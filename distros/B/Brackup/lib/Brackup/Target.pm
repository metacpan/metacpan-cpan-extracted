package Brackup::Target;

use strict;
use warnings;
use Brackup::InventoryDatabase;
use Brackup::TargetBackupStatInfo;
use Brackup::Util 'tempfile';
use Brackup::DecryptedFile;
use Carp qw(croak);

sub new {
    my ($class, $confsec) = @_;
    my $self = bless {}, $class;
    $self->{name} = $confsec->name;
    $self->{name} =~ s/^TARGET://
        or die "No target found matching " . $confsec->name;
    die "Target name must be only a-z, A-Z, 0-9, and _." 
        unless $self->{name} =~ /^\w+/;

    $self->{keep_backups} = $confsec->value("keep_backups");
    $self->{inv_db} =
        Brackup::InventoryDatabase->new($confsec->value("inventorydb_file") ||
                                        $confsec->value("inventory_db") ||
                                        "$ENV{HOME}/.brackup-target-$self->{name}.invdb",
                                        $confsec);

    return $self;
}

sub name {
    my $self = shift;
    return $self->{name};
}

# return hashref of key/value pairs you want returned to you during a restore
# you should include anything you need to restore.
# keys must match /^\w+$/
sub backup_header {
    return {}
}

# returns bool
sub has_chunk {
    my ($self, $chunk) = @_;
    die "ERROR: has_chunk not implemented in sub-class $self";
}

# returns true on success, or returns false or dies otherwise.
sub store_chunk {
    my ($self, $chunk) = @_;
    die "ERROR: store_chunk not implemented in sub-class $self";
}

# returns true on success, or returns false or dies otherwise.
sub delete_chunk {
    my ($self, $chunk) = @_;
    die "ERROR: delete_chunk not implemented in sub-class $self";
}

# returns a list of names of all chunks
sub chunks {
    my ($self) = @_;
    die "ERROR: chunks not implemented in sub-class $self";
}

sub inventory_db {
    my $self = shift;
    return $self->{inv_db};
}

sub add_to_inventory {
    my ($self, $pchunk, $schunk) = @_;
    my $key  = $pchunk->inventory_key;
    my $db = $self->inventory_db;
    $db->set($key => $schunk->inventory_value);
}

# return stored chunk, given positioned chunk, or undef.  no
# need to override this, unless you have a good reason.
sub stored_chunk_from_inventory {
    my ($self, $pchunk) = @_;
    my $key    = $pchunk->inventory_key;
    my $db     = $self->inventory_db;
    my $invval = $db->get($key)
        or return undef;
    return Brackup::StoredChunk->new_from_inventory_value($pchunk, $invval);
}

# return a list of TargetBackupStatInfo objects representing the
# stored backup metafiles on this target.
sub backups {
    my ($self) = @_;
    die "ERROR: backups method not implemented in sub-class $self";
}

# downloads the given backup name to the current directory (with
# *.brackup extension)
sub get_backup {
    my ($self, $name) = @_;
    die "ERROR: get_backup method not implemented in sub-class $self";
}

# deletes the given backup from this target
sub delete_backup {
    my ($self, $name) = @_;
    die "ERROR: delete_backup method not implemented in sub-class $self";
}

# removes old metafiles from this target
sub prune {
    my ($self, %opt) = @_;

    my $keep_backups = $opt{keep_backups} || $self->{keep_backups}
        or die "ERROR: keep_backups option not set\n";
    die "ERROR: keep_backups option must be at least 1\n"
        unless $keep_backups > 0;

    # select backups to delete
    my (%backups, @backups_to_delete) = ();
    foreach my $backup_name (map {$_->filename} $self->backups) {
        $backup_name =~ /^(.+)-\d+$/;
        $backups{$1} ||= [];
        push @{ $backups{$1} }, $backup_name;
    }
    foreach my $source (keys %backups) {
        next if $opt{source} && $source ne $opt{source};
        my @b = reverse sort @{ $backups{$source} };
        push @backups_to_delete, splice(@b, ($keep_backups > $#b+1) ? $#b+1 : $keep_backups);
    }

    warn ($opt{dryrun} ? "Pruning:\n" : "Pruned:\n") if $opt{verbose};
    foreach my $backup_name (@backups_to_delete) {
        warn "  $backup_name\n" if $opt{verbose};
        $self->delete_backup($backup_name) unless $opt{dryrun};
    }
    return scalar @backups_to_delete;
}

# removes orphaned chunks in the target
sub gc {
    my ($self, %opt) = @_;

    # get all chunks and then loop through metafiles to detect
    # referenced ones
    my %chunks = map {$_ => 1} $self->chunks;
    my $total_chunks = scalar keys %chunks;
    my $tempfile = +(tempfile())[1];
    my @backups = $self->backups;
    BACKUP: foreach my $i (0 .. $#backups) {
        my $backup = $backups[$i];
        warn sprintf "Collating chunks from backup %s [%d/%d]\n",
            $backup->filename, $i+1, scalar(@backups) 
                if $opt{verbose};
        $self->get_backup($backup->filename, $tempfile);
        my $decrypted_backup = new Brackup::DecryptedFile(filename => $tempfile);
        my $parser = Brackup::Metafile->open($decrypted_backup->name);
        $parser->readline;  # skip header
        ITEM: while (my $it = $parser->readline) {
            next ITEM unless $it->{Chunks};
            my @item_chunks = map { (split /;/)[3] } grep { $_ } split(/\s+/, $it->{Chunks} || "");
            delete $chunks{$_} for (@item_chunks);
        }
    }
    my @orphaned_chunks = keys %chunks;

    # report orphaned chunks
    if (@orphaned_chunks && $opt{verbose} && $opt{verbose} >= 2) {
      warn "Orphaned chunks:\n";
      warn "  $_\n" for (@orphaned_chunks);
    }

    # remove orphaned chunks
    if (@orphaned_chunks && ! $opt{dryrun}) {
        my $confirm = 'y';
        if ($opt{interactive}) {
            printf "Run gc, removing %d/%d orphaned chunks? [y/N] ", 
              scalar @orphaned_chunks, $total_chunks;
            $confirm = <>;
        }

        if (lc substr($confirm,0,1) eq 'y') {
            warn "Removing orphaned chunks\n" if $opt{verbose};
            $self->delete_chunk($_) for (@orphaned_chunks);

            # delete orphaned chunks from inventory
            my $inventory_db = $self->inventory_db;
            while (my ($k, $v) = $inventory_db->each) {
                $v =~ s/ .*$//;         # strip value back to hash
                $inventory_db->delete($k) if exists $chunks{$v};
            }
        }
    }

    return wantarray ? ( scalar @orphaned_chunks, $total_chunks ) :  scalar @orphaned_chunks;
}



1;

__END__

=head1 NAME

Brackup::Target - describes the destination for a backup

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:amazon]
  type = Amazon
  aws_access_key_id  = ...
  aws_secret_access_key =  ....

=head1 GENERAL CONFIG OPTIONS

=over

=item B<type>

The driver for this target type.  The type B<Foo> corresponds to the Perl module 
Brackup::Target::B<Foo>.

The set of targets (and the valid options for type) currently distributed with the
Brackup core are:

B<Filesystem> -- see L<Brackup::Target::Filesystem> for configuration details

B<Ftp> -- see L<Brackup::Target::Ftp> for configuration details

B<Sftp> -- see L<Brackup::Target::Sftp> for configuration details

B<Amazon> -- see L<Brackup::Target::Amazon> for configuration details

B<Amazon> -- see L<Brackup::Target::CloudFiles> for configuration details

=item B<keep_backups>

The default number of recent backups to keep when running I<brackup-target prune>.

=item B<inventorydb_file>

The location of the L<Brackup::InventoryDatabase> inventory database file for 
this target e.g.

  [TARGET:amazon]
  type = Amazon
  aws_access_key_id  = ...
  aws_secret_access_key =  ...
  inventorydb_file = /home/bradfitz/.amazon-already-has-these-chunks.db

Only required if you wish to change this from the default, which is 
".brackup-target-TARGETNAME.invdb" in your home directory.

=item B<inventorydb_type>

Dictionary type to use for the inventory database. The dictionary type B<Bar>
corresponds to the perl module Brackup::Dict::B<Bar>.

The default inventorydb_type is B<SQLite>. See L<Brackup::InventoryDatabase> for 
more.

=item B<inherit>

The name of another Brackup::Target section to inherit from i.e. to use 
for any parameters that are not already defined in the current section e.g.:

  [TARGET:ftp_defaults]
  type = Ftp
  ftp_host = myserver
  ftp_user = myusername
  ftp_password = mypassword

  [TARGET:ftp_home]
  inherit = ftp_defaults
  path = home

  [TARGET:ftp_images]
  inherit = ftp_defaults
  path = images

=back

=head1 SEE ALSO

L<Brackup>

L<Brackup::InventoryDatabase>

=cut

# vim:sw=4:et


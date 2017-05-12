# support module for helping test brackup
package Brackup::Test;
require Exporter;
use strict;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(do_backup do_restore ok_dirs_match ok_files_match);

use Test::More;
use FindBin qw($Bin);
use Brackup::Util qw(tempdir tempfile);
use File::Find;
use File::stat ();
use Cwd;
use Brackup::DecryptedFile;
use Digest::SHA1 qw/sha1_hex/;

use Brackup;

my $has_diff = eval "use Text::Diff; 1;";

my @to_unlink;
my $par_pid = $$;
END {
    if ($$ == $par_pid) {
        my $rv = unlink @to_unlink unless $ENV{BRACKUP_TEST_NOCLEANUP};
    }
}

# Set the gpg directory, so we don't rely on users having a ~/.gnupg
$ENV{GNUPGHOME} = tempdir( CLEANUP => 1 );

sub do_backup {
    my %opts = @_;
    my $with_confsec    = delete $opts{'with_confsec'} || sub {};
    my $with_targetsec  = delete $opts{'with_targetsec'} || sub {};
    my $with_root       = delete $opts{'with_root'}    || sub {};
    my $target          = delete $opts{'with_target'};
    die if %opts;

    my $initer = shift;

    my $conf = Brackup::Config->new;
    my $confsec;

    $confsec = Brackup::ConfigSection->new("SOURCE:test_root");
    $with_confsec->($confsec);
    $conf->add_section($confsec);

    my $root = $conf->load_root("test_root");
    ok($root, "have a source root");
    $with_root->($root);

    unless ($target) {
        my $backup_dir = tempdir( CLEANUP => $ENV{BRACKUP_TEST_NOCLEANUP} ? 0 : 1 );
        ok_dir_empty($backup_dir);

        my ($inv_fh, $inv_filename) = tempfile();
        close($inv_fh);
        push @to_unlink, $inv_filename;


        $confsec = Brackup::ConfigSection->new("TARGET:test_restore");
        $with_targetsec->($confsec);
        $confsec->add("type" => "Filesystem") unless exists $confsec->{type};
        $confsec->add("inventorydb_file" => $inv_filename);
        $confsec->add("path" => $backup_dir);
        $conf->add_section($confsec);
        $target = $conf->load_target("test_restore", testmode => 1);
    }

    ok($target, "have a target ($target)");

    my $backup = Brackup::Backup->new(
                                      root      => $root,
                                      target    => $target,
                                      savefiles => 1,
                                      );
    ok($backup, "have a backup object");

    my ($meta_fh, $meta_filename) = tempfile();
    ok(-e $meta_filename, "metafile exists");
    push @to_unlink, $meta_filename;

    ok(eval { $backup->backup($meta_filename) }, "backup succeeded");
    if ($@) {
        warn "Died running backup: $@\n";
    }
    ok(-s $meta_filename, "backup file has size");

    check_inventory_db($target, [$root->gpg_args]);

    return wantarray ? ($meta_filename, $backup, $target) : $meta_filename;
}

sub check_inventory_db {
    my ($target, $gpg_args) = @_;

    my $inv_db_file;
    eval {
        my $inv_db = $target->inventory_db                      or die 'cannot open inventory db';
        $inv_db_file = $inv_db->backing_file ? (' ' . $inv_db->backing_file) : '';

        while (my ($key, $value) = $inv_db->each) {
            my ($raw_dig, $gpg_rcpt) = split /;/, $key;
            my ($enc_dig, $enc_size, $range) = split /\s+/, $value;

            # check the stored data
            my $dataref = $target->load_chunk($enc_dig)         or die "cannot load chunk $enc_dig";
            length $$dataref == $enc_size                       or die "chunk $enc_dig has wrong size, not $enc_size";
            $enc_dig eq "sha1:".sha1_hex($$dataref)             or die "chunk $enc_dig has wrong digest";
 
            # if we are in a composite chunk, keep only the part we want
            if($range) {
                my ($from, $to) = split '-', $range;
                my $part = substr $$dataref, $from, $to-$from;
                $dataref = \$part;
            }

            # decrypt if encrypted
            my $dec_ref;
            if($gpg_rcpt =~ /^to=(.*)$/) {
                my $meta = { 'GPG-Recipient' => $1 };
                local @Brackup::GPG_ARGS = @$gpg_args;

                $dec_ref = Brackup::Decrypt::decrypt_data($dataref, meta => $meta);
            } else {
                $dec_ref = $dataref;
            }

            # check the raw data
            $raw_dig eq "sha1:".sha1_hex($$dec_ref)       or die "chunk $enc_dig has wrong raw digest";
        }
    };
    ok(!$@, "inventory db$inv_db_file is good")   or diag($@);
}

sub do_restore {
    my ($backup_file, %opts) = @_;
    my $prefix     = delete $opts{'prefix'} || "";   # default is restore everything
    my $restore_should_die = delete $opts{'restore_should_die'};
    die if %opts;
    my $restore_dir = tempdir( CLEANUP => $ENV{BRACKUP_TEST_NOCLEANUP} ? 0 : 1 );
    ok_dir_empty($restore_dir);

    my $restore = Brackup::Restore->new(
                                        to     => $restore_dir,
                                        prefix => $prefix,
                                        file   => $backup_file,
                                        );
    ok($restore, "have restore object");
    my $rv = eval { $restore->restore; };
    if ($restore_should_die) {
        ok(! defined $rv, "restore died: $@") 
            or die "restore unexpectedly succeeded";
        return;
    }
    else {
        ok($rv, "did the restore") 
            or die "restore failed: $@";
        return $restore_dir;
    }
}

sub ok_dirs_match {
    my ($after, $before) = @_;

    my $pre_ls  = dir_structure($before);
    my $post_ls = dir_structure($after);

    if ($has_diff) {
        use Data::Dumper;
        my $pre_dump = Dumper($pre_ls);
        my $post_dump = Dumper($post_ls);
        my $diff = Text::Diff::diff(\$pre_dump, \$post_dump);
        is($diff, "", "dirs match");
    } else {
        is_deeply($post_ls, $pre_ls, "dirs match");
    }
}

sub ok_files_match {
    my ($after, $before) = @_;

    my $pre_ls  = file_meta($before);
    my $post_ls = file_meta($after);

    if ($has_diff) {
        use Data::Dumper;
        my $pre_dump = Dumper($pre_ls);
        my $post_dump = Dumper($post_ls);
        my $diff = Text::Diff::diff(\$pre_dump, \$post_dump);
        is($diff, "", "files match");
    } else {
        is_deeply($post_ls, $pre_ls, "files match");
    }
}

sub ok_dir_empty {
    my $dir = shift;
    unless (-d $dir) { ok(0, "not a dir"); return; }
    opendir(my $dh, $dir) or die "failed to opendir: $!";
    is_deeply([ sort readdir($dh) ], ['.', '..'], "dir is empty: $dir");
}

sub file_meta {
    my $path = shift;
    my $st = File::stat::lstat($path);

    my $meta = {};
    $meta->{size} = $st->size unless -d $path;
    $meta->{is_file} = 1 if -f $path;
    $meta->{is_link} = 1 if -l $path;
    if ($meta->{is_link}) {
        $meta->{link} = readlink $path;
    } else {
        # we ignore these for links, since Linux doesn't let us restore anyway,
        # as Linux as no lutimes(2) syscall, as of Linux 2.6.16 at least
        $meta->{atime} = $st->atime if 0; # TODO: make tests work with atimes
        $meta->{mtime} = $st->mtime;
        $meta->{mode}  = sprintf('%#o', $st->mode & 0777);
    }

    # the gpg tests open/close the rings in the root, so
    # mtimes get bumped around or something.  the proper fix
    # is too ugly for what it's worth, so let's just ignore
    # the mtime of top-level
    delete $meta->{mtime} if $path eq ".";

    return $meta;
}

# given a directory, returns a hashref of its contentn
sub dir_structure {
    my $dir = shift;
    my %files;  # "filename" -> {metadata => ...}
    my $cwd = getcwd;
    chdir($dir) or die "Failed to chdir to $dir";

    find({
        no_chdir => 1,
        preprocess => sub { return sort @_ },
        wanted => sub {
            my $path = $_;
            $files{$path} = file_meta($path);
        },
    }, ".");

    chdir($cwd) or die "Failed to chdir back to $cwd";
    return \%files;
}

# add a random number of orphan chunks to $target
sub add_orphan_chunks {
    my ($root, $target, $orphan_chunks_count) = @_;

    for (1..$orphan_chunks_count) {
        # HACK: to avoid worse hacks, we need a pchunk to store an orphan chunk.
        # We use small segments of 'pubring-test.gpg' so that they are different 
        # than all other chunks
        my $pchunk = Brackup::PositionedChunk->new(
            file => Brackup::File->new(root => $root,
                                       path => 'pubring-test.gpg'),
            offset => $_ * 10,
            length => 10,
        );

        # no encryption, copy raw data and store schunk
        my $schunk = Brackup::StoredChunk->new($pchunk);
#       $schunk->copy_raw_data;
        $target->store_chunk($schunk);
    }
}


1;

# vim:et:sw=4

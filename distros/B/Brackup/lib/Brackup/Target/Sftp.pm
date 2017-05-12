package Brackup::Target::Sftp;
use strict;
use warnings;
use base 'Brackup::Target::Filebased';
use File::Basename;
use Net::SFTP::Foreign 1.57;                    # versions <= 1.56 emit warnings
use Net::SFTP::Foreign::Constants qw(:flags);

sub new {
    my ($class, $confsec) = @_;
    my $self = $class->SUPER::new($confsec);

    $self->{path} = $confsec->value("path") or die 'No path specified';
    $self->{nocolons} = $confsec->value("no_filename_colons");
    $self->{nocolons} = $self->_default_nocolons unless defined $self->{nocolons};

    $self->{sftp_host} = $confsec->value("sftp_host") or die 'No "sftp_host"';
    $self->{sftp_port} = $confsec->value("sftp_port");
    $self->{sftp_user} = $confsec->value("sftp_user") || (getpwuid($<))[0] 
        or die "No sftp_user specified";

    $self->_common_new;

    return $self;
}

sub new_from_backup_header {
    my ($class, $header) = @_;
    my $self = bless {}, $class;

    $self->{sftp_host} = $header->{'SftpHost'};
    $self->{sftp_user} = $header->{'SftpUser'};
    $self->{sftp_port} = $header->{'SftpPort'} if $header->{'SftpPort'};
    $self->{path} = $header->{'BackupPath'} or
        die "No BackupPath specified in the backup metafile.\n";
    $self->{nocolons} = $header->{"NoColons"};
    $self->{nocolons} = $self->_default_nocolons unless defined $self->{nocolons};

    $self->_common_new;

    return $self;
}

sub _common_new {
    my ($self) = @_;
    $self->{retry_wait} = int($ENV{SFTP_RETRY_WAIT} || 10);
    $self->_connect();
}

sub backup_header {
    my ($self) = @_;
    return {
        "BackupPath" => $self->{path},
        "SftpHost" => $self->{sftp_host},
        "SftpUser" => $self->{sftp_user},
        "NoColons" => $self->nocolons,
        $self->{sftp_port} ? ("SftpPort" => $self->{sftp_port}) : (),
    };
}

sub _default_nocolons { 
    return 1;        # Can't assume remote OS allows colons
}

sub nocolons {
    my ($self) = @_;
    return defined $self->{nocolons} ? $self->{nocolons} : $self->_default_nocolons;
}

sub _connect {
    my ($self) = @_;

    $self->{sftp} = Net::SFTP::Foreign->new(
        $self->{sftp_host}, 
        user => $self->{sftp_user},
        $self->{sftp_port} ? (port => $self->{sftp_port}) : (),
    );
    $self->{sftp}->error and die $self->{sftp}->error;
}

sub _autoretry {
    my ($self, $code) = @_;
    my $result = $code->();

    if (!defined($result) && !$self->{sftp}->{_connected}) {
        warn "Error in SFTP connection: " . $self->{sftp}->error . "\n";
        sleep $self->{retry_wait};
        warn "Trying to reconnect ...\n";
        $self->_connect();
        $result = $code->();
    }

    return $result;
}

sub _ls {
    my ($self, $path) = @_;
    my $result = $self->_autoretry(sub {
        if (my $ls = $self->{sftp}->ls($path, 
                names_only => 1, no_wanted => qr/^\.\.?$/ )) {
            die "Bad ls results $ls" unless ref $ls && ref $ls eq 'ARRAY';
            return [ map { $path . '/' . $_ } @$ls ];
        }
    });
    unless (defined($result)) {
        die "Listing failed for $path: " . $self->{sftp}->error;
    }
    return wantarray ? @$result : $result;
}

sub size {
    my ($self, $path) = @_;
    my $size = $self->_autoretry(sub {
        my $attr = $self->{sftp}->stat($path)
            or die "Cannot stat path '$path'";
        return $attr->size;
    });
    unless (defined($size)) {
        die "Getting size for $path failed: " . $self->{sftp}->error;
    }
    return $size;
}

sub _mtime {
    my ($self, $path) = @_;
    my $mtime = $self->_autoretry(sub {
        my $attr = $self->{sftp}->stat($path)
            or die "Cannot stat path '$path'";
        return $attr->mtime;
    });
    unless (defined $mtime) {
        die "Getting mtime of $_ failed: " . $self->{sftp}->error;
    }
    return $mtime;
}

sub _mkdir {
    my ($self, $dir) = @_;
    return if ! $dir || $dir eq '/';

    my $parent = dirname($dir);
    $self->_autoretry(sub {
        $self->{sftp}->stat($parent) or $self->_mkdir($parent);
        $self->{sftp}->stat($dir) or $self->{sftp}->mkdir($dir);
    }) or die "Creating directory $dir failed: " . $self->{sftp}->error;
}

sub _put_chunk {
    my ($self, $path, $content) = @_;

    $self->_mkdir(dirname($path));

    $self->_autoretry(sub {
        my $fh = $self->{sftp}->open($path, SSH2_FXF_WRITE|SSH2_FXF_CREAT) 
            or die "Failed to open";
        my $result = $self->{sftp}->write($fh, $content);
        $self->{sftp}->close($fh) or die "Failed to close";
        return $result;
    }) or die "Writing file $path failed: " . $self->{sftp}->error;
}

sub _put_fh {
    my ($self, $path, $fh) = @_;

    $self->_mkdir(dirname($path));

    $self->_autoretry(sub { $self->{sftp}->put($fh, $path) })
        or die "Doing a put to path $path failed: " . $self->{sftp}->error;
}

sub _get {
    my ($self, $path) = @_;
    my $content;

    $self->_autoretry(sub {
        $content = $self->{sftp}->get_content($path);
    }) or die "Reading file $path failed: " . $self->{sftp}->error;

    return \$content;
}

sub _delete {
    my ($self, $path) = @_;
    $self->_autoretry(sub {
        return $self->{sftp}->remove($path);
    }) or die "Removing file $path failed: " . $self->{sftp}->error;
}

sub chunkpath {
    my ($self, $dig) = @_;
    return $self->{path} . '/' . $self->SUPER::chunkpath($dig);
}

sub metapath {
    my ($self, $name) = @_;
    return $self->{path} . '/' . $self->SUPER::metapath($name);
}

sub load_chunk {
    my ($self, $dig) = @_;
    return $self->_get($self->chunkpath($dig));
}

sub store_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;
    my $path = $self->chunkpath($dig);

    $self->_put_fh($path, $chunk->chunkref); 

    my $actual_size = $self->size($path);
    my $expected_size = $chunk->backup_length;
    unless ($actual_size == $expected_size) {
        die "Chunk $path incompletely written to disk: size is " .
            "$actual_size, expecting $expected_size\n";
    }

    return 1;
}

sub delete_chunk {
    my ($self, $dig) = @_;
    $self->_delete($self->chunkpath($dig));
}

# returns a list of names of all chunks
sub chunks {
    my $self = shift;

    my @chunks = ();
    for ($self->{sftp}->find( $self->{path}, 
            wanted => qr/\.chunk$/, no_descend => qr/^backups$/ )) {
        my $chunk_name = basename($_->{filename});
        $chunk_name =~ s/\.chunk$//;
        $chunk_name =~ s/\./:/g if $self->nocolons;
        push @chunks, $chunk_name;
    }
    return @chunks;
}

sub store_backup_meta {
    my ($self, $name, $fh) = @_;
    $self->_put_fh($self->metapath("$name.brackup"), $fh);
    return 1;
}

sub backups {
    my ($self) = @_;
    my $list = $self->_ls($self->metapath());

    my @ret = ();
    foreach (@$list) {
        my $fn = basename($_);
        next unless $fn =~ m/\.brackup$/;

        (my $bn = $fn) =~ s/\.brackup$//;

        my $path = $self->metapath($fn);
        my $size = $self->size($path);
        my $mtime = $self->_mtime($path);

        push @ret, Brackup::TargetBackupStatInfo->new($self, $bn,
                                                      time => $mtime,
                                                      size => $size);
    }

    return @ret;
}

# downloads the given backup name to the current directory (with
# *.brackup extension) or to the specified location
sub get_backup {
    my ($self, $name, $output_file) = @_;
    my $path = $self->metapath("$name.brackup");

	$output_file ||= "$name.brackup";

    $self->_autoretry(sub {
        return $self->{sftp}->get($path, $output_file);
    }) or die "Reading file $path failed: " . $self->{ftp}->error;

    return 1;
}

sub delete_backup {
    my ($self, $name) = @_;
    $self->_delete($self->metapath("$name.brackup"));
    return 1;
}

1;


=head1 NAME

Brackup::Target::Sftp - backup to an SSH/SFTP server 

=head1 DESCRIPTION

Backup to an SSH/SFTP server, using the L<Net::SFTP::Foreign> perl module.

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:server_sftp]
  type = Sftp
  path = /path/on/server
  sftp_host = server.example.com
  sftp_user = user

At this time there is no 'sftp_password' setting - you are encouraged 
to use ssh keys for authentication instead of passwords. Alternatively,
you can enter your password interactively when prompted.

=head1 CONFIG OPTIONS

=over

=item B<type>

I<(Mandatory.)> Must be "B<Sftp>".

=item B<path>

I<(Mandatory).> Server-side path to write backups to (may be ".").

=item B<sftp_host>

I<(Mandatory).> SSH/SFTP server hostname.

=item B<sftp_port>

Port on which to connect to remote SSH/SFTP server.

=item B<sftp_user>

Username to use to connect.

=item B<no_filename_colons>

Flag - set to false (0/false/no) to indicate that the remote filesystem supports
colons (':') in filenames. Default: 1.

=back

=head1 SEE ALSO

L<Brackup::Target>

L<Brackup::Target::Ftp>

L<Net::SFTP::Foreign>

=head1 AUTHOR

Gavin Carr E<lt>gavin@openfusion.com.auE<gt>.

Copyright (c) 2008 Gavin Carr.

This module is free software. You may use, modify, and/or redistribute 
this software under the same terms as perl itself.

=cut

# vim:sw=4:et


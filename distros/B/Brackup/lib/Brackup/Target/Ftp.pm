package Brackup::Target::Ftp;
use strict;
use warnings;
use base 'Brackup::Target::Filebased';
use File::Basename;
use Net::FTP;

sub new {
    my ($class, $confsec) = @_;
    my $self = $class->SUPER::new($confsec);

    $self->{ftp_host} = $confsec->value("ftp_host") or die 'No "ftp_host"';
    $self->{ftp_user} = $confsec->value("ftp_user") or die 'No "ftp_user"';
    $self->{ftp_password} = $confsec->value("ftp_password") or
        die 'No "ftp_password"';
    $self->{path} = $confsec->value("path") or
        die 'No path specified';

    $self->_common_new;

    return $self;
}

sub new_from_backup_header {
    my ($class, $header, $confsec) = @_;
    my $self = bless {}, $class;

    $self->{ftp_host} = $ENV{FTP_HOST} || $header->{'FtpHost'};
    $self->{ftp_user} = $ENV{FTP_USER} || $header->{'FtpUser'};
    $self->{ftp_password} = $ENV{FTP_PASSWORD} || 
                            $confsec->value('ftp_password') or
        die "FTP_PASSWORD missing in environment";
    $self->{path} = $header->{'BackupPath'} or
        die "No BackupPath specified in the backup metafile.\n";

    $self->_common_new;

    return $self;
}

sub _common_new {
    my ($self) = @_;
    $self->{retry_wait} = int($ENV{FTP_RETRY_WAIT} || 10);
    $self->_connect();
}

sub backup_header {
    my ($self) = @_;
    return {
        "BackupPath" => $self->{path},
        "FtpHost" => $self->{ftp_host},
        "FtpUser" => $self->{ftp_user},
    };
}

sub nocolons {
    # We never know what operating system is at the other end, thus never use
    # colons.
    return 1;
}

sub _connect {
    my ($self) = @_;

    $self->{ftp} = Net::FTP->new($self->{ftp_host}) or die $@;
    $self->{ftp}->login($self->{ftp_user}, $self->{ftp_password});
    $self->{ftp}->binary();
}

sub _autoretry {
    my ($self, $code) = @_;
    my $result = $code->();

    if (!defined($result) && !$self->{ftp}->connected) {
        warn "Error in FTP: " . $self->{ftp}->message . "\n";
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
        return $self->{ftp}->ls($path);
    });
    unless (defined($result)) {
        die "Listing failed for $path: " . $self->{ftp}->message;
    }
    return wantarray ? @$result : $result;
}

sub size {
    my ($self, $path) = @_;
    my $size = $self->_autoretry(sub {
        return $self->{ftp}->size($path);
    });
    unless (defined($size)) {
        die "Getting size for $path failed: " . $self->{ftp}->message;
    }
    return $size;
}

sub _mdtm {
    my ($self, $path) = @_;
    my $mtime = $self->_autoretry(sub {
        return $self->{ftp}->mdtm($path);
    });
    unless (defined $mtime) {
        die "Getting mtime of $_ failed: " . $self->{ftp}->message;
    }
    return $mtime;
}

sub _put_fh {
    my ($self, $path, $fh) = @_;

    # Ugly-hack: monkey-patch IO::InnerFile to provide BINMODE for Net::FTP::put
    *{IO::InnerFile::BINMODE} = sub { $_[0]->binmode }
      if $fh->isa('IO::InnerFile');

    # Make sure directory exists.
    my $dir = dirname($path);
    $self->_autoretry(sub {
        return $self->{ftp}->mkdir($dir, 1)
    }) or die "Creating directory $dir failed: " . $self->{ftp}->message;

    $self->_autoretry(sub {
        $self->{ftp}->put($fh, $path);
    }) or die "Writing file $path failed: " . $self->{ftp}->message;
}

sub _put_chunk {
    my ($self, $path, $content) = @_;
    open(my $fh, '<', \$content) or die $!;
    $self->_put_fh($path, $fh);
}

sub _get {
    my ($self, $path) = @_;
    my $content;

    $self->_autoretry(sub {
        open(my $fh, '>', \$content) or die $!;
        binmode($fh);
        my $result = $self->{ftp}->get($path, $fh);
        close($fh) or die "Failed to close";
        return $result;
    }) or die "Reading file $path failed: " . $self->{ftp}->message;

    return \$content;
}

sub _delete {
    my ($self, $path) = @_;
    $self->_autoretry(sub {
        return $self->{ftp}->delete($path);
    }) or die "Removing file $path failed: " . $self->{ftp}->message;
}

sub _recurse {
    my ($self, $path, $maxdepth, $match) = @_;
    return if $maxdepth < 0;
    foreach ($self->_ls($path)) {
        if ($match->($_)) {
            $self->_recurse($_, $maxdepth - 1, $match);
        }
    }
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
    my ($self) = @_;
    my @chunks;

    $self->_recurse($self->{path}, 2, sub {
        my ($path) = @_;
        my $filename = basename($path);

        if ($path =~ m/\.chunk$/) {
            $filename =~ s/\.chunk$//;
            $filename =~ s/\./:/g if $self->nocolons;
            push @chunks, $filename;
            return 0;
        }

        return $filename ne 'backups';
    });

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
        my $mtime = $self->_mdtm($path);

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
        open(my $out, '>', $output_file)
            or die "Failed to open $output_file: $!\n";
        my $result = $self->{ftp}->get($path, $out);
        close($out) or die $!;
        return $result;
    }) or die "Reading file $path failed: " . $self->{ftp}->message;

    return 1;
}

sub delete_backup {
    my ($self, $name) = @_;
    $self->_delete($self->metapath("$name.brackup"));
    return 1;
}

1;


=head1 NAME

Brackup::Target::Ftp - backup to an FTP server

=head1 DESCRIPTION

Back up to an FTP server.

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:nfs_in_garage]
  type = Ftp
  path = .
  ftp_host = ftp.domain.tld
  ftp_user = user
  ftp_password = password

=head1 CONFIG OPTIONS

=over

=item B<type>

Must be "B<Ftp>".

=item B<path>

Server-side path, can be ".".

=item B<ftp_host>

FTP server host, optionally with port (host:port).

=item B<ftp_user>

Username to use.

=item B<ftp_password>

Password to use.

=back

=head1 SEE ALSO

L<Brackup::Target>

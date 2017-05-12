
package Brackup::Mount;

# Note: This package and the brackup-mount utility that calls it
# both depend on Fuse. Fuse isn't a dependency of the Brackup
# distribution as a whole, so don't load this from anywhere else
# in Brackup.
use Fuse;

use Brackup;
use Brackup::Restore;
use POSIX qw(ENOENT EISDIR EROFS ENOTDIR EBUSY EINVAL O_WRONLY O_RDWR);
use Fcntl qw(S_IFREG S_IFDIR S_IFLNK);
use File::Temp;
use IO::File;

use strict;

sub mount {
    my ($class, $metafile, $mountpoint) = @_;

    my $p = Brackup::Metafile->open($metafile) or die "Failed to open metafile $metafile";

    my $header = $p->readline();
    my $driver_header = Brackup::Restore::_driver_meta($header);

    my $driver_class = $header->{BackupDriver};
    die "No driver specified" unless $driver_class;

    eval "use $driver_class; 1;" or die "Failed to load driver ($driver_class) to restore from: $@\n";

    my $target = "$driver_class"->new_from_backup_header($driver_header);

    my $meta = $class->_build_metadata($header, $p);

    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    my $file_temp_path = sub {
        my ($record) = @_;

        return $tempdir."/".$record->{digest};
    };

    return Fuse::main(
        mountpoint => $mountpoint,
        mountopts => "",
        threaded => 0,
        debug => 0,

        getattr => sub {
            my ($path) = @_;
            my $record = $meta->{$path};
            return -ENOENT unless $record;

            return (
                0,     # device number (?)
                0,     # inode
                $record->{mode},
                0,     # nlink
                $<,    # uid
                0,     # gid
                0,     # rdev
                $record->{size},
                $record->{atime},
                $record->{mtime},
                $record->{mtime}, # ctime
                1024,  # blocksize
                1,     # blocks
            );
        },

        getdir => sub {
            my ($path) = @_;

            my $record = $meta->{$path};
            return -ENOENT unless $record;
            return -ENOTDIR unless $record->{type} eq 'd';

            return ('..', @{$record->{child_nodes}}, 0);
        },

        readlink => sub {
            my ($path) = @_;

            my $record = $meta->{$path};
            return -ENOENT unless $record;

            return $record->{link} || 0;
        },

        open => sub {
            my ($path, $mode) = @_;

            my $record = $meta->{$path};
            return -ENOENT unless $record;
            return -EISDIR if $record->{type} eq 'd';
            return -EROFS if ($mode & O_WRONLY) || ($mode & O_RDWR);

            # Fetch the data relating to this file to a local
            # file and open it.

            unless ($record->{fh}) {
                my $fn = $file_temp_path->($record);

                # HACK: Do a bit of grovelling in Brackup::Restore's innards.
                # We want to restore the file, and the process is quite involved,
                # so we call Brackup::Restore::_restore_file in a kinda wacky
                # way to trick it into putting the file where we want it.
                my $fake_object = bless {
                    _target => $target,
                    _meta => $header,
                }, 'Brackup::Restore';
                Brackup::Restore::_restore_file($fake_object, $fn, $record->{meta});

                my $fh = IO::File->new($fn, '<');
                $record->{fh} = $fh;
            }
            $record->{opencount}++;

            return 0;
        },

        read => sub {
            my ($path, $size, $offset) = @_;

            my $record = $meta->{$path};
            return -ENOENT unless $record;
            return -EISDIR if $record->{type} eq 'd';

            return -EBUSY unless $record->{opencount} > 0;

            my $fh = $record->{fh};

            my $buf = "";
            $fh->seek($offset, 0);
            my $amount_read = $fh->read($buf, $size);
            my $err = -$!;

            if (defined $amount_read) {
                return $buf;
            }
            else {
                return $err+0;
            }
        },

        release => sub {
            my ($path, $mode) = @_;

            # A previously-opened file has been closed.

            my $record = $meta->{$path};
            return -ENOENT unless $record;

            my $fh = $record->{fh};
            return -EINVAL unless $fh;

            $record->{opencount}--;

            if ($record->{opencount} == 0) {
                close($fh);
                unlink($file_temp_path->($record));
                $record->{fh} = undef;
            }
        },

        statfs => sub {
            return (1024, scalar(keys %$meta)+0, 0, 0, 0, 1024);
        },
    );
}

sub _build_metadata {
    my ($class, $header, $p) = @_;

    my %meta = ();

    while (my $it = $p->readline) {
        my $path = $it->{Path};
        my $type = $it->{Type} || 'f';
        my $mode = oct($it->{Mode} || ($type eq 'd' ? $header->{DefaultDirMode} : $header->{DefaultFileMode}));

        # Add the type to the mode
        $mode |= ({
            d => S_IFDIR,
            f => S_IFREG,
            l => S_IFLNK,
        }->{$type} || 0);

        my $record = {
            path => $path,
            type => $type,
            mode => $mode,
            size => $it->{Size},
            mtime => $it->{Mtime},
            atime => $it->{Atime},
            link => $it->{Link},
            child_nodes => [],
            fh => undef,
            digest => $it->{Digest},
            opencount => 0,
            meta => $it,
        };

        my $parent_path = undef;
        my $local_name = undef;

        if ($path =~ m!^(.+)/([^/]+)$!) {
            $parent_path = '/'.$1;
            $local_name = $2;
        }
        else {
            $parent_path = '/';
            $local_name = $path;
        }

        my $path_key = $path eq '.' ? '/' : '/'.$path;

        $meta{$path_key} = $record;
        push @{$meta{$parent_path}{child_nodes}}, $local_name;
    }

    return \%meta;
}

=head1 NAME

Brackup::Mount - Mount a backup as a usable filesystem using FUSE

=cut

1;

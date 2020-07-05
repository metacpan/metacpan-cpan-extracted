use strict;
use warnings;
use strictures;
use diagnostics;
package App::turbocopy;

# VERSION

=head1 NAME

App::turbocopy - CLI utility to copying files in more effective way

=head1 SYNOPSIS

  # copy file a to  new file b
  turbocopy a b

  # copy files recursively from dir a to dir b
  turbocopy -r a/ b/

=head1 DESCRIPTION

This script provides a command to copy files in more effective way using asynchronous IO.

=head1 Options

=over 4

=item -r

copy files recursively

=back

=head1 HINTS

If the target already exists, it will be overwritten without any warning!

If the source is a file and the target is a directory, the source will be copied into target.

If the programm dies with "Too many open files", increase the count of file descriptors (ulimit -n)

=cut

use Path::Tiny;
use IO::AIO qw(aio_copy aio_readdir);
use Getopt::Long;
use Pod::Usage;
use File::Find;
# global variables
my @options;
my $is_recursive;
GetOptions(
    'r' => \$is_recursive
) or pod2usage(2);

my $src = shift @ARGV;
my $target = shift @ARGV;
die "no target defined!" unless (defined $target);
die "no source defined!" unless (defined $src);

my $src_path = path( $src );
my $target_path = path( $target );
die "source '$src' not a file!" unless ($is_recursive || path( $src )->is_file);
if ($target_path->is_dir) {
    if (! defined $is_recursive) {
        # recalc target as $target/basename($src)
        $target_path = $target_path->child( $src_path->basename );
    }
}
# non recursive file -> file copy
if (! defined $is_recursive) {
    aio_copy($src_path->absolute->stringify, $target_path->absolute->stringify, sub {
        my $status = shift;
        if ($status) {
            die "error copying $src_path to $target_path, $!"
        }
    }
    );
} else {
    # recursive dir -> dir copy
    print "copying ",$src_path->absolute->stringify(),"/* to ",$target_path,"/\n";
    my @filepaths;
    find (sub {
        -f $_ && push @filepaths, $File::Find::name;
    }, $src_path->absolute->stringify);
    my @dirpaths;
    find (sub {
        -d $_ && push @dirpaths, $File::Find::name;
    }, $src_path->absolute->stringify);
    # make targetdirs
    foreach my $srcdir (@dirpaths) { # TODO: Parallelize with Parallel::Iterator?
        my $src = path($srcdir);
        my $relsrc = $src->relative($src_path);
        my $target = $target_path->child($relsrc);
        if (! $target->is_dir) {
            $target->mkpath(); # TODO: should be replaced with IO::AIO::Utils::mkpath
        }
    }
    # copy files
    warn("found ", scalar @filepaths, " files!") unless (scalar(@filepaths) > 1024);
    foreach my $srcfile (@filepaths) { # TODO: Parallelize with Parallel::Iterator?
        my $src = path($srcfile);
        my $relsrc = $src->relative($src_path);
        my $target = $target_path->child($relsrc);
        aio_copy($srcfile, $target->absolute->stringify, sub {
            my $status = shift;
            if ($status) {
                die "error copying $srcfile to $target, $!"
            }

        }
        );
    }
}

1;

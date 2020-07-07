use strict;
use warnings;
use strictures;
use diagnostics;
package App::turbocopy;

# ABSTRACT: CLI utility to copying files in more effective way using async IO
# VERSION

use Path::Tiny;
use IO::AIO qw(aio_copy aio_readdir);
use Pod::Usage;
use File::Find;

sub run {
    my ($is_recursive, $src, $target) = @_;
    die "no target defined!" unless (defined $target);
    die "no source defined!" unless (defined $src);

    my $src_path = path($src);
    my $target_path = path($target);
    die "source '$src' not a file!" unless ($is_recursive || path($src)->is_file);
    if ($target_path->is_dir) {
        if (!defined $is_recursive) {
            # recalc target as $target/basename($src)
            $target_path = $target_path->child($src_path->basename);
        }
    }
    # non recursive file -> file copy
    if (!defined $is_recursive) {
        aio_copy($src_path->absolute->stringify, $target_path->absolute->stringify, sub {
            my $status = shift;
            if ($status) {
                die "error copying $src_path to $target_path, $!"
            }
        }
        );
    }
    else {
        # recursive dir -> dir copy
        print "copying ", $src_path->absolute->stringify(), "/* to ", $target_path, "/\n";
        my @filepaths;
        my @dirpaths;

        no warnings 'File::Find';
        my $wanted = sub {
            if (-f $_) {push @filepaths, $File::Find::name;}
            if (-d $_) {push @dirpaths, $File::Find::name;}
        };
        use warnings;

        finddepth({
            wanted   => $wanted,
            no_chdir => 0,
            follow   => 1,
        }, $src_path->absolute->stringify);


        # make targetdirs
        foreach my $srcdir (@dirpaths) {
            # TODO: Parallelize with Parallel::Iterator?
            my $src = path($srcdir);
            my $relsrc = $src->relative($src_path);
            my $target = $target_path->child($relsrc);
            if (!$target->is_dir) {
                $target->mkpath(); # TODO: should be replaced with IO::AIO::Utils::mkpath
            }
        }

        # copy files
        warn("found ", scalar @filepaths, " files!") unless (scalar(@filepaths) < 1024);
        foreach my $srcfile (@filepaths) {
            # TODO: Parallelize with Parallel::Iterator?
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
}

1;

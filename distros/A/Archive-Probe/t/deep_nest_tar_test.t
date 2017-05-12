#!/usr/bin/perl -w
# Test case for nested tar (tgz, bz2, tar) archive.
#
# Author:          JustinZhang <fgz@qad.com>
# Creation Date:   2013-05-20
#
#
BEGIN {
    if (-d 't') {
        # running from the base directory
        push @INC, 't';
    }
}
use strict;
use Cwd;
use File::Path;
use File::Spec::Functions qw(rel2abs updir catdir catfile);
use File::Temp qw(tempdir);
use Test::More qw(no_plan);
use TestBase;
use Archive::Probe;

my $test_data_dir = get_test_data_dir();
my $test_data_no = 'tc5';
my $map = {};
my $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
my $probe = Archive::Probe->new();
SKIP: {
    skip "tar is not installed", 3 unless $probe->_is_cmd_avail('tar');

    $probe->working_dir($tmpdir);
    $probe->add_pattern(
        '\w+\.abc',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{abc} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{abc} = '';
            }
    });
    my $base_dir = catdir($test_data_dir, $test_data_no);
    $probe->reset_matches();
    $probe->search($base_dir, 1);

    # verify that the .abc file is found
    my $exp = catdir(
        'a.tar__',
        'b.tgz__',
        'c.bz2__',
        'version.abc'
    );
    is(
        $map->{abc},
        $exp,
        'file search in deep nested tar archive'
    );

    my $b = catfile(
        $tmpdir,
        'a.tar__',
        'b.tgz'
    );
    ok(-f $b, 'existence of b.tgz');

    my $c = catfile(
        $tmpdir,
        'a.tar__',
        'b.tgz__',
        'c.bz2'
    );
    ok(-f $c, 'existence of c.bz2');
}

# cleanup the temp directory to free disk space
rmtree($tmpdir);

# vim: set ai nu nobk expandtab sw=4 ts=4:

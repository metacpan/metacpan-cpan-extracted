#!/usr/bin/perl -w
# Test case for nested archive.
#
# Author:          JustinZhang <fgz@qad.com>
# Creation Date:   2013-05-13
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
my $test_data_no = 'tc2';
my $map = {};
my $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
my $probe = Archive::Probe->new();

SKIP: {
    skip "unrar is not installed", 5 unless $probe->_is_cmd_avail('unrar');
    skip "unzip is not installed", 5 unless $probe->_is_cmd_avail('unzip');
    skip "7za is not installed", 5 unless $probe->_is_cmd_avail('7za');
    skip "tar is not installed", 5 unless $probe->_is_cmd_avail('tar');

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
    my $base = catdir($test_data_dir, $test_data_no);
    $probe->reset_matches();
    $probe->search($base, 1);

    # verify that the .abc file is found
    my $exp = catdir(
        'a.rar__',
        'b.tgz__',
        'c.bz2__',
        'd.zip__',
        'e.7z__',
        'version.abc'
    );
    is(
        $map->{abc},
        $exp,
        'file search in deep nested archive'
    );

    my $b = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz'
    );
    ok(-f $b, 'existence of b.tgz');

    my $c = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz__',
        'c.bz2'
    );
    ok(-f $c, 'existence of c.bz2');

    my $d = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz__',
        'c.bz2__',
        'd.zip'
    );
    ok(-f $d, 'existence of d.zip');

    my $e = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz__',
        'c.bz2__',
        'd.zip__',
        'e.7z'
    );
    ok(-f $e, 'existence of e.7z');
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    $map = {};
    $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());

    $probe->working_dir($tmpdir);
    $base = catdir($test_data_dir, $test_data_no, "a.rar");
    $probe->reset_matches();
    $probe->search($base, 1);

    # verify that the .abc file is found
    is(
        $map->{abc},
        $exp,
        'file search in deep nested archive(start w/ file)'
    );

    $b = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz'
    );

    ok(-f $b, 'existence of b.tgz(start w/ file)');

    $c = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz__',
        'c.bz2'
    );
    ok(-f $c, 'existence of c.bz2(start w/ file)');

    $d = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz__',
        'c.bz2__',
        'd.zip'
    );
    ok(-f $d, 'existence of d.zip(start w/ file)');

    $e = catfile(
        $tmpdir,
        'a.rar__',
        'b.tgz__',
        'c.bz2__',
        'd.zip__',
        'e.7z'
    );
    ok(-f $e, 'existence of e.7z(start w/ file)');

    # cleanup the temp directory to free disk space
    rmtree($tmpdir);
}

# vim: set ai nu nobk expandtab sw=4 ts=4:

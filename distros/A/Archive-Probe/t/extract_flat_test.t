#!/usr/bin/perl -w
# Test case for nested archive extraction.
#
# Author:          JustinZhang <fgz@qad.com>
# Creation Date:   2014-01-23
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
my $probe = Archive::Probe->new();
SKIP: {
    skip "unrar is not installed", 5 unless $probe->_is_cmd_avail('unrar');
    skip "unzip is not installed", 5 unless $probe->_is_cmd_avail('unzip');
    skip "7za is not installed", 5 unless $probe->_is_cmd_avail('7za');
    skip "tar is not installed", 5 unless $probe->_is_cmd_avail('tar');

    # Non-recursive extract start with directory test case
    my $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
    my $base = catdir($test_data_dir, $test_data_no);
    my $ver_abc = catfile(
        $tmpdir,
        'version.abc'
    );
    my $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    my $c_bz2 = catfile(
        $tmpdir,
        'c.bz2'
    );
    my $d_zip = catfile(
        $tmpdir,
        'd.zip'
    );
    my $e_7z = catfile(
        $tmpdir,
        'e.7z'
    );
    my $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    my $ret = $probe->extract($base, $tmpdir, 0, 1);
    ok(
        $ret &&
        -f $dir_txt &&
        -f $b_tgz &&
        !-f $c_bz2 &&
        !-f $d_zip &&
        !-f $e_7z &&
        !-f $ver_abc,
        'Flat non-recurisve extract deep nested archive(starts w/ dir)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    # Recursive extract start with diretory test case
    $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
    $ver_abc = catfile(
        $tmpdir,
        'version.abc'
    );
    $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    $c_bz2 = catfile(
        $tmpdir,
        'c.bz2'
    );
    $d_zip = catfile(
        $tmpdir,
        'd.zip'
    );
    $e_7z = catfile(
        $tmpdir,
        'e.7z'
    );
    $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    $ret = $probe->extract($base, $tmpdir, 1, 1);
    # verify that the dir.txt exists in top level folder
    ok(
        $ret &&
        -f $dir_txt &&
        -f $b_tgz &&
        -f $c_bz2 &&
        -f $d_zip &&
        -f $e_7z &&
        -f $ver_abc,
        'Flat Recurisve extract top level file in deep nested archive(starts w/ dir)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    # Non-recursive extract start with file test case
    $ver_abc = catfile(
        $tmpdir,
        'version.abc'
    );
    $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    $c_bz2 = catfile(
        $tmpdir,
        'c.bz2'
    );
    $d_zip = catfile(
        $tmpdir,
        'd.zip'
    );
    $e_7z = catfile(
        $tmpdir,
        'e.7z'
    );
    $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    $base = catfile($test_data_dir, $test_data_no, "a.rar");
    $ret = $probe->extract($base, $tmpdir, 0, 1);
    ok(
        $ret &&
        -f $dir_txt &&
        -f $b_tgz &&
        !-f $c_bz2 &&
        !-f $d_zip &&
        !-f $e_7z &&
        !-f $ver_abc,
        'Flat non-recurisve extract deep nested archive(starts w/ file)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    # Recursive extract start with file test case
    $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
    $ver_abc = catfile(
        $tmpdir,
        'version.abc'
    );
    $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    $c_bz2 = catfile(
        $tmpdir,
        'c.bz2'
    );
    $d_zip = catfile(
        $tmpdir,
        'd.zip'
    );
    $e_7z = catfile(
        $tmpdir,
        'e.7z'
    );
    $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    $ret = $probe->extract($base, $tmpdir, 1, 1);
    # verify that all files are extracted into the top level folder
    ok(
        $ret &&
        -f $dir_txt &&
        -f $b_tgz &&
        -f $c_bz2 &&
        -f $d_zip &&
        -f $e_7z &&
        -f $ver_abc,
        'Flat Recurisve extract top level file in deep nested archive(starts w/ file)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

}

# vim: set ai nu nobk expandtab sw=4 ts=4 tw=72 :

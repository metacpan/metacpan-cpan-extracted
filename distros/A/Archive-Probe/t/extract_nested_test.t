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
    my $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    my $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    my $ret = $probe->extract($base, $tmpdir, 0);
    ok(
       $ret &&
        -f $dir_txt &&
        -f $b_tgz,
        'Non-recurisve extract deep nested archive(starts w/ dir)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    # Recursive extract start with diretory test case
    $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
    my $ver_abc = catfile(
        $tmpdir,
        'b.tgz__',
        'c.bz2__',
        'd.zip__',
        'e.7z__',
        'version.abc'
    );
    $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    $ret = $probe->extract($base, $tmpdir, 1);
    # verify that the dir.txt exists in top level folder
    ok(
       $ret &&
        -f $dir_txt,
        'Recurisve extract top level file in deep nested archive(starts w/ dir)'
    );
    # verify that the version.abc is extracted
    ok(
        -f $ver_abc,
        'Recurisve extract nested file in deep nested archive(starts w/ dir)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    # Non-recursive extract start with file test case
    $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
    $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    $base = catfile($test_data_dir, $test_data_no, "a.rar");
    $ret = $probe->extract($base, $tmpdir, 0);
    ok(
       $ret &&
        -f $dir_txt &&
        -f $b_tgz,
        'Non-recurisve extract deep nested archive(starts w/ file)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    # Recursive extract start with file test case
    $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
    $ver_abc = catfile(
        $tmpdir,
        'b.tgz__',
        'c.bz2__',
        'd.zip__',
        'e.7z__',
        'version.abc'
    );
    $b_tgz = catfile(
        $tmpdir,
        'b.tgz'
    );
    $dir_txt = catfile(
        $tmpdir,
       'dir.txt'
    );
    $ret = $probe->extract($base, $tmpdir, 1);
    # verify that the dir.txt exists in top level folder
    ok(
       $ret &&
        -f $dir_txt,
        'Recurisve extract top level file in deep nested archive(starts w/ file)'
    );
    # verify that the version.abc is extracted
    $ver_abc = catfile(
        $tmpdir,
        'b.tgz__',
        'c.bz2__',
        'd.zip__',
        'e.7z__',
        'version.abc'
    );
    ok(
        -f $ver_abc,
        'Recurisve extract nested file in deep nested archive(starts w/ file)'
    );
    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

}

# vim: set ai nu nobk expandtab sw=4 ts=4 tw=72 :

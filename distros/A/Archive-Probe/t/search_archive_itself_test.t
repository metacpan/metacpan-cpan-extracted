#!/usr/bin/perl -w
# Test case to search archive itself in deeply nested archive.
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
my $test_data_no = 'tc3';
my $map = {};
my $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
my $probe = Archive::Probe->new();
SKIP: {
    skip "unrar is not installed", 11 unless $probe->_is_cmd_avail('unrar');

    $probe->working_dir($tmpdir);
    $probe->add_pattern(
        '\w+\.rar',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                my %m1 = map {$_ => 1} @$file_ref;
                $map = \%m1;
            }
    });
    my $base_dir = catdir($test_data_dir, $test_data_no);
    $probe->reset_matches();
    $probe->search($base_dir, 1);

    # verify overall matches
    is(keys(%$map), 5, "Overall matches test");

    # verify a.rar is extracted
    my $a = catfile(
        $tmpdir,
        'a.rar'
    );
    ok($map->{$a} && -f $a, 'extract a.rar test');

    # verify b.rar is extracted
    my $b = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar'
    );
    ok($map->{$b} && -f $b, 'extract b.rar test');

    # verify c.rar is extracted
    my $c = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar__',
        'c.rar'
    );
    ok($map->{$c} && -f $c, 'extract c.rar test');

    # verify d.rar is extracted
    my $d = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar__',
        'c.rar__',
        'd.rar'
    );
    ok($map->{$d} && -f $d, 'extract d.rar test');

    # verify e.rar is extracted
    my $e = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar__',
        'c.rar__',
        'd.rar__',
        'e.rar'
    );
    ok($map->{$e} && -f $e, 'extract e.rar test');

    # cleanup the temp directory to free disk space
    rmtree($tmpdir);

    # second pass test, test file existence only
    $map = {};
    $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
    $probe->working_dir($tmpdir);
    $probe->reset_matches();
    $probe->search($base_dir, 0);

    # verify overall matches
    is(keys(%$map), 5, "Overall matches test");

    # verify a.rar exists
    $a = catfile(
        $tmpdir,
        'a.rar'
    );
    ok($map->{$a} && !-f $a, 'a.rar existence test');

    # verify b.rar exists
    $b = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar'
    );
    ok($map->{$b} && -f $b, 'b.rar existence test');

    # verify c.rar exists
    $c = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar__',
        'c.rar'
    );
    ok($map->{$c} && -f $c, 'c.rar existence test');

    # verify d.rar exists
    $d = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar__',
        'c.rar__',
        'd.rar'
    );
    ok($map->{$d} && -f $d, 'd.rar existence test');

    # verify e.rar exists
    $e = catfile(
        $tmpdir,
        'a.rar__',
        'b.rar__',
        'c.rar__',
        'd.rar__',
        'e.rar'
    );
    ok($map->{$e} && -f $e, 'e.rar existence test');
}

# cleanup the temp directory to free disk space
rmtree($tmpdir);

# vim: set ai nu nobk expandtab sw=4 ts=4:

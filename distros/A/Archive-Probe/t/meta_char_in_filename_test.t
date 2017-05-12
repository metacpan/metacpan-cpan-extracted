#!/usr/bin/perl -w
# Test case to search file w/ meta char in the name
#
# Author:          JustinZhang <fgz@qad.com>
# Creation Date:   2013-05-14
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
my $map = {};
my $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
my $probe = Archive::Probe->new();

# leading backslash test fails on Windows, skip it
SKIP: {
    skip "unrar is not installed", 2 unless $probe->_is_cmd_avail('unrar');
    skip "7za is not installed", 2 unless $probe->_is_cmd_avail('7za');
    skip "Skip backslash in filename test on Win", 2 if $^O eq 'MSWin32';

    my $test_data_no = 'tc6';
    $probe->working_dir($tmpdir);
    $probe->add_pattern(
        'version\.abc',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{version} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{version} = '';
            }
    });
    $probe->add_pattern(
        '\.go',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{go} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{go} = '';
            }
    });
    my $base_dir = catdir($test_data_dir, $test_data_no);
    $probe->reset_matches();
    $probe->search($base_dir, 1);

    # verify that the version.abc file is found
    my $exp = catfile(
        'a.zip__',
        '\\version.abc'
    );
    is(
        $map->{version},
        $exp,
        'bashslash in file name test'
    );

    # verify that the "hell.go" file is found
    $exp = catfile(
        'c.zip__',
        "\\Rock & Roll 't.zip__",
        'go',
        'hello.go'
    );
    is(
        $map->{go},
        $exp,
        'space, single quote, backslash in file name test'
    );

}

SKIP: {
    skip "unrar is not installed", 8 unless $probe->_is_cmd_avail('unrar');
    skip "unzip is not installed", 8 unless $probe->_is_cmd_avail('unzip');

    my $test_data_no = 'tc4';
    $probe->working_dir($tmpdir);
    $probe->add_pattern(
        'abc.d$',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{dot_d} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{dot_d} = '';
            }
    });
    $probe->add_pattern(
        '\.hpp$',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{hpp} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{hpp} = '';
            }
    });
    $probe->add_pattern(
        'my.*\.txt',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{txt} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{txt} = '';
            }
    });
    my $base_dir = catdir($test_data_dir, $test_data_no);
    $probe->reset_matches();
    $probe->search($base_dir, 1);

    # verify abc's.zip exists
    my $a = catfile(
        $tmpdir,
        'a.rar__',
        'abc\'s.zip'
    );
    ok(-f $a, 'existence of matched file');

    # verify that the abc.d file is found
    my $exp = catfile(
        'a.rar__',
        'abc\'s.zip__',
        'abc.d'
    );
    is(
        $map->{dot_d},
        $exp,
        'single quote in zip file name test'
    );
    $a = catfile(
        $tmpdir,
        'a.rar__',
        'abc\'s.zip__',
        'abc.d'
    );
    ok(-f $a, 'existence of matched file');

    # verify that the "quick & dirty sort.hpp" file is found
    $exp = catfile(
        'b.zip__',
        'cpp',
        'quick & dirty sort.hpp'
    );
    is(
        $map->{hpp},
        $exp,
        'space in file name test'
    );
    $a = catfile(
        $tmpdir,
        'b.zip__',
        'cpp',
        'quick & dirty sort.hpp'
    );
    ok(-f $a, 'existence of matched file');

    # verify that the "my ##&**|>>(1).txt" file is found
    $exp = catfile(
        'd.zip__',
        'a{0} (0) [0]',
        'my ##&**|>>(1).txt'
    );
    is(
        $map->{txt},
        $exp,
        'comprehensive meta-char file name test'
    );
    $a = catfile(
        $tmpdir,
        'd.zip__',
        'a{0} (0) [0]',
        $^O ne 'MSWin32' ? 'my ##&**|>>(1).txt' : 'my ##&_____(1).txt'
    );
    ok(-f $a, 'existence of matched file');
}

# cleanup the temp directory to free disk space
#rmtree($tmpdir);

# vim: set ai nu nobk expandtab sw=4 ts=4:

#!/usr/bin/perl -w
# Test case for common Java archives such as .jar, .war and .ear
#
# Author:          JustinZhang <fgz@qad.com>
# Creation Date:   2013-09-23
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
my $test_data_no = 'tc7';
my $map = {};
my $tmpdir = tempdir('_arXXXXXXXX', DIR => File::Spec->tmpdir());
my $probe = Archive::Probe->new();
SKIP: {
    skip "unzip is not installed", 3 unless $probe->_is_cmd_avail('unzip');

    $probe->working_dir($tmpdir);
    $probe->add_pattern(
        'MANIFEST\.MF$',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{mf} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{mf} = '';
            }
    });
    $probe->add_pattern(
        'Pattern\.class$',
        sub {
            my ($pattern, $file_ref) = @_;

            if (@$file_ref) {
                $map->{clazz} = $probe->_strip_dir($tmpdir, $file_ref->[0]);
            }
            else {
                $map->{clazz} = '';
            }
    });
    my $base_dir = catdir($test_data_dir, $test_data_no);
    $probe->reset_matches();
    $probe->search($base_dir, 1);

    # verify that the MANIFEST.MF file is found
    my $exp = catdir(
        'oro.jar__',
        'META-INF',
        'MANIFEST.MF'
    );
    is(
        $map->{mf},
        $exp,
        'search MANIFEST in jar file'
    );
    # verify that the MANIFEST.MF file is extracted correctly
    my $f = catfile(
        $tmpdir,
        'oro.jar__',
        'META-INF',
        'MANIFEST.MF'
    );
    ok(-f $f, 'existence of MANIFEST.MF');

    # verify that the Pattern.class file is found
    $exp = catdir(
        'oro.jar__',
        'org',
        'apache',
        'oro',
        'text',
        'regex',
        'Pattern.class'
    );
    is(
        $map->{clazz},
        $exp,
        'search org.apache.oro.text.regex.Pattern in jar file'
    );
    # verify that the MANIFEST.MF file is extracted correctly
    $f = catfile(
        $tmpdir,
        'oro.jar__',
        'org',
        'apache',
        'oro',
        'text',
        'regex',
        'Pattern.class'
    );
    ok(-f $f, 'existence of Pattern.class');
}

# cleanup the temp directory to free disk space
rmtree($tmpdir);

# vim: set ai nu nobk expandtab sw=4 ts=4:

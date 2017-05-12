#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use MooX::Cmd::Tester;
use App::Math::Tutor;

use File::Path qw(mkpath rmtree);

my $test_dir;
my $keep;
my $format;

BEGIN
{
    defined $ENV{KEEP_TEST_OUTPUT} and $keep = $ENV{KEEP_TEST_OUTPUT};
    defined $ENV{TEST_OUTPUT_TYPE} and $format = $ENV{TEST_OUTPUT_TYPE};
    if ( defined( $ENV{TEST_DIR} ) )
    {
        $test_dir = $ENV{TEST_DIR};
        -d $test_dir or mkpath $test_dir;
        $keep = 1;
    }
    else
    {
        $test_dir = File::Spec->rel2abs( File::Spec->curdir() );
        $test_dir = File::Spec->catdir( $test_dir, "test_output_" . $$ );
        $test_dir = VMS::Filespec::unixify($test_dir) if $^O eq 'VMS';
        rmtree $test_dir;
        mkpath $test_dir;
    }

    defined $format or $format = "tex";
}

END { defined($test_dir) and rmtree $test_dir unless $keep }

my $rv;

$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(vulfrac add --output-type), $format, qw(--output-location), $test_dir ] );
$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(vulfrac mul -t), $format, qw(-o),     $test_dir ] );
$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(vulfrac cast -t), $format, qw(-o),    $test_dir ] );
$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(vulfrac compare -t), $format, qw(-o), $test_dir ] );

$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(natural add -t), $format, qw(-o), $test_dir ] );

$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(roman add -t), $format, qw(-o),  $test_dir ] );
$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(roman cast -t), $format, qw(-o), $test_dir ] );

$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(unit add -t), $format, qw(-o),     $test_dir ] );
$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(unit cast -t), $format, qw(-o),    $test_dir ] );
$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(unit compare -t), $format, qw(-o), $test_dir ] );

$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(poly solve -t), $format, qw(-o), $test_dir ] );

$rv = test_cmd_ok( 'App::Math::Tutor' => [ qw(power rules -t), $format, qw(-o), $test_dir ] );

done_testing;

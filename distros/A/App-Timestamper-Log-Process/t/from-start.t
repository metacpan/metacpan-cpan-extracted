#!/usr/bin/env perl

use strict;
use warnings;
use 5.014;
use autodie;

use Test::More tests => 11;

use Path::Tiny qw/ cwd path tempdir tempfile /;

my $dir = tempdir( 'CLEANUP' => 1 );
my $inputfn =
    cwd()->child( "t", "data", "sample-input-logs", "hp1.build.log.txt" );

my $expected_results_fn =
    cwd()
    ->child( "t", "data", "expected-output", "from-start",
    "hp1.build.log.txt" );

sub _portable_lines
{
    my $fh = shift;

    return $fh->lines( { binmode => ":raw:encoding(UTF-8)", chomp => 1, } );
}

sub _portable_lines_aref
{
    my $fh = shift;
    return [ _portable_lines($fh) ];
}

{
    my $ofn = $dir->child("output.log.txt");
    system(
        $^X,  "-Mblib", "-MApp::Timestamper::Log::Process",
        "-e", "App::Timestamper::Log::Process->new({argv => [\@ARGV,]})->run()",
        "--", "from_start", "--output", $ofn, $inputfn,
    );

    # TEST
    ok( scalar( -f $ofn ), "from_start app-mode produced a file", );

    # TEST
    is_deeply(
        _portable_lines_aref($ofn),
        _portable_lines_aref($expected_results_fn),
        "Expected from-start results ",
    )
}

{
    my $ofn = $dir->child("output_script.log.txt");
    system( $^X, "-Mblib", cwd()->child( "bin", "timestamper-log-process", ),
        "from_start", "--output", $ofn, $inputfn, );

    # TEST
    ok( scalar( -f $ofn ), "from_start app-mode produced a file", );

    # TEST
    is_deeply(
        _portable_lines_aref($ofn),
        _portable_lines_aref($expected_results_fn),
        "Expected from-start results",
    )
}

{
    my $ofn = $dir->child("output-dash.log.txt");
    system(
        $^X,  "-Mblib", "-MApp::Timestamper::Log::Process",
        "-e", "App::Timestamper::Log::Process->new({argv => [\@ARGV,]})->run()",
        "--", "from-start", "--output", $ofn, $inputfn,
    );

    # TEST
    ok( scalar( -f $ofn ), "from-start dash app-mode produced a file", );

    # TEST
    is_deeply(
        _portable_lines_aref($ofn),
        _portable_lines_aref($expected_results_fn),
        "Expected from-start with dash results",
    )
}

{
    my $ofn = $dir->child("output_time.log.txt");
    system( $^X, "-Mblib", cwd()->child( "bin", "timestamper-log-process", ),
        "time", "--output", $ofn, $inputfn, );

    # TEST
    ok( scalar( -f $ofn ), "time app-mode produced a file", );

    # TEST
    like(
        _portable_lines_aref($ofn)->[0],
        qr#\A112\.86074400\s#ms, "Expected time-mode results",
    );
}

{
    my $ofn      = $dir->child("output_time2.log.txt");
    my $inputfn2 = cwd()->child(
        "t",                 "data",
        "sample-input-logs", "abc-path-TypeScript-generator-mt-rand.log.txt"
    );
    system( $^X, "-Mblib", cwd()->child( "bin", "timestamper-log-process", ),
        "time", "--output", $ofn, $inputfn, $inputfn2, );

    # TEST
    ok( scalar( -f $ofn ), "time app-mode produced a file", );
    my $lines = _portable_lines_aref($ofn);

    # TEST
    like( $lines->[0], qr#\A112\.86074400\s#ms, "Expected time-mode results", );

    # TEST
    like( $lines->[1],
        qr#\A150\.14364291\s#ms, "Expected multiple time-mode results 2nd line",
    );
}

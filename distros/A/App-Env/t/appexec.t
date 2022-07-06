#!perl

use Test2::V0;
use Test::Lib;

use File::Spec::Functions qw[ catfile ];
use Capture::Tiny 'capture_stdout';


my $exe    = catfile( qw[ blib script appexec ] );
my $lib    = catfile( qw[ t lib ] );
my $script = catfile( qw [ t bin appexec.pl ] );

subtest 'direct' => sub {
    my ( $stdout, $exit ) = capture_stdout {
        system( $^X, '-Mblib', "-I${lib}", $exe, 'App1', $^X, $script,
            'Site1_App1', );
    };


    is( $exit, 0, 'run appexec for App1' )
      or bail_out( "error running appexec" );

    chomp $stdout;
    is( $stdout, '1', 'result' );
};

subtest 'alias' => sub {
    my ( $stdout, $exit ) = capture_stdout {
        system( $^X, '-Mblib', "-I${lib}", $exe, 'App3', $^X, $script,
            'Site1_App1', );
    };

    is( $exit, 0, 'run appexec for App1' )
      or bail_out( "error running appexec" );

    chomp $stdout;
    is( $stdout, '1', 'result' );
};

subtest 'define' => sub {
    my ( $stdout, $exit ) = capture_stdout {
        system( $^X, '-Mblib',
            "-I${lib}", $exe,
            '-D',       'TEST_APPEXEC_DEFINE=got_three_please',
            '--env',    'App1',
            $^X,        $script,
            'TEST_APPEXEC_DEFINE',
        );
    };

    is( $exit, 0, 'run appexec for App1' )
      or bail_out( "error running appexec" );

    chomp $stdout;
    is( $stdout, 'got_three_please', 'result' );
};

subtest 'dumpvar' => sub {
    my ( $stdout, $exit ) = capture_stdout {
        system( $^X, '-Mblib',
            "-I${lib}",  $exe,
            '-D',        'TEST_APPEXEC_DEFINE0=got_three_please',
            '-D',        'TEST_APPEXEC_DEFINE1=got_four_please',
            '--env',     'App1',
            '--dumpenv', 'values',
            '--dumpvar', 'TEST_APPEXEC_DEFINE0',
            '--dumpvar', 'TEST_APPEXEC_DEFINE1',
        );
    };

    is( $exit, 0, 'run appexec for App1' )
      or bail_out( "error running appexec" );

    chomp $stdout;
    my @output = split /\n/, $stdout;

    is(
        \@output,
        bag {
            item 'got_three_please';
            item 'got_four_please';
            end;
        },
        'result'
    );
};


done_testing;

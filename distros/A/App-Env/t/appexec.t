#!perl

use Test2::V0;
use Test::Lib;
use Test::Script;

use File::Spec::Functions qw[ catfile ];
use Capture::Tiny 'capture_stdout';

my $exe    = catfile( qw[ script appexec ] );
my $lib    = catfile( qw[ t lib ] );
my $script = catfile( qw [ t bin appexec.pl ] );

my @run_script = ( $^X, '-It/lib', $script );

if ( 0 ) {
    subtest 'direct' => sub {
        script_runs( [ $exe, 'App1', @run_script, 'Site1_App1' ] );
        script_stdout_is( "1\n", 'result' );
    };


    subtest 'alias' => sub {
        script_runs( [ $exe, 'App3', @run_script, 'Site1_App1' ] );
        script_stdout_is( "1\n", 'result' );
    };

    subtest 'define' => sub {
        script_runs( [
            $exe,
            -D => 'TEST_APPEXEC_DEFINE=got_three_please',
            '--env', 'App1', @run_script, 'TEST_APPEXEC_DEFINE',
        ] );
        script_stdout_is( "got_three_please\n", 'result' );
    };

    subtest 'dumpenv' => sub {

        subtest 'values' => sub {
            script_runs( [
                    $exe,
                    -D => 'TEST_APPEXEC_DEFINE0=got_three_please',
                    -D => 'TEST_APPEXEC_DEFINE1=got_four_please',
                    '--env',     'App1',
                    '--dumpenv', 'values',
                    '--dumpvar', 'TEST_APPEXEC_DEFINE0',
                    '--dumpvar', 'TEST_APPEXEC_DEFINE1',
                ],
                {
                    stdout              => \my $stdout,
                    interpreter_options => [ -I => 't/lib' ],
                },
            );

            chomp $stdout;
            my @output = split /\n/, $stdout;
            is(
                \@output,
                bag {
                    item 'got_three_please';
                    item 'got_four_please';
                    end;
                },
                'result',
            );
        };
    };


}

subtest 'shell' => sub {
        #<<<
        script_runs( [
            $exe,
            '-D', 'TEST_APPEXEC_DEFINE0=got_three_please',
            '-D', 'TEST_APPEXEC_DEFINE1=got_four_please',
            '-D', 'TEST_APPEXEC_BASH_FUNC_ml%%=fake_bash_passing_function_to_subshell',
            '--clear',
            '--env', 'App1',
            '--dumpenv', 'bash',
            ],
            {
                stdout              => \my $stdout,
                interpreter_options => [ -I => 't/lib' ],
            },
        );
        #>>>

    my %output = map {
        s/;$//;
        my ( $key, $value ) = split( /=/, $_, 2 );
        ( $key => $value );
      }
      grep /^TEST_APPEXEC_/, split /\n/, $stdout;

    is(
        \%output,
        hash {
            field TEST_APPEXEC_DEFINE0 => q{'got_three_please'};
            field TEST_APPEXEC_DEFINE1 => q{'got_four_please'};
            end;
        },
        'result',
    );
};



done_testing;

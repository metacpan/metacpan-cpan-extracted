use strict;
use warnings;

use Test::More;

use App::Commando;

my %tests = (
    'No arguments and no switches' => {
        ARGV            => [],
        expected_argv   => [],
        expected_config => {},
    },
    'One short switch' => {
        ARGV            => [ '-f' ],
        expected_argv   => [],
        expected_config => { 'foo' => '1' },
    },
    'One long switch' => {
        ARGV            => [ '--bar' ],
        expected_argv   => [],
        expected_config => { 'bar' => '1' },
    },
    'Two long switches' => {
        ARGV            => [ '--foo', '--bar' ],
        expected_argv   => [],
        expected_config => { 'foo' => '1', 'bar' => '1' },
    },
    'One argument' => {
        ARGV            => [ 'xyzzy' ],
        expected_argv   => [ 'xyzzy' ],
        expected_config => {},
    },
    'One argument and one short switch' => {
        ARGV            => [ '-f', 'xyzzy' ],
        expected_argv   => [ 'xyzzy' ],
        expected_config => { 'foo' => '1' },
    },
    'Two arguments' => {
        ARGV            => [ 'xyzzy', 'zzyxy' ],
        expected_argv   => [ 'xyzzy', 'zzyxy' ],
        expected_config => {},
    },
    'Two arguments and one long switch' => {
        ARGV            => [ '--bar', 'xyzzy', 'zzyxy' ],
        expected_argv   => [ 'xyzzy', 'zzyxy' ],
        expected_config => { 'bar' => '1' },
    },
);

for my $test_name (keys %tests) {
    local @ARGV = @{$tests{$test_name}->{ARGV}};

    my $program = App::Commando::program('test');
    $program->option('foo', '-f', '--foo', 'Enables foo');
    $program->option('bar', '-b', '--bar', 'Enables bar');
    $program->action(sub {
        my ($argv, $config) = @_;

        is_deeply $argv, $tests{$test_name}->{expected_argv},
            "$test_name: argv";
        is_deeply $config, $tests{$test_name}->{expected_config},
            "$test_name: config";
    });
    $program->go;
}

done_testing;

use strict;
use warnings;
use Test::More;
use Test::MockObject;
use App::Ikaros::LandingPoint;
use App::Ikaros::Planner;

my $plan = {
    prove_tests     => [ 'test.t' ],
    forkprove_tests => [ 'test2.t' ],
    prove_command   => [ '$prove' ],
    chdir => ''
};


my $mock = Test::MockObject->new;
$mock->fake_module('Net::OpenSSH',
                   'new'   => sub { bless {}, 'Net::OpenSSH'; },
                   'error' => sub { '' });

my $hosts = [
    App::Ikaros::LandingPoint->new({
        user     => $ENV{USER},
        runner   => 'prove',
    }, 'localhost'),
    App::Ikaros::LandingPoint->new({
        user     => $ENV{USER},
        runner   => 'forkprove',
    }, 'localhost')
];

my $planner = App::Ikaros::Planner->new($hosts, $plan);
$planner->planning($_, $plan) foreach @$hosts;

is_deeply($hosts->[0]->{prove}, [
    '-I$HOME/ikaros_lib',
    '-I$HOME/ikaros_lib/lib/perl5',
    '$HOME/ikaros_lib/bin/Prove.pm',
    '--state=save'
], 'prove commands');

is_deeply($hosts->[1]->{plan}, [
    'mkdir -p $HOME/ikaros_lib/bin',
    'cd $HOME',
    'cd $HOME/ && echo \'IKAROS:BUILD_START\' && ((perl -I$HOME/ikaros_lib $HOME/$HOME_localhost_build_kicker.pl) || echo 1) && (if [ -e junit_output.xml ]; then mv junit_output.xml $HOME; fi;) && (if [ -e .prove ]; then mv .prove $HOME; fi;) && echo \'skip move cover_db\' && echo \'IKAROS:BUILD_END\'',
    'cd $HOME'
], 'plan');

done_testing;

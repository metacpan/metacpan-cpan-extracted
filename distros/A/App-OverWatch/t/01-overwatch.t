
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('App::OverWatch');

my $OverWatch = App::OverWatch->new();

isa_ok($OverWatch, 'App::OverWatch');

my $rh_options = {
    opta => 1,
    optb => 1,

    cmda => 0,
    cmdb => 1,
};

my $rh_commands = {
    cmda => sub { },
    cmdb => sub { },
};

my $rh_required_options = {
    cmda => [ qw( opta ) ],
    cmdb => [ qw( opta optb ) ],
};

## Basic case
{
    my $cmd = $OverWatch->check_options({
        options          => $rh_options,
        valid_commands   => [ keys %$rh_commands ],
        required_options => $rh_required_options,
    });

    is($cmd, 'cmdb', 'Deduced command is cmdb');
}

## Bad commands
{
    my $cmd;

    $rh_options->{cmdb} = 0;

    throws_ok {
        $cmd = $OverWatch->check_options({
            options          => $rh_options,
            valid_commands   => [ keys %$rh_commands ],
            required_options => $rh_required_options,
        });
    } qr/Please specify one and only one command/, 'No command dies';

    $rh_options->{cmda} = 1;
    $rh_options->{cmdb} = 1;

    throws_ok {
        $cmd = $OverWatch->check_options({
            options          => $rh_options,
            valid_commands   => [ keys %$rh_commands ],
            required_options => $rh_required_options,
        });
    } qr/Please specify one and only one command/, 'Too many commands dies';

    $rh_options->{cmdb} = 0;

    lives_ok {
        $cmd = $OverWatch->check_options({
            options          => $rh_options,
            valid_commands   => [ keys %$rh_commands ],
            required_options => $rh_required_options,
        });
    } 'Single command is ok';
}

## Bad options
{
    my $cmd;

    my $rh_bad_opts = {
        opta => 1,
        optb => undef,

        cmda => 1,
        cmdb => 0,
    };

    lives_ok {
        $cmd = $OverWatch->check_options({
            options          => $rh_bad_opts,
            valid_commands   => [ keys %$rh_commands ],
            required_options => $rh_required_options,
        });
    } 'cmda with opta is ok';
    is($cmd, 'cmda', 'Deduced command is cmda');

    ## cmda requires opta
    $rh_bad_opts->{opta} = undef;

    throws_ok {
        $cmd = $OverWatch->check_options({
            options          => $rh_bad_opts,
            valid_commands   => [ keys %$rh_commands ],
            required_options => $rh_required_options,
        });
    } qr/--opta is a required option/, 'cmda without opta dies';

    ## cmdb requires opta and optb
    $rh_bad_opts->{cmda} = 0;
    $rh_bad_opts->{cmdb} = 1;

    throws_ok {
        $cmd = $OverWatch->check_options({
            options          => $rh_bad_opts,
            valid_commands   => [ keys %$rh_commands ],
            required_options => $rh_required_options,
        });
    } qr/--opta is a required option/, 'cmdb without opta/optb dies';
}

done_testing();

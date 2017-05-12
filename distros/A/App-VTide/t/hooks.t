#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use App::VTide;

my $module = 'App::VTide::Hooks';
use_ok( $module );

my $vtide = App::VTide->new;

run();
internal();

done_testing();

sub run {
    $vtide->config->global_config('nowhere/.vtide.yml');
    my $hooks = eval {
        $module->new(
            vtide => $vtide,
        )
    };
    ok $hooks, 'Create new cmd' || diag $@;

    eval { $hooks->run('missing_hook') };
    my $error = $@;
    ok !$error, 'No errors running a missing hook' or diag $error;

    $hooks->hook_cmds->{found_hook} = sub {
        my ($self, $alter) = @_;
        $$alter++;
    };
    my $val = 1;
    $hooks->run('found_hook', \$val);
    is $val, 2, 'Found hook runs';
}

sub internal {
    $vtide->config->global_config('t/.vtide.yml');
    $vtide->config->local_config('t/.vtide.yml');
    my $hooks = eval {
        $module->new(
            vtide => $vtide,
        )
    };

    ok $hooks->hook_cmds->{local}, 'Read local hooks file';
    ok $hooks->hook_cmds->{global}, 'Read global hooks file';
}

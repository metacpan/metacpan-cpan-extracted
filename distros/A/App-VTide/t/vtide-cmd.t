#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use App::VTide;
use Path::Tiny;
use File::chdir;

my $module = 'App::VTide::Command';
use_ok( $module );

my $vtide = App::VTide->new;

env();

done_testing();

sub env {
    my $cmd = eval {
        $module->new(
            vtide    => $vtide,
            defaults => {},
        )
    };
    ok $cmd, 'Create new cmd' || diag $@;

    local $ENV{VTIDE_NAME}   = '';
    local $ENV{VTIDE_DIR}    = '';
    local $ENV{VTIDE_CONFIG} = '';

    $cmd->env('name', 'dir', 'config');
    is $ENV{VTIDE_NAME}, 'name', 'Environment variable name set correctly';
    is $ENV{VTIDE_DIR}, 'dir', 'Environment variable dir set correctly';
    is $ENV{VTIDE_CONFIG}, 'config', 'Environment variable config set correctly';

    $cmd->env();
    is $ENV{VTIDE_NAME}, 'name', 'Environment variable name set correctly (again)';
    is $ENV{VTIDE_DIR}, ''.path($CWD, 'dir'), 'Environment variable dir set correctly (again)';
    is $ENV{VTIDE_CONFIG}, 'config', 'Environment variable config set correctly (again)';

    local $ENV{VTIDE_NAME}   = '';
    local $ENV{VTIDE_DIR}    = '';
    local $ENV{VTIDE_CONFIG} = '';

    $cmd->env();
    is $ENV{VTIDE_NAME}, 'vtide', 'Environment variable name set correctly (again)';
    is $ENV{VTIDE_DIR}, $CWD, 'Environment variable dir set correctly (again)';
    is $ENV{VTIDE_CONFIG}, ''.path($CWD, '.vtide.yml'), 'Environment variable config set correctly (again)';
}

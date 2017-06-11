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

#env();
#save_session();
#session_dir();

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
    diag $ENV{VTIDE_DIR};
    is $ENV{VTIDE_DIR}, 'dir', 'Environment variable dir set correctly';
    is $ENV{VTIDE_CONFIG}, 'config', 'Environment variable config set correctly';

    $cmd->env();
    is $ENV{VTIDE_NAME}, 'name', 'Environment variable name set correctly (again)';
    diag $ENV{VTIDE_DIR};
    #is $ENV{VTIDE_DIR}, ''.path($CWD, 'dir'), 'Environment variable dir set correctly (again)';
    is $ENV{VTIDE_CONFIG}, 'config', 'Environment variable config set correctly (again)';

    local $ENV{VTIDE_NAME}   = '';
    local $ENV{VTIDE_DIR}    = '';
    local $ENV{VTIDE_CONFIG} = '';

    $cmd->env();
    is $ENV{VTIDE_NAME}, 'vtide', 'Environment variable name set correctly (again)';
    diag $ENV{VTIDE_DIR};
    is $ENV{VTIDE_DIR}, $CWD, 'Environment variable dir set correctly (again)';
    is $ENV{VTIDE_CONFIG}, ''.path($CWD, '.vtide.yml'), 'Environment variable config set correctly (again)';
}

sub save_session {
    unlink 't/history.yml' if -f 't/history.yml';
    my $cmd = eval {
        $module->new(
            history  => path('t/history.yml'),
            vtide    => $vtide,
            defaults => {},
        )
    };
    ok $cmd, 'Create new cmd' || diag $@;
    # skipping if history file isn't writable
    return if ! -w $cmd->history->parent;

    local $ENV{VTIDE_NAME}   = '';
    local $ENV{VTIDE_DIR}    = '';
    local $ENV{VTIDE_CONFIG} = '';

    $cmd->save_session('test', 'dir');
    ok -f $cmd->history, 'History file created';

    # save session again to check updating works
    $cmd->save_session('test', 'dir');
    ok -f $cmd->history, 'History file created';

    unlink 't/history.yml' if -f 't/history.yml';
}

sub session_dir {
    my $cmd = eval {
        $module->new(
            history  => path('t/history.yml'),
            vtide    => $vtide,
            defaults => {},
        )
    };
    ok $cmd, 'Create new cmd' || diag $@;
    # skipping if history file isn't writable
    return if ! -w $cmd->history->parent;

    local $ENV{VTIDE_NAME}   = '';
    local $ENV{VTIDE_DIR}    = '';
    local $ENV{VTIDE_CONFIG} = '';

    my ($name, $dir) = $cmd->session_dir();
    is $dir, $CWD, 'Default directory name';

    $cmd->save_session($name, $dir);

    ($name, $dir) = $cmd->session_dir('vtide');
    is $dir, $CWD, 'Application default directory name';
    unlink 't/history.yml' if -f 't/history.yml';
}

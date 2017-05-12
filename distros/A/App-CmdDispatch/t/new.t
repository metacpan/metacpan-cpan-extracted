#!/usr/bin/env perl

use Test::More tests => 8;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use App::CmdDispatch;

{
    my $label = 'Single command, handler only';
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
    );
    isa_ok( $app, 'App::CmdDispatch' );

    is_deeply [ $app->command_list() ], [qw/noop/], "$label: noop found";
}

{
    my $label = 'Single command plus shell';
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
        {
            default_commands => 'shell'
        },
    );
    isa_ok( $app, 'App::CmdDispatch' );

    is_deeply [ $app->command_list() ], [qw/noop shell/], "$label: explicit and default commands found";
}

{
    my $label = 'Single command plus help';
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
        {
            default_commands => 'help'
        },
    );
    isa_ok( $app, 'App::CmdDispatch' );

    is_deeply [ $app->command_list() ], [qw/noop hint help/], "$label: explicit and default commands found";
}

{
    my $label = 'Single command plus help and shell';
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
        {
            default_commands => 'shell help'
        },
    );
    isa_ok( $app, 'App::CmdDispatch' );

    is_deeply [ $app->command_list() ], [qw/noop shell hint help/], "$label: explicit and default commands found";
}

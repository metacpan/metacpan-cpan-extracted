#!/usr/bin/env perl

use Test::More tests => 20;

use strict;
use warnings;

use App::CmdDispatch::Table;

{
    my $label = 'Single command';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop/], "$label: noop found";
}

{
    my $label = 'Double command';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
            noop2 => { code => sub {} },
        },
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop noop2/], "$label: both found";
}

{
    my $label = 'Single command, single alias';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
        {
            other => 'noop another time',
        }
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop/], "$label: noop found";
    is_deeply [ $app->alias_list() ], [qw/other/], "$label: other found";
}

{
    my $label = 'Double command, double alias';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
            noop2 => { code => sub {} },
        },
        {
            other => 'noop another time',
            another => 'noop2 yet again',
        }
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop noop2/], "$label: both commands found";
    is_deeply [ $app->alias_list() ], [qw/another other/], "$label: both aliases found";
}

{
    my $label = 'Discard empty command';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
            '' => { code => sub {} },
        },
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop/], "$label: noop found";
}

{
    my $label = 'Discard empty alias';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
        {
            other => 'noop another time',
            '' => 'noop should not get here',
        }
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop/], "$label: noop found";
    is_deeply [ $app->alias_list() ], [qw/other/], "$label: other found";
}

{
    my $label = 'Discard undefined command descriptor';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
            missing => undef,
        },
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop/], "$label: noop found";
}

{
    my $label = 'Discard undefined alias';
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
        {
            other => 'noop another time',
            missing => undef,
        }
    );
    isa_ok( $app, 'App::CmdDispatch::Table' );

    is_deeply [ $app->command_list() ], [qw/noop/], "$label: noop found";
    is_deeply [ $app->alias_list() ], [qw/other/], "$label: other found";
}


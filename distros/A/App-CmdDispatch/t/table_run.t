#!/usr/bin/env perl

use Test::More tests => 5;
use Test::Exception;

use strict;
use warnings;

use App::CmdDispatch::Table;

# TODO - need a mock object to pass as first parameter and need to test for it in run.
{
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
    );

    throws_ok { $app->run(); } 'App::CmdDispatch::Exception::MissingCommand', "Running with no parameters gives error.\n";
}

{
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
    );

    throws_ok { $app->run( {} ); } 'App::CmdDispatch::Exception::MissingCommand', "Running with no command gives error.\n";
}

{
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
    );

    throws_ok { $app->run( {}, '' ); } 'App::CmdDispatch::Exception::MissingCommand', "Running with empty command gives error.\n";
}

{
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
    );

    lives_ok { $app->run( {}, 'noop' ); } "noop command run successfully";
}

{
    my $app = App::CmdDispatch::Table->new(
        {
            noop => { code => sub {} },
        },
    );

    throws_ok { $app->run( {}, 'foo' ); } 'App::CmdDispatch::Exception::UnknownCommand', "Unrecognized command gives error";
}


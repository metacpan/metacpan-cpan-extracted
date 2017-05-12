#!/usr/bin/env perl

use Test::More tests => 4;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::IO;

use App::CmdDispatch;

{
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
        { io => $io, default_commands => 'help shell' }
    );

    $app->run();
    is( $io->output, <<EOF, "Running with no command gives error.\n" );
Missing command

Commands:
  noop
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF
}

{
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
        { io => $io, default_commands => 'help shell' }
    );

    $app->run( '' );
    is( $io->output, <<EOF, "Running with empty command gives error.\n" );
Missing command

Commands:
  noop
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF
}

{
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
        { io => $io, default_commands => 'help shell' }
    );

    $app->run( 'hint' );
    is( $io->output, <<EOF, "Synopsis command run successfully" );

Commands:
  noop
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF
}

{
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new(
        {
            noop => { code => sub {} },
        },
        { io => $io, default_commands => 'help shell' }
    );

    $app->run( 'foo' );
    is( $io->output, <<EOF, "Unrecognized command gives error" );
Unrecognized command 'foo'

Commands:
  noop
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF
}


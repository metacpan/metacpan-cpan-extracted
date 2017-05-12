#!/usr/bin/env perl

use Test::More tests => 19;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::IO;

use App::CmdDispatch;

{
    my $label = 'Single command, handler only';
    my $io    = Test::IO->new();
    my $app   = App::CmdDispatch->new(
        {
            noop => {
                code => sub { }
            },
        },
        { io => $io, default_commands => 'shell help' }
    );

    $app->hint;
    is( $io->output, <<EOF, "$label: Default hint supplied" );

Commands:
  noop
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF
}

{
    my $label = 'Single command, handler and hint';
    my $io    = Test::IO->new();
    my $app   = App::CmdDispatch->new(
        { noop => { code => sub { }, clue => 'noop [n]' }, },
        { io => $io, default_commands => 'shell help' }
    );

    $app->hint;
    is( $io->output, <<EOF, "$label: Help as supplied" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF
}

{
    my $label = 'Single command, all supplied';
    my $io    = Test::IO->new();
    my $app   = App::CmdDispatch->new(
        { noop => { code => sub { }, clue => 'noop [n]', help => 'Does nothing, n times.' }, },
        { io => $io, default_commands => 'shell help' } );

    $app->hint;
    is( $io->output, <<EOF, "$label: Help as supplied" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF

    $io->clear;
    $app->hint( undef );
    is( $io->output, <<EOF, "$label: undef supplied to hint" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF

    $io->clear;
    $app->hint( '' );
    is( $io->output, <<EOF, "$label: empty string supplied to hint" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF

    $io->clear;
    $app->hint( 0 );
    is( $io->output, "Unrecognized command '0'\n", "$label: zero supplied to hint" );

    $io->clear;
    $app->hint( 'noop' );
    is( $io->output, <<EOF, "$label: command supplied to hint" );

noop [n]
EOF

    $io->clear;
    $app->hint( 'hint' );
    is( $io->output, <<EOF, "$label: hint supplied to hint" );

hint [command|alias]   Display command hints
EOF

    $io->clear;
    $app->hint( 'commands' );
    is( $io->output, <<EOF, "$label: 'commands' supplied to hint" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF

    $io->clear;
    $app->hint( 'aliases' );
    is( $io->output, '', "$label: 'aliases' supplied to hint, with no aliases" );
}

{
    my $label = 'Single command, all supplied, aliases';
    my $io    = Test::IO->new();
    my $app   = App::CmdDispatch->new(
        { noop => { code => sub { }, clue => 'noop [n]', help => 'Does nothing, n times.' }, },
        { io => $io, default_commands => 'shell help', alias => { help2 => 'help help' } }
    );

    $app->hint;
    is( $io->output, <<EOF, "$label: Help as supplied" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help

Aliases:
  help2 : help help
EOF

    $io->clear;
    $app->hint( undef );
    is( $io->output, <<EOF, "$label: undef supplied to hint" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help

Aliases:
  help2 : help help
EOF

    $io->clear;
    $app->hint( '' );
    is( $io->output, <<EOF, "$label: empty string supplied to hint" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help

Aliases:
  help2 : help help
EOF

    $io->clear;
    $app->hint( 0 );
    is( $io->output, "Unrecognized command '0'\n", "$label: zero supplied to hint" );

    $io->clear;
    $app->hint( 'noop' );
    is( $io->output, <<EOF, "$label: command supplied to hint" );

noop [n]
EOF

    $io->clear;
    $app->hint( 'hint' );
    is( $io->output, <<EOF, "$label: hint supplied to hint" );

hint [command|alias]   Display command hints
EOF

    $io->clear;
    $app->hint( 'commands' );
    is( $io->output, <<EOF, "$label: 'commands' supplied to hint" );

Commands:
  noop [n]
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
EOF

    $io->clear;
    $app->hint( 'aliases' );
    is( $io->output, <<EOF, "$label: ask for alias list" );

Aliases:
  help2 : help help
EOF

    $io->clear;
    $app->hint( 'help2' );
    is( $io->output, <<EOF, "$label: alias supplied to hint" );

help2 : help help
EOF
}

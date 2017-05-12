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

    $app->help;
    is( $io->output, <<EOF, "$label: Default help supplied" );

Commands:
  noop

  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF
}

{
    my $label = 'Single command, handler and hint';
    my $io    = Test::IO->new();
    my $app   = App::CmdDispatch->new(
        { noop => { code => sub { }, clue => 'noop [n]' }, },
        { io => $io, default_commands => 'shell help' }
    );

    $app->help;
    is( $io->output, <<EOF, "$label: Help as supplied" );

Commands:
  noop [n]

  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF
}

{
    my $label = 'Single command, all supplied';
    my $io    = Test::IO->new();
    my $app   = App::CmdDispatch->new(
        { noop => { code => sub { }, clue => 'noop [n]', help => 'Does nothing, n times.' }, },
        { io => $io, default_commands => 'shell help' } );

    $app->help;
    is( $io->output, <<EOF, "$label: Default man supplied" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF

    $io->clear;
    $app->help( undef );
    is( $io->output, <<EOF, "$label: undef supplied to hint" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF

    $io->clear;
    $app->help( '' );
    is( $io->output, <<EOF, "$label: empty string supplied to hint" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF

    $io->clear;
    $app->help( 0 );
    is( $io->output, "Unrecognized command '0'\n", "$label: zero supplied to hint" );

    $io->clear;
    $app->help( 'noop' );
    is( $io->output, <<EOF, "$label: command supplied to hint" );

noop [n]
        Does nothing, n times.
EOF

    $io->clear;
    $app->help( 'help' );
    is( $io->output, <<EOF, "$label: help supplied to help" );

help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF

    $io->clear;
    $app->help( 'commands' );
    is( $io->output, <<EOF, "$label: 'commands' supplied to help" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF

    $io->clear;
    $app->help( 'aliases' );
    is( $io->output, '', "$label: 'aliases' supplied to help, with no aliases" );
}

{
    my $label = 'Single command, all supplied, with alias';
    my $io    = Test::IO->new();
    my $app   = App::CmdDispatch->new(
        { noop => { code => sub { }, clue => 'noop [n]', help => 'Does nothing, n times.' }, },
        { io => $io, default_commands => 'shell help', alias => { help2 => 'help help' } }
    );

    $app->help;
    is( $io->output, <<EOF, "$label: Default man supplied" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.

Aliases:
  help2 : help help
EOF

    $io->clear;
    $app->help( undef );
    is( $io->output, <<EOF, "$label: undef supplied to hint" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.

Aliases:
  help2 : help help
EOF

    $io->clear;
    $app->help( '' );
    is( $io->output, <<EOF, "$label: empty string supplied to hint" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.

Aliases:
  help2 : help help
EOF

    $io->clear;
    $app->help( 0 );
    is( $io->output, "Unrecognized command '0'\n", "$label: zero supplied to hint" );

    $io->clear;
    $app->help( 'noop' );
    is( $io->output, <<EOF, "$label: command supplied to hint" );

noop [n]
        Does nothing, n times.
EOF

    $io->clear;
    $app->help( 'help' );
    is( $io->output, <<EOF, "$label: help supplied to help" );

help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF

    $io->clear;
    $app->help( 'commands' );
    is( $io->output, <<EOF, "$label: 'commands' supplied to help" );

Commands:
  noop [n]
        Does nothing, n times.
  shell
        Execute commands as entered until quit.
  hint [command|alias]
        A list of commands and/or aliases. Limit display with the argument.
  help [command|alias]
        Display help about commands and/or aliases. Limit display with the
        argument.
EOF

    $io->clear;
    $app->help( 'aliases' );
    is( $io->output, <<EOF, "$label: help request on aliases" );

Aliases:
  help2 : help help
EOF
    $io->clear;
    $app->help( 'help2' );
    is( $io->output, <<EOF, "$label: 'aliases' supplied to help, with no aliases" );

help2 : help help
EOF
}


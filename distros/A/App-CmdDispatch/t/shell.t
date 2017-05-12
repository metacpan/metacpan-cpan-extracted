#!/usr/bin/env perl

use Test::More tests => 3;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use App::CmdDispatch;
use Test::IO;

sub shell_is ($$$)
{
    my ($input, $expected, $label) = @_;

    $input .= "\nquit\n" unless $input =~ /\bquit\b/;
    my $io = Test::IO->new( $input );
    my $app = App::CmdDispatch->new( { noop => { code=> sub {} } }, { io => $io, default_commands => 'shell help' } );

    my $actual;
    $app->shell;
    return is( $io->output, $expected, $label );
}

shell_is( "quit\n", "Enter a command or 'quit' to exit:\n> ", 'Immediately exit shell' );

shell_is( "\nquit\n", "Enter a command or 'quit' to exit:\n> > ", 'Handle blank lines' );

shell_is( "hint\nquit\n", qq{Enter a command or 'quit' to exit:
> 
Commands:
  noop
  shell                  Launch an interactive command shell.
  hint [command|alias]   Display command hints
  help [command|alias]   Display complete help
> },  'Shell to help' );

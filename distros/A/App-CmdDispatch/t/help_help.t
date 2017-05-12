#!/usr/bin/env perl

use Test::More tests => 6;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::IO;

use App::CmdDispatch;
use App::CmdDispatch::Help;

{
    my $label = 'help defaults';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper = App::CmdDispatch::Help->new( $app, \%commands );

    $helper->help;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]
        Do nothing n times
EOF
}

{
    my $label = 'help without command help';

    my %commands = ( noop => { code => sub { }, clue => 'noop [n]' }, );
    my $io       = Test::IO->new();
    my $app      = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper = App::CmdDispatch::Help->new( $app, \%commands );

    $helper->help( 'noop' );
    is $io->output, <<EOF, $label;

noop [n]
        No help for 'noop'
EOF
}

{
    my $label = 'help indent changed';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper = App::CmdDispatch::Help->new( $app, \%commands, { 'help:indent_help' => '    ' } );

    $helper->help;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]
    Do nothing n times
EOF
}

{
    my $label = 'Pre-help text';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper =
        App::CmdDispatch::Help->new( $app, \%commands,
        { 'help:pre_help' => 'This is the pre-help text.' } );

    $helper->help;
    is $io->output, <<EOF, $label;

This is the pre-help text.

Commands:
  noop [n]
        Do nothing n times
EOF
}

{
    my $label = 'Post-help text';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io } );

    # Normally this would be created by the above.
    my $helper =
        App::CmdDispatch::Help->new( $app, \%commands,
        { 'help:post_help' => 'This is the post-help text.' },
        );

    $helper->help;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]
        Do nothing n times

This is the post-help text.
EOF
}

{
    my $label = 'abstract added to hint';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]', abstract => 'Do nothing command' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper = App::CmdDispatch::Help->new( $app, \%commands );

    $helper->help;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]
        Do nothing n times
EOF
}

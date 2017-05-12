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
    my $label = 'hint defaults';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper = App::CmdDispatch::Help->new( $app, \%commands );

    $helper->hint;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]
EOF
}

{
    my $label = 'hint indent changed';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper = App::CmdDispatch::Help->new( $app, \%commands, { 'help:indent_hint' => '    ' } );

    $helper->hint;
    is $io->output, <<EOF, $label;

Commands:
    noop [n]
EOF
}

{
    my $label = 'Pre-hint text';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper =
        App::CmdDispatch::Help->new( $app, \%commands,
        { 'help:pre_hint' => 'This is the pre-hint text.' } );

    $helper->hint;
    is $io->output, <<EOF, $label;

This is the pre-hint text.

Commands:
  noop [n]
EOF
}

{
    my $label = 'Post-hint text';

    my %commands =
        ( noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]' }, );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io } );

    # Normally this would be created by the above.
    my $helper =
        App::CmdDispatch::Help->new( $app, \%commands,
        { 'help:post_hint' => 'This is the post-hint text.' },
        );

    $helper->hint;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]

This is the post-hint text.
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

    $helper->hint;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]   Do nothing command
EOF
}

{
    my $label = 'abstract with mult commands';

    my %commands = (
        noop => { code => sub { }, help => 'Do nothing n times', clue => 'noop [n]', abstract => 'Do nothing command' },
        noop2 => { code => sub { }, help => 'Do nothing a^2 + b^2 times', clue => 'noop2 [a [b]]', abstract => 'Do nothing 2 command' },
        noop3 => { code => sub { }, help => 'Do nothing a + b + c times', clue => 'noop3 a b c', abstract => 'Do nothing 3 command' },
    );
    my $io = Test::IO->new();
    my $app = App::CmdDispatch->new( \%commands, { io => $io }, );

    # Normally this would be created by the above.
    my $helper = App::CmdDispatch::Help->new( $app, \%commands );

    $helper->hint;
    is $io->output, <<EOF, $label;

Commands:
  noop [n]        Do nothing command
  noop2 [a [b]]   Do nothing 2 command
  noop3 a b c     Do nothing 3 command
EOF
}


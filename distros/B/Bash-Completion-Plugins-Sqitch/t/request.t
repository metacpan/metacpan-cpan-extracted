#!/usr/bin/env perl

use strict;
use warnings;
use aliased 'Bash::Completion::Request';
use aliased 'Bash::Completion::RequestX::Sqitch';
use Test2::Bundle::More;
use Test2::Tools::Compare qw/bag end etc hash item field is/;

# ABSTRACT: testing bash completion extended request class for Sqitch
#
# N.B., these tests use the "live" `App::Sqitch` commands, and the tests assume
# the existence of certain subcommands. As such, these will fail if some of
# them are ever removed.

subtest empty_env_vars  => \&test_empty_env_vars;
subtest candidates      => \&test_candidates;
subtest commands        => \&test_commands;
subtest command_only    => \&test_command_only;
subtest previous_arg    => \&test_previous_arg;
subtest subcommand_only => \&test_subcommand_only;

done_testing;

sub test_empty_env_vars {
    # COMP_LINE and COMP_POINT are expected to be available for
    # Bash::Completion::Request to work properly.

    # Naughty - suppressing uninitialized warnings in Bash::Completion::Request
    # when the COMP_* variables are not present.
    local $SIG{__WARN__} = sub{ };

    my $rx = Sqitch->new(request => Request->new());
    is $rx->command    => '';
    is $rx->subcommand => '';
    is $rx->args       => [];
}

sub test_candidates {
    # A command with no subcommand returns all subcommands
    my $rx = _get_rx('sqitch');
    is (
        $rx->candidates,
        bag {
            item 'deploy';
            item 'status';
            item 'verify';
            etc;
        }
    );
    is $rx->stripped_args => [], 'removed command from args';

    # A partial subcommand *still* returns all subcommands, but you wont see
    # them as they will be further filtered by bash/zsh autocomplete.
    $rx = _get_rx('sqitch ver');
    is (
        $rx->candidates,
        bag {
            item 'deploy';
            item 'status';
            item 'verify';
            etc;
        }
    );
    is $rx->stripped_args => [], 'removed partial subcommand from args';

    # A complete subcommand returns all subcommand options
    $rx = _get_rx('sqitch verify');
    is (
        $rx->candidates,
        bag {
            item '--target';
            item '--to-change';
            item '--set';
            etc;
        }
    );
    is $rx->stripped_args => [], 'removed command and subcommand';

    # A used subcommand option is removed from further subcommand candidates
    $rx = _get_rx('sqitch verify --set');
    ok !(grep {m/--set/} @{$rx->candidates});
    is $rx->stripped_args => ['--set'], 'contains subcommand args';
}

sub test_commands {
    # `sqitch_commands` is the ArrayRef of commands obtained using
    # `Module::Pluggable`.
    #
    # This test is kind of redundant as the candidates above essentially does
    # the same thing.
    my $rx = _get_rx('sqitch');
    is (
        $rx->sqitch_commands,
        bag {
            item 'add';
            item 'deploy';
            item 'upgrade';
            item 'verify';
            etc;
        }
    );
}

sub test_command_only {
    my $rx = _get_rx('sqitch');
    is $rx->command    => 'sqitch';
    is $rx->subcommand => '';
}

sub test_previous_arg {
    my $rx = _get_rx('sqitch verify');
    is $rx->previous_arg => '', 'commands are not arguments';

    $rx = _get_rx('sqitch verify --target');
    is $rx->previous_arg => '--target';
}

sub test_subcommand_only {
    my $rx = _get_rx('sqitch verify');
    is $rx->command    => 'sqitch';
    is $rx->subcommand => 'verify';
}

sub _get_rx {
    my $line = shift;

    local $ENV{COMP_POINT} = length($line) + 1;
    local $ENV{COMP_LINE}  = $line;

    return Sqitch->new(request => Request->new(), @_);
}

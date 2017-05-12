use strict;
use warnings;

use Bash::Completion::Plugin::Test;
use Module::Find qw(usesub);
use Test::More tests => 1;

my $tester = Bash::Completion::Plugin::Test->new(
    plugin => 'Bash::Completion::Plugins::dzil',
);

my @dzil_commands = usesub Dist::Zilla::App::Command;
@dzil_commands    = map { # expand aliases and get true names
    $_->command_names
} @dzil_commands;

push @dzil_commands, '--help', '-?', '-h', 'commands', 'help'; # common commands/options to App::Cmd

$tester->check_completions('dzil ^', \@dzil_commands);

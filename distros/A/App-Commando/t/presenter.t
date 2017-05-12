use strict;
use warnings;

use Test::More;

use App::Commando::Command;

BEGIN { use_ok('App::Commando::Presenter'); }

my $command = App::Commando::Command->new('foo');
my $subcommand = App::Commando::Command->new('bar', $command);
$subcommand->version('0.4.2');
$subcommand->description('Do that thing');
$subcommand->option('one', '-1', '--one', 'First option');
$subcommand->option('two', '-2', '--two', 'Second option');
$subcommand->alias('baz');

my $presenter = App::Commando::Presenter->new($subcommand);
isa_ok $presenter, 'App::Commando::Presenter', '$presenter';

is($presenter->options_presentation,
'        -1, --one          First option
        -2, --two          Second option',
'options_presentation has the expected content');

is(App::Commando::Presenter->new($command)->subcommands_presentation,
    '  bar, baz              Do that thing',
    'subcommands_presentation has the expected content');

is($presenter->command_presentation,
'foo bar 0.4.2 -- Do that thing

Usage:

  foo bar

Options:
        -1, --one          First option
        -2, --two          Second option',
'command_presentation has the expected content');

is(App::Commando::Presenter->new($command)->command_presentation,
'foo

Usage:

  foo

Subcommands:
  bar, baz              Do that thing',
'command_presentation of top-level command has the expected content');

done_testing;

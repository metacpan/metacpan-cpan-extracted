use strict;
use warnings;

use Test::Fatal;
use Test::More;

BEGIN { use_ok('App::Commando::Command'); }

my $command = App::Commando::Command->new('foo');
isa_ok $command, 'App::Commando::Command', '$command';

$command->description('Does foo');

is $command->version, undef, 'Version is undefined as expected';
is $command->version('1.2.3'), '1.2.3',
    'Version is returned correctly when being set';
is $command->version, '1.2.3', 'Version is correct after setting';

is $command->syntax, 'foo', 'Syntax is initially the same as command name';
is $command->syntax('foo [options]'), 'foo [options]',
    'Syntax is returned correctly when being set';
is $command->syntax, 'foo [options]', 'Syntax is correct after setting';

is_deeply $command->aliases, [], 'Aliases are initially empty';
$command->alias('bar');
is_deeply $command->aliases, [ 'bar' ], 'Aliases are set correctly';
is $command->names_and_aliases, 'foo, bar', 'names_and_aliases are correct';

is $command->full_name, 'foo', 'Full name is correct';

is $command->identity, 'foo 1.2.3', 'Identity is correct';

is $command->summarize, '  foo, bar              Does foo',
    'Summary is correct';

my $subcommand = App::Commando::Command->new('baz', $command);
$command->commands->{$subcommand->name} = $subcommand;

is $subcommand->full_name, 'foo baz', 'Full name of a subcommand is correct';

is $subcommand->identity, 'foo baz', 'Identity of a subcommand is correct';

is $command->default_command, undef, 'default_command is undefined as expected';
like exception { $command->default_command('bad'); },
    qr/bad couldn't be found in this command's list of commands./,
    'Exception is thrown when an unknown name is used with default_command';
is $command->default_command($subcommand->name), $subcommand,
    'default_command returns the expected Command object';

done_testing;

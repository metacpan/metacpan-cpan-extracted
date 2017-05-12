#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use_ok('Bash::Completion::Plugin')
  || die "Could not load Bash::Completion::Plugin, ";

my $plugin = Bash::Completion::Plugin->new;
ok($plugin, 'Got a plugin instance');
is(scalar($plugin->args), 0, '... no args by default');

$plugin = Bash::Completion::Plugin->new(args => [qw( a b c d )]);
ok($plugin, 'Got a plugin instance');
is(scalar($plugin->args), 4, '... args as expected');
cmp_deeply([$plugin->args], [qw( a b c d )], '... and the expected args');

cmp_deeply($plugin->should_activate, [],
  'Default should_activate() returns []');
cmp_deeply($plugin->generate_bash_setup,
  [], 'Default generate_bash_setup() returns []');


## and we are done for today
done_testing();

#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::BashCompletionTestUtils 'create_test_cmds';

use_ok('Bash::Completion') || die "Could not load Bash::Completion, ";

my $bc = Bash::Completion->new;
ok($bc,                       'Bash::Completion object ok');
ok(scalar($bc->plugin_names), '... got some plugins');

my @plugins = $bc->plugins;
for my $plugin (@plugins) {
  ok($plugin->isa('Bash::Completion::Plugin'), " ... plugin $plugin is ok");
}

## Test setup
{
  my $cmds = create_test_cmds('perldoc', 'bash-complete');
  local $ENV{PATH} = $cmds->{path};

  my $script = $bc->setup;
  ok($script, 'Got us a setup script');

  like(
    $script,
    qr{bash-complete complete BashComplete},
    '... with the expected setup command for bash-complete'
  ) if $cmds->{cmd}{'bash-complete'};
  like(
    $script,
    qr{bash-complete complete Perldoc},
    '... with the expected setup command for perldoc'
  ) if $cmds->{cmd}{'perldoc'};
  like(
    $script,
    qr{-o nospace -o default perldoc},
    '...... and it even has the correct options'
  ) if $cmds->{cmd}{'perldoc'};
}


## and we are done for today
done_testing();

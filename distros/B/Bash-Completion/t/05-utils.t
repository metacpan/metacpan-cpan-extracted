#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;
use Test::BashCompletionTestUtils 'create_test_cmds';

use_ok('Bash::Completion::Utils',
  qw(command_in_path match_perl_modules prefix_match))
  || die "Could not load Bash::Completion::Utils, ";


subtest 'command_in_path' => sub {
  my $name = join('-', $$, rand(time()), time());
  my $cmds = create_test_cmds($name);
  local $ENV{PATH} = $cmds->{path};

  ok(command_in_path($name), "command_in_path($name) works") if $cmds->{cmd}{$name};


  my $non_existing_command = "please-dont-exist-pleeease-$name";
  ok(
    !command_in_path($non_existing_command),
    "command_in_path($non_existing_command) also works"
  );
};


subtest 'match_perl_modules' => sub {
  my @pm = match_perl_modules('Bash::Comple');
  cmp_bag(\@pm, ['Completion', 'Completion::']);

  @pm = match_perl_modules('Bash::Completion');
  cmp_bag(\@pm, ['Completion', 'Completion::']);

  @pm = match_perl_modules('Bash::Completion::');
  cmp_bag(\@pm, ['Utils', 'Plugins::', 'Plugin', 'Request']);

  @pm = match_perl_modules('Bash::Completion::U');
  cmp_bag(\@pm, ['Utils']);

  @pm = match_perl_modules('Bash::Completion::Uz');
  cmp_bag(\@pm, []);

  @pm = match_perl_modules('Bash::Completion::Plugins::Ba');
  cmp_bag(\@pm, ['BashComplete']);

  @pm = match_perl_modules('Bash::Completion::Plugins::Ba');
  cmp_bag(\@pm, ['BashComplete']);

  {
    ## duplicate our @INC dirs, force it to find multiple copies
    local @INC;
    push @INC, 'lib';

    @pm = match_perl_modules('Bash::Completion::Plugins::Ba');
    cmp_bag(\@pm, ['BashComplete']);
  }

  unshift @INC, './t/tlib';
  @pm = match_perl_modules('OhPleaseLetNotBeAModuleWithThisPrefixOnCPAN');
  ok grep({/^OhPleaseLetNotBeAModuleWithThisPrefixOnCPAN::$/} @pm),
    'Let ourUniquePrefix expand to ourUniquePrefix::';

  @pm = match_perl_modules('Net:');
  cmp_deeply(\@pm, array_each(re('^(?<!Net::).')));
};


subtest 'prefix_match' => sub {
  my @mtchs =
    prefix_match('--h', '--dry', '--help', '--helicopter', '--nothing', '-h');
  cmp_bag(
    \@mtchs,
    ['--help', '--helicopter'],
    'Matched correct set of options'
  );

  @mtchs = prefix_match('a', 'never', 'always', 'perl', 'python', 'antique');
  cmp_bag(\@mtchs, ['always', 'antique'], 'Matched correct set of words');
};


## and we are done for today
done_testing();

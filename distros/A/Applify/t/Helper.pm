package t::Helper;

use strict;
use warnings;

sub is_help {
  my $script   = shift;
  my @expected = split /\n/, shift;
  my $desc     = shift;
  my @got      = split /\n/, +(run_method($script, 'print_help'))[0];

  while (@got) {
    my $exp = $expected[0] // $got[0] // '';
    Test::More::is(shift(@got), shift(@expected), "help for $desc ($exp)");
  }

  Test::More::is(int(@got),      0, 'no more help got');
  Test::More::is(int(@expected), 0, 'no more help expected');
}

sub run_method {
  my ($thing, $method, @args) = @_;
  local *STDOUT;
  local *STDERR;
  my $stdout = '';
  my $stderr = '';
  open STDOUT, '>', \$stdout;
  open STDERR, '>', \$stderr;
  local $| = 1;
  my $ret = eval { $thing->$method(@args) };
  return $stdout, $stderr, $ret;
}

sub import {
  my $caller = caller;

  eval <<"HERE" or die $@;
package $caller;
use warnings;
use strict;
use Test::More;
1;
HERE

  no strict 'refs';
  *{"$caller\::is_help"}    = \&is_help;
  *{"$caller\::run_method"} = \&run_method;
}

1;

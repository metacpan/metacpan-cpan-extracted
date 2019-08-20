package t::Helper;

sub import {
  my $caller = caller;

  eval <<"HERE" or die $@;
package $caller;
use warnings;
use strict;
use Test::More;
1;
HERE

  *{"$caller\::run_method"} = sub {
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
  };
}

1;

package PoolReset;

use strict;
use warnings;

use EV ();

# A connection is idle in the pool only once the reset of its borrow has been
# answered (karr k99, core k398): DISCARD ALL and the connect actions are on the
# wire between a call's completion and the connection's return. A test that
# counts the idle connections, or that wants the next call to run at once, waits
# for that first. until_reset runs the EV loop until no connection of the pool
# is being reset, 10 seconds at most; it answers true when none is.
#
#   PoolReset->until_reset($storage);   # an EV storage, or its pool
sub until_reset {
  my ($class, $what, $seconds) = @_;
  my $pool = $what->can('pool') ? $what->pool : $what;
  my $expired = 0;
  EV::now_update();
  my $dog = EV::timer($seconds // 10, 0, sub { $expired = 1 });
  $dog->keepalive(0);   # it must not keep a dry loop waiting
  # one turn of the loop at least: the release may still be to come
  my $turns = 0;
  until ($turns++ && !%{ $pool->{_resetting} || {} } or $expired) {
    EV::run(EV::RUN_ONCE());
  }
  return !$expired;
}

1;

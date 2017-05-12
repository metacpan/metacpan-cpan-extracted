use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}

BEGIN {
  unless (eval { require threads }) {
    print "1..0 # SKIP threads.pm not installed\n";
    exit 0;
  }
}

use threads;
use threads::shared;

our $had_error :shared;
END { $? = $had_error||0 }

use strict;
use warnings;

# load it before spawning a thread, that's the whole point
require Devel::GlobalDestruction::XS;

sub do_test {

  # just die so we don't need to deal with testcount skew
  unless ( ($_[0]||'') eq 'arg' ) {
    $had_error++;
    die "Argument passing failed!";
  }

  delete $INC{'t/01_basic.t'};
  do 't/01_basic.t';

  1;
}

threads->create('do_test', 'arg')->join
  or $had_error++;

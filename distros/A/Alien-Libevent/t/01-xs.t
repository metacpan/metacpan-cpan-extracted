use Test2::V0 -no_srand => 1;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Libevent;

alien_diag 'Alien::Libevent';

alien_ok 'Alien::Libevent';

subtest xs => sub {

  my $xs1 = <<'EOM';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <event2/event.h>

MODULE = main PACKAGE = main

const char *
event_get_version();
EOM

  xs_ok $xs1, with_subtest {
    my $version = event_get_version();
    warn "version = $version";
    like $version, qr/^([0-9]+\.)[0-9]+/;
    note "v = $version";
  };

  my $xs2 = <<'EOM';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <event.h>

MODULE = main PACKAGE = main

const char *
event_get_version();
EOM

  xs_ok $xs2, with_subtest {
    my $version = event_get_version();
    warn "version = $version";
    like $version, qr/^([0-9]+\.)[0-9]+/;
    note "v = $version";
  };


};

done_testing;

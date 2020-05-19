use Test2::V0 -no_srand => 1;
use Test::Alien 1.90;
use Test::Alien::Diag 1.90;
use Alien::libpcre;

alien_diag 'Alien::libpcre';

alien_ok 'Alien::libpcre';

subtest xs => sub {

  my $xs = <<'EOM';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <pcre.h>

MODULE = main PACKAGE = main

const char *
pcre_version();
EOM

  xs_ok $xs, with_subtest {
    my $version = pcre_version();
    warn "version = $version";
    like $version, qr/^([0-9]+\.)[0-9]+/;
    note "v = $version";
  };

};

done_testing;



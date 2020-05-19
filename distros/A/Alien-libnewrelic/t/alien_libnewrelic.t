use Test2::V0 -no_srand => 1;
use Alien::libnewrelic;
use Test::Alien;
use Test::Alien::Diag;

alien_ok 'Alien::libnewrelic';
alien_diag 'Alien::libnewrelic';

my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libnewrelic.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char* version(class)
    const char *class
  CODE:
    RETVAL = newrelic_version();
  OUTPUT:
    RETVAL
EOF

xs_ok $xs, with_subtest {
  my($nr) = @_;
  my $version = $nr->version;
  is($version, Alien::libnewrelic->version);
};

ffi_ok with_subtest {
  my($ffi) = @_;
  local $@ = '';
  my $nr = eval q{ package NR::FFI;
    $ffi->attach(['newrelic_version' => 'version'] => [] => 'string');
    'NR::FFI';
  };
  is $@, '';
  my $version = $nr->version;
  is($version, Alien::libnewrelic->version);
};

done_testing

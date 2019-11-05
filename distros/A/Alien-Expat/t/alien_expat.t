use Test2::V0 -no_srand => 1;
use Test::Alien 1.90;
use Test::Alien::Diag 1.90;
use Alien::Expat;

alien_diag 'Alien::Expat';

alien_ok 'Alien::Expat';

subtest xmlwf => sub {

  run_ok(['xmlwf', '-v'])
    ->success
    ->note;
};

my $xs_version;

subtest xs => sub {

  my $xs = <<'EOM';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <expat.h>

const char *
expat_version()
{
  static char buffer[50];
  XML_Expat_Version v;

  v = XML_ExpatVersionInfo();
  sprintf(buffer, "%d.%d.%d", v.major, v.minor, v.micro);
  return buffer;
}

MODULE = main PACKAGE = main

const char *
expat_version();
EOM

  xs_ok $xs, with_subtest {
    like $xs_version = expat_version(), qr/^([0-9]+\.){2}[0-9]$/;
    note "v = $xs_version";
  };

};

subtest ffi => sub {

  ffi_ok { symbols => ['XML_ExpatVersionInfo'], api => 1 }, with_subtest {
    my($ffi) = @_;

    do {
      package Expat::Version;
      use FFI::Platypus::Record;
      record_layout(qw(
        int major
        int minor
        int micro
      ));
    };

    $ffi->type('record(Expat::Version)' => 'XML_Expat_Version');

    my $f = $ffi->function('XML_ExpatVersionInfo' => [] => 'XML_Expat_Version');
    my $v = $f->call;
    my $ffi_version = sprintf "%d.%d.%d", $v->major, $v->minor, $v->micro;
    like $ffi_version, qr/^([0-9]+\.){2}[0-9]$/;
    note "v = $ffi_version";
    if(defined $xs_version)
    {
      is $ffi_version, $xs_version;
    }
  };

};

done_testing


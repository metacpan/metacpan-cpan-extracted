use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::hdt_cpp;

alien_diag 'Alien::hdt_cpp';
alien_ok 'Alien::hdt_cpp';

run_ok([ qw(rdf2hdt corpus/example1.ttl example1.hdt) ])
  ->success;

run_ok([ qw(hdt2rdf example1.hdt -) ])
  ->success
  ->out_like(qr{\QRDF/XML Syntax\E});

# my $xs = <<'END';
# #include "EXTERN.h"
# #include "perl.h"
# #include "XSUB.h"
# ...
#
# MODULE = main PACKAGE = main
#
# ...
# END
# xs_ok $xs, with_subtest {
#   ...
# };

# ffi_ok { symbols => [...] }, with_subtest {
#   my $ffi = shift;
#   ...
# };

done_testing;

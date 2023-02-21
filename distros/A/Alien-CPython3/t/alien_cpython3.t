use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::CPython3;

alien_diag 'Alien::CPython3';
alien_ok 'Alien::CPython3';

run_ok( [ Alien::CPython3->exe, '--version' ] )
	->success
	->out_like( qr/Python \Q@{[ Alien::CPython3->version ]}\E/ );
  # python3 -c 'import sys; print( "\n".join(sys.path) )'
#my $run = run_ok( [ Alien::CPython3->exe, '-c',  'import sys; print( "\n".join(sys.path) )' ] );
#$run->success;
  #->success
  #->out_like(qr/ ... /);

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

done_testing;

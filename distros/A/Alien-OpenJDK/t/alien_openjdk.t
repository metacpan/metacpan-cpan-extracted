use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::OpenJDK;

alien_diag 'Alien::OpenJDK';
alien_ok 'Alien::OpenJDK';

 run_ok([ qw(java -version) ])
   ->success
   ->err_like(qr/^openjdk version "([0-9\._]+(?:-\w+)?)"/m);

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

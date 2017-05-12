
use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 6, todo => [] }
BEGIN { $| = 1 }

# load your module...
use lib './';
use Class::OOorNO;

my($f) = Class::OOorNO->new();

# check to see if non-autoloaded Class::OOorNO methods are can-able ;O)
map { ok(ref(UNIVERSAL::can($f,$_)),'CODE') } qw
   (
      coerce_array
      myargs
      myself
      OOorNO
      shave_opts

      VERSION
   );

exit;

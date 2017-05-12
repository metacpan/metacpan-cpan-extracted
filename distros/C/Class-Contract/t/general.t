# This script should be runnable with 'make test'.

######################### We start with some black magic to print on failure.

BEGIN { $| = 1 }
END { print "not ok 1\n"  unless $loaded }

use lib qw( ./t );
use Magic;

use Class::Contract;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

::ok('desc'   => 'Empty Contract',
     'expect' => 1,
     'code'   => 'package Empty; use Class::Contract; contract {}');

::ok('desc'   => 'Circular Inheritence',
     'expect' => qr/Can\'t create circular reference in inheritence/,
     'code'   => <<'CODE');
package Mobius;
use Class::Contract;
contract { inherits 'Mobius' };
CODE


=pod

:#:ok('desc'   => 'Garbage Collection',
 	   'expect' => 1,
   	 'need'   => 'Empty Contract',
   	 'code'   => <<'CODE');
package Garbage;
use Class::Contract;
contract {
  attr 'name';
  dtor;
    impl { 1 };
};
{ my @o = (Garbage->new, Garbage->new, Garbage->new, Garbage->new); }
(keys %$Class::Contract::hook) ? 0 : 1;
CODE

=cut

1;
__END__


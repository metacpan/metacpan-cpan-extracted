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
# alpha, bravo, charlie, delta, echo, foxtrot, 
# golf, hotel, india, juliett, kilo, lima, mike,
# november, oscar, papa, quebec, romeo, sierra,
# tango, uniform, victor, whiskey, xray, yankee, zulu
::ok('desc'   => "ctor initialization left-most depth-first order",
     'expect' => 1,
     'code'   => <<'CODE');
package Alpha;
use Class::Contract;
contract { ctor 'new'; impl { push @::test, 'A'; $::test{'A'} = [@_] } };

package Bravo;
use Class::Contract;
contract {
  inherits 'Alpha';
  ctor 'new';
    impl { push @::test, 'B'; $::test{'B'} = [@_] }
};

package Charlie; use Class::Contract;
contract {
  inherits 'Alpha';
  ctor 'new';
    impl { push @::test, 'C'; $::test{'C'} = [@_] };
};

package Delta;
use Class::Contract;
contract { ctor 'new'; impl { push @::test, 'D'; $::test{'D'} = [@_] } };

package Echo;
use Class::Contract;
contract {
  inherits 'Delta';
  ctor 'new';
    impl { push @::test, 'E'; $::test{'E'} = [@_] };
};

package Foxtrot;
use Class::Contract;
contract {
  inherits qw( Bravo Charlie Echo );
  ctor 'new';
    impl { push @::test, 'F'; $::test{'F'} = [@_] };
};

package main;
(@::test, %::test) = ();
{ my $foo = Foxtrot->new; }
join('', @::test) eq 'ABCDEF' ? 1 : 0;
CODE

::ok('desc'   => "Can't use ctor from class with abstract methods",
     'expect' => qr/^Class \w+ has abstract methods. Can\'t create \w+ object/,
     'code'   => <<'CODE');
package Abstract; use Class::Contract; contract { abstract method 'foo' };
Abstract->new();
CODE

::ok('desc'   => "ctor initialization pre post impl done right",
     'expect' => 1,
     'code'   => <<'CODE');
#fixme
1;
CODE

1;
__END__


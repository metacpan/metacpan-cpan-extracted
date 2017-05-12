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
::ok('desc'   => "dtor initialization right-most derived-first order",
     'expect' => 1,
     'code'   => <<'CODE');
package Alpha;
use Class::Contract;
contract {
  dtor;
    impl {
		  $::order{ref(&self)||&self} .= 'A';
		  $::args{ref(&self)||&self}->{'A'} = [@_]
    };
};

package Bravo;
use Class::Contract;
contract {
  inherits 'Alpha';
    dtor;
      impl {
        $::order{ref(&self)||&self} .= 'B';
	      $::args{ref(&self)||&self}->{'B'}=[@_]
      };
};

package Charlie; use Class::Contract;
contract {
  inherits 'Alpha';
  dtor;
    impl {
      $::order{ref(&self)||&self} .= 'C';
      $::args{ref(&self)||&self}->{'C'}=[@_]
    };
};

package Delta;
use Class::Contract;
contract {
  dtor;
    impl {
      $::order{ref(&self)||&self} .= 'D';
      $::args{ref(&self)||&self}->{'D'} = [@_];
    };
};

package Echo;
use Class::Contract;
contract {
  attr 'foobar';
  inherits 'Delta';
  dtor;
    impl {
      $::order{ref(&self)||&self} .= 'E';
      $::args{ref(&self)||&self}->{'E'} = [@_]
    };
};

package Foxtrot;
use Class::Contract;
contract {
  inherits qw( Bravo Charlie Echo );
  dtor;
    impl {
      $::order{ref(&self)||&self} .= 'F';
      $::args{ref(&self)||&self}->{'F'} = [@_]
    };
};

package main;
(%::order, %::args) = ();
{ my $foo = Foxtrot->new; }
$::order{'Foxtrot'} eq 'FEDCBA' ? 1 : 0;
CODE

1;
__END__


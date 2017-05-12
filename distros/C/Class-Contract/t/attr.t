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

::ok('desc'   => "attr accessors are private to class' package namespace",
     'expect' => qr/^attribute Attribute::foo inaccessible from package main/s,
     'code'   => <<'CODE');
#=> Attributes accessors are private to the class in which they're declared
#   Calling an attribute accessor outside the namespace of the class'
#   package will raise an exception
package Attribute;
use Class::Contract;
contract { class attr 'foo' => 'SCALAR' };
${Attribute->foo} = 1;

package main;
${Attribute->foo};
CODE

::ok('desc'   => 'attr preconditions are inherited',
     'expect' => 3,
#     'need'   => 'Extended Contracts',
     'code'   => <<'CODE');
#package main;
#my $o = Baz->new();
#$o->get_name;
#delete $::pre{'attr'};
3
CODE

::ok('desc'   => 'attr cannot have implementation',
     'expect' => qr/^Attribute cannot have implementation/,
     'code'   => <<'CODE');
package Attribute::Impl;
use Class::Contract;
contract { attr 'baz'; impl {1} };
CODE

::ok('desc'   => 'exception if attempt to access obj attr with class ref',
     'expect' => qr/^Can\'t access object attr w\/ class reference/,
     'code'   => <<'CODE');
package Attribute::Obj;
use Class::Contract;
contract {
  attr 'baz';
  class method 'get_baz';
    impl { ${self->baz} };
};

package main;
Attribute::Obj->get_baz;
CODE


1;
__END__




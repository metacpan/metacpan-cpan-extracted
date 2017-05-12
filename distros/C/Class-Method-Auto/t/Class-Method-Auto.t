# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-Method-Auto.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Class::Method::Auto') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;

package Foo;

use strict;
use warnings;

sub bar($) :method {
	return shift()."::bar";
}

sub baz($) :method {
	return shift()."::baz";
}

sub nomethod($) {
	return shift()."::nomethod";
}

package Blurp;

use strict;
use warnings;

our @ISA = 'Foo';

use Class::Method::Auto 'bar';

Test::More::is(bar(), 'Blurp::bar', 'simple');

eval {
	choke();
};
Test::More::like($@, qr/^Undefined subroutine &Blurp::choke called/, 'choke');

package Moose;

use strict;
use warnings;

our @ISA = 'Foo';

use Class::Method::Auto '-attributes', qr/^bar$/;

Test::More::is(bar(), 'Moose::bar', 'bar');

eval {
	baz();
};
Test::More::like($@, qr/^Undefined subroutine &Moose::baz called/, 'regexp');

eval {
	nomethod();
};
Test::More::like($@, qr/^Undefined subroutine &Moose::nomethod called/, 'attr');



# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
BEGIN { plan tests => 22 };
use Class::Decorator;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $temp1 = Foo::Bar->new();
ok(1);

my $dec1 = Class::Decorator->new(obj=>$temp1);
ok(1);

$dec1->baz();
ok(1);

my @array;

if ($dec1->baz() == 456) {
    ok(1);
} else {
    ok(0);
}

my @array = $dec1->baz();
if ($array[0] == 1) {
    ok(1);
} else {
    ok(0);
}

if ($dec1->baz() == 456) {
    ok(1);
} else {
    ok(0);
}

my @array = $dec1->baz();
if ($array[0] == 1) {
    ok(1);
} else {
    ok(0);
}

$dec1 = Class::Decorator->new(obj=>$temp1, pre=>sub {print "testing pre\n";}, post=>sub {print "testing post\n";} );
ok(1);

if ($dec1->baz() == 456) {
    ok(1);
} else {
    ok(0);
}

my @array = $dec1->baz();
if ($array[0] == 1) {
    ok(1);
} else {
    ok(0);
}

$dec1 = Class::Decorator->new(
			      obj=>$temp1,
			      pre=>sub {print "before $Class::Decorator::METH\n"},
			      post=>sub {print "after $Class::Decorator::METH\n"}
			      );
ok(1);

if ($dec1->baz() == 456) {
    ok(1);
} else {
    ok(0);
}

my $dec2;
$dec2 = Class::Decorator->new(
			      obj=>$dec1,
			      pre=>sub {print "in\n"},
			      post=>sub {print "out\n"}
			      );
ok(1);

my @array = $dec2->baz();
if ($array[0] == 1) {
    ok(1);
} else {
    ok(0);
}

$dec2 = Class::Decorator->new(
			      obj  => $dec1,
			      methods => {
				  baz => {
				      pre  => sub{print "before baz()\n"},
				      post => sub{print "after baz()\n"}
				  }
			      }
			      );

ok(1);

my @array = $dec2->baz();
if ($array[0] == 1) {
    ok(1);
} else {
    ok(0);
}

$Foo::Bar::VERSION = 2.43;
if ($dec2->VERSION(2.43)){
    ok(1);
} else {
    ok(0);
}

if ($dec2->can("baz")){
    ok(1);
} else {
    ok(0);
}

if ($dec2->can("bim")){
    ok(0);
} else {
    ok(1);
}

if ($dec2->isa("Foo::Bar")){
    ok(1);
} else {
    ok(0);
}

if ($dec2->isa("Bar::Baz")){
    ok(0);
} else {
    ok(1);
}

package Foo::Bar;
use strict;
sub new
{
    bless {}, shift;
}

sub baz 
{
    if (wantarray) {
	return (1,2,3);
    } else {
	return 456;
    }
}

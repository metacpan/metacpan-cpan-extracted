# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test;

BEGIN { plan tests => 14 }

use Data::Properties;

# constructor
ok(my $p1 = new Data::Properties);

# constructor with invalid default properties
eval {my $bad = new Data::Properties("asdsd") };
ok($@);

# constructor with default properties
ok(my $p2 = new Data::Properties($p1));

# load properties
open FH, "t/sample.properties" or die "Can't open t/sample.properties: $!\n";
ok($p2->load(\*FH));
close FH;

# store properties
open FH2, "> t/tmpfile" or die "Can't open t/tmpfile: $!\n";
ok($p2->store(\*FH2, "MyApp Properties"));
close FH2;
unlink "t/tmpfile" or die "Can't unlink t/tmpfile: $!\n";

# get undefined property
ok(!$p2->get_property("undefined-property"));

# get defined properties written in various formats
ok($p2->get_property("Truth1"), 'Beauty');
ok($p2->get_property("Truth2"), 'Beauty');
ok($p2->get_property("Truth3"), 'Beauty');

# get property with multiple continuation lines
ok($p2->get_property("fruits"),
   'apple, banana, pear, cantaloupe, watermelon, kiwi, mango');

# get property with empty value
ok(!$p2->get_property("cheeses"));

# property names
ok(join(' ', sort $p2->property_names()),
   'Truth1 Truth2 Truth3 cheeses fruits');

# set property
ok($p2->set_property("Foo", "bar"));
ok($p2->get_property("Foo"), "bar");

exit;

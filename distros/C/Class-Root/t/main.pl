#!perl

use MyClass::Foo;
use MyClass::Bar;
use MyClass::Baz;
use MyClass::Hoo;

#print MyClass::Bar->class_schema;
#print MyClass::Bar->class_dump;

my $foo1 = MyClass::Foo->new(favorite_color => "green");
my $bar1 = MyClass::Bar->new(favorite_color => "blue");
my $bar2 = MyClass::Bar->new(favorite_color => "blue2");
my $baz1 = MyClass::Baz->new(favorite_color => "red");
my $baz2 = MyClass::Baz->new(favorite_color => "red2");
my $baz3 = MyClass::Baz->new(favorite_color => "red3");
my $hoo1 = MyClass::Hoo->new(favorite_color => "white");
my $hoo2 = MyClass::Hoo->new(favorite_color => "white2");
my $hoo3 = MyClass::Hoo->new(favorite_color => "white3");
my $hoo4 = MyClass::Hoo->new(favorite_color => "white4");

print "foo1->population: ", $foo1->population, "\n";
print "bar1->population: ", $bar1->population, "\n";
print "baz1->population: ", $baz1->population, "\n";
print "hoo1->population: ", $hoo1->population, "\n";

print "hoo1->foo_population: ", $hoo1->foo_population, "\n";
print "hoo1->bar_population: ", $hoo1->bar_population, "\n";
print "hoo1->baz_population: ", $hoo1->baz_population, "\n";
print "hoo1->get_bars_secret: ", $hoo1->get_bars_secret, "\n";
print "hoo1->get_bazs_secret: ", $hoo1->get_bazs_secret, "\n";

print "hoo1->id: ", $hoo1->id, "\n";
print "hoo2->id: ", $hoo2->id, "\n";
print "hoo3->id: ", $hoo3->id, "\n";
print "hoo4->id: ", $hoo4->id, "\n";

print "hoo3->class_schema:\n", $hoo3->class_schema;
print "hoo3->class_dump:\n", $hoo3->class_dump;
print "hoo3->instance_dump:\n", $hoo3->instance_dump;





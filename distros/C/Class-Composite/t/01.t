use strict;
use warnings;
use Data::Dumper;

use lib	qw( ./lib ../lib );

use Test::Simple  tests => 24;

use Class::Composite::Container;
use Class::Composite::Element;


ok( my $container = Class::Composite::Container->new(), "Container created");
ok( my $element1  = Class::Composite::Element->new(), "element created");
my $element2  = Class::Composite::Element->new();

ok( $container->addElement($element1, $element2), "Elements added");
ok( $container->nOfElements == 2, "2 elements found");

ok( $container->removeElement(1) eq $element2, "removed 2d element");
ok( $container->nOfElements == 1, "Found 1 element");
ok( ! $container->addElement( 123 ), "Could not add a non Class::Composite");
ok( $container->addElement( undef ), "Could add undef");
ok( $container->nOfElements == 2, "found 2 elements");

ok( $container->elements([$element1, $element2, $element1]), "replaced elements");
ok( $container->getElements->[1] eq $element2, "2nd element looks good");
ok( $container->nextElement eq $element1, "1st element looks good");
ok( $container->nextElement eq $element2, "2nd element looks good");
$container->nextElement;
ok( ! $container->nextElement, "No 4th element");
ok( $container->setPointer(1) == 4, "Pointer set");
ok( $container->getElement() eq $element2, "Element 2 found");

my $container2 = Class::Composite::Container->new();
$container2->addElement($element2, $element1);
ok( $container->addElementFlat($container2), "Adding flat a new container");
ok( $container->nOfElements == 5, "5 elements found");
ok( $container->addElement($container2), "Added container in container");
ok( scalar @{$container->getLeaves} == 7, "7 leaves");
ok( scalar @{$container->getElements} == 6, "6 elements");
ok( scalar @{$container->getAll} == 8, "8 items");

ok( $container->removeAll(), "removed all");
ok( $container->nOfElements == 0, "No elements left");
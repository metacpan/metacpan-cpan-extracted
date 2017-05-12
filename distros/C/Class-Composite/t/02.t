use strict;
use warnings;
use Data::Dumper;

use lib qw( ./lib ../lib ./t );

use Test::Simple  tests => 4;

use Container;
use Element;

ok( my $container = Container->new(), "container created");
ok( my $element1  = Element->new(), "element created");
my $element2  = Element->new();
$container->addElement( $element1, $element2 );
ok( $container->bar == 2, "2 elements in container");
ok( ! defined $element1->bar, "undef elements in element1");
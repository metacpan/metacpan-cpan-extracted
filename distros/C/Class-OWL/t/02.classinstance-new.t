use Test::More tests=>2;

use_ok('Class::OWL',debug=>0,package=>'OM2','url'=>'http://www.openmetadir.org/om2/om2-1.owl');
my $m1 = OM2::Message->new('http://www.su.se/om2#dummy1',mid=>111);
warn $m1->_rdf->serialize;
is($m1->mid,111);

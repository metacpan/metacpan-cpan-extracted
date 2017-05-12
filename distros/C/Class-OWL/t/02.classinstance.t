use Test::More tests=>2;

use_ok('Class::OWL',debug=>0,package=>'OM2','url'=>'http://www.openmetadir.org/om2/om2-1.owl');
my $m1 = OM2::Message->meta->new_instance('http://www.su.se/om2#dummy1');
$m1->mid('111');

my $rdf = Class::OWL->to_rdf($m1);
my $xml = $rdf->serialize();
my $m2 = Class::OWL->from_rdf('http://www.su.se/om2#dummy1',$xml);
diag $m2->_rdf->serialize(format=>'ntriples');

is($m2->mid,$m1->mid);

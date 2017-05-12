use Test::More tests=>1;

use_ok('Class::OWL',package=>'OM2','url'=>'http://www.openmetadir.org/om2/om2-1.owl');
my $m1 = OM2::Message->meta->new_instance('http://www.su.se/om2#dummy1');
$m1->mid(undef);
$m1->body();

diag $m1->_rdf->serialize();

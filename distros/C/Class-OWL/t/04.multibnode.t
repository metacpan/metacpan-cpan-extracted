use Test::More tests=>1;

use_ok('Class::OWL',package=>'OM2','url'=>'http://www.openmetadir.org/om2/prim-3.owl');
my $p1 = OM2::User->meta->new_instance();
my $p2 = OM2::User->meta->new_instance($p1->_model); 

diag $p1->_model->serialize();
diag $p1->_rdf->serialize(format=>'ntriples');
diag $p2->_rdf->serialize(format=>'ntriples');

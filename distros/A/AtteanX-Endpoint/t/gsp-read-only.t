use Test::More;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use Attean::RDF;
use AtteanX::Endpoint;
use Test::WWW::Mechanize::PSGI;
use Test::AtteanX::Endpoint;

my $mech_ro	= Test::AtteanX::Endpoint->mech_for_nquads(update => 0, <<"END");
_:b <http://example.org/num> "0" .
_:b <http://example.org/num> "1" <http://example.org/graph1> .
_:b <http://example.org/num> "2" <http://example.org/graph2> .
END

subtest 'DELETE default graph (read-only)' => sub {
	$mech_ro->delete('/gsp?default');
	is($mech_ro->status, 405);
};

subtest 'PUT named graph (read-only)' => sub {
	$mech_ro->put('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph_new', 'Content-Type' => 'text/turtle', content => '<s> <p> "first POST" .');
	is($mech_ro->status, 405);
};

subtest 'POST named graph (read-only)' => sub {
	$mech_ro->post('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph_new', 'Content-Type' => 'text/turtle', content => '<s> <p> "first POST" .');
	is($mech_ro->status, 405);
};

done_testing();

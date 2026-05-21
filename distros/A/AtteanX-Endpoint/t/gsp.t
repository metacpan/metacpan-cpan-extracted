use Test::More;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use Attean::RDF;
use AtteanX::Endpoint;
use Test::WWW::Mechanize::PSGI;

sub mech_for_nquads {
	my $allow_update	= shift;
	my $nquads			= shift;
	my $config			= {
		endpoint	=> {
			service_description => {},
			html				=> {},
			load_data			=> 0,
			update				=> $allow_update,
		}
	};

	my $store	= Attean->get_store('Memory')->new();
	my $model	= Attean::MutableQuadModel->new( store => $store );
	my $graph	= iri('http://example.org/graph');
	$model->load_triples('nquads', $graph => $nquads);


	my $end		= AtteanX::Endpoint->new( model => $model, conf => $config, graph => $graph );
	my $app	= sub {
		my $env 	= shift;
		my $req 	= Plack::Request->new($env);
		my $resp	= $end->run( $req );
		return $resp->finalize;
	};

	my $mech	= Test::WWW::Mechanize::PSGI->new(app => $app);
	return $mech;
}


my $mech	= mech_for_nquads(1, <<"END");
_:b <num> "000" .
_:b <num> "123" <http://example.org/graph1> .
_:b <num> "787" <http://example.org/graph2> .
<doc> <name> "My Document" <http://example.org/graph3> .
END

subtest 'HEAD default graph' => sub {
	$mech->head_ok('/gsp?default', {Accept => 'text/turtle'});
	ok( $mech->success );
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	is(length($mech->content(raw => 1)), 0, 'empty body');
};

subtest 'GET default graph' => sub {
	$mech->get('/gsp?default', Accept => 'text/turtle');
	ok( $mech->success );
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	$mech->content_like(qr#"000"#);
	$mech->content_unlike(qr#"123"#);
	$mech->content_unlike(qr#"My Document"#);
};

subtest 'GET named graph' => sub {
	$mech->get('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph2', Accept => 'text/turtle');
	ok( $mech->success );
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	$mech->content_like(qr#"787"#);
	$mech->content_unlike(qr#"123"#);
	$mech->content_unlike(qr#"My Document"#);
};

subtest 'PUT named graph' => sub {
	$mech->put('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph2', 'Content-Type' => 'text/turtle', content => '<s> <p> "new content" .');
	ok( $mech->success );
	$mech->get('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph2', Accept => 'text/turtle');
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	$mech->content_like(qr/new content/);
	$mech->content_unlike(qr#"787"#);
	$mech->content_unlike(qr#"123"#);
	$mech->content_unlike(qr#"My Document"#);
};

subtest 'PUT default graph' => sub {
	$mech->put('/gsp?default', 'Content-Type' => 'text/turtle', content => '<s> <p> "new default content" .');
	ok( $mech->success );
	$mech->get('/gsp?default', Accept => 'text/turtle');
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	$mech->content_like(qr/new default content/);
	$mech->content_unlike(qr#"000"#);
	$mech->content_unlike(qr#"123"#);
	$mech->content_unlike(qr#"My Document"#);
};

subtest 'DELETE default graph' => sub {
	$mech->get('/gsp?default', Accept => 'text/turtle');
	ok( $mech->success );
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	$mech->content_like(qr/s>/);
	$mech->delete('/gsp?default');
	ok( $mech->success );
	$mech->get_ok('/gsp?default', {Accept => 'text/turtle'});
	$mech->content_unlike(qr/s>/);
};

subtest 'POST named graph' => sub {
	$mech->delete('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph_new');
	$mech->post('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph_new', 'Content-Type' => 'text/turtle', content => '<s> <p> "first POST" .');
	ok( $mech->success );
	$mech->post('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph_new', 'Content-Type' => 'text/turtle', content => '<s> <p> "second POST" .');
	ok( $mech->success );

	$mech->get_ok('/gsp?graph=http%3A%2F%2Fexample.org%2Fgraph_new', {Accept => 'application/n-triples', 'Accept-Encoding' => ''});
	is( $mech->ct, 'application/n-triples', 'Is application/n-triples' );
	$mech->content_like(qr/first POST/);
	$mech->content_like(qr/second POST/);
};

subtest 'PUT named graph (RDF/XML)' => sub {
	$mech->delete('/gsp?graph=http%3A%2F%2Fexample.org%2Frdfxml');
	$mech->put('/gsp?graph=http%3A%2F%2Fexample.org%2Frdfxml', 'Content-Type' => 'application/rdf+xml', content => <<"END");
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:eg="http://example.org/"
         xml:base="http://example.org/dir/file">
  <rdf:Description rdf:ID="frag" eg:value="rdf/xml value" />
</rdf:RDF>
END
	ok( $mech->success );

	$mech->get_ok('/gsp?graph=http%3A%2F%2Fexample.org%2Frdfxml', {Accept => 'application/n-triples', 'Accept-Encoding' => ''});
	is( $mech->ct, 'application/n-triples', 'Is application/n-triples' );
	$mech->content_like(qr#http://example.org/value#);
	$mech->content_like(qr#rdf/xml value#);
};

done_testing();

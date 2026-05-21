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


my $mech_ro	= mech_for_nquads(0, <<"END");
_:b <num> "0" .
_:b <num> "1" <http://example.org/graph1> .
_:b <num> "2" <http://example.org/graph2> .
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

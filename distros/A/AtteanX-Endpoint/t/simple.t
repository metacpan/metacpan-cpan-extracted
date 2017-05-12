use Test::More;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use Attean::RDF;
use AtteanX::Endpoint;
use Test::WWW::Mechanize::PSGI;

sub mech_for_nquads {
	my $nquads	= shift;
	my $config	= {
		endpoint	=> {
			service_description => {
				named_graphs	=> 1,
				default			=> 1,
			},
			html				=> {
				embed_images	=> 1,
				image_width		=> 200,
				resource_links	=> 1,
			},
			load_data	=> 0,
			update		=> 0,
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


my $mech	= mech_for_nquads(<<"END");
_:b <num> "123" <http://example.org/graph> .
_:b <num> "787" <http://example.org/graph> .
<doc> <name> "My Document" <http://example.org/graph2> .
END

subtest 'POST query for default graph' => sub {
	$mech->post('/sparql', Accept => 'application/sparql-results+xml', Content => ['query' => 'SELECT * WHERE { ?s ?p ?o }']);
	is( $mech->ct, 'application/sparql-results+xml', 'Is application/sparql-results+xml' );
	$mech->content_unlike(qr#My Document#);
	$mech->content_like(qr#num#);
	$mech->content_like(qr#787#);
	$mech->content_like(qr#123#);
};

subtest 'POST query for named graph' => sub {
	$mech->post('/sparql', Accept => 'application/sparql-results+xml', Content => ['query' => 'SELECT * WHERE { GRAPH ?g { ?s ?p ?o } }']);
	is( $mech->ct, 'application/sparql-results+xml', 'Is application/sparql-results+xml' );
	$mech->content_like(qr#My Document#);
	$mech->content_unlike(qr#num#);
};

done_testing();

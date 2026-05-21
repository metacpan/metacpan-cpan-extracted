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
			gsp_path			=> '/custom/gsp_path',
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

subtest 'HEAD default graph (default endpoint)' => sub {
	$mech->head('/gsp?default', Accept => 'text/turtle');
	cmp_ok($mech->status, '>=', 400, 'response is error');
	cmp_ok($mech->status, '<', 500, 'response is client error');
};

subtest 'HEAD default graph (custom endpoint)' => sub {
	$mech->head('/custom/gsp_path?default', Accept => 'text/turtle');
	ok( $mech->success );
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	is(length($mech->content(raw => 1)), 0, 'empty body');
};

subtest 'GET default graph (custom endpoint)' => sub {
	$mech->get('/custom/gsp_path?default', Accept => 'text/turtle');
	ok( $mech->success );
	is( $mech->ct, 'text/turtle', 'Is text/turtle' );
	$mech->content_like(qr#"000"#);
	$mech->content_unlike(qr#"123"#);
	$mech->content_unlike(qr#"My Document"#);
};

done_testing();

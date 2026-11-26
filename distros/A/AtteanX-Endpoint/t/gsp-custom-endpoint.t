use Test::More;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use Attean::RDF;
use AtteanX::Endpoint;
use Test::WWW::Mechanize::PSGI;
use Test::AtteanX::Endpoint;

my $mech	= Test::AtteanX::Endpoint->mech_for_nquads(update => 1, gsp_path => '/custom/gsp_path', <<"END");
_:b <http://example.org/num> "000" .
_:b <http://example.org/num> "123" <http://example.org/graph1> .
_:b <http://example.org/num> "787" <http://example.org/graph2> .
<http://example.org/doc> <http://example.org/name> "My Document" <http://example.org/graph3> .
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

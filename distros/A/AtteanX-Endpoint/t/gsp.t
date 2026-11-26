use Test::More;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';

use Encode qw(encode);
use URI::Escape qw(uri_escape);

use Attean::RDF;
use AtteanX::Endpoint;
use Test::WWW::Mechanize::PSGI;
use Test::AtteanX::Endpoint;

my $mech	= Test::AtteanX::Endpoint->mech_for_nquads(update => 1, <<"END");
_:b <http://example.org/num> "000" .
_:b <http://example.org/num> "123" <http://example.org/graph1> .
_:b <http://example.org/num> "787" <http://example.org/graph2> .
<http://example.org/doc> <http://example.org/name> "My Document" <http://example.org/graph3> .
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

# Returns the character length of the single literal object in $graph, as seen
# by the query engine. This distinguishes correctly-decoded UTF-8 content from
# mojibake, which a byte-level round-trip through the GSP endpoint cannot do
# (the serializer writes latin-1 characters back out as the same bytes).
sub literal_length {
	my $graph	= shift;
	my $sparql	= "SELECT (STRLEN(?o) AS ?len) WHERE { GRAPH <$graph> { ?s ?p ?o } }";
	$mech->get('/sparql?query=' . uri_escape($sparql), Accept => 'application/sparql-results+json', 'Accept-Encoding' => '');
	return unless ($mech->success);
	my $parser	= Attean->get_parser('SPARQLJSON')->new();
	my ($res)	= $parser->parse_list_from_bytes($mech->content);
	my $len		= $res->value('len')->value;
	return $len;
}

subtest 'PUT named graph (RDF/XML, non-ASCII)' => sub {
	my $graph	= 'http://example.org/rdfxml-utf8';
	my $value	= encode('UTF-8', "caf\x{e9} \x{263a}"); # "café" + U+263A WHITE SMILING FACE
	$mech->put('/gsp?graph=' . uri_escape($graph), 'Content-Type' => 'application/rdf+xml', content => <<"END");
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:eg="http://example.org/">
  <rdf:Description rdf:about="http://example.org/s" eg:value="$value" />
</rdf:RDF>
END
	ok( $mech->success, 'RDF/XML body with non-ASCII content accepted' );
	is( literal_length($graph), 6, 'RDF/XML body decoded as UTF-8' );
};

subtest 'POST multipart upload (RDF/XML, non-ASCII)' => sub {
	my $graph	= 'http://example.org/upload-rdfxml';
	my $value	= encode('UTF-8', "caf\x{e9} \x{263a}"); # "café" + U+263A WHITE SMILING FACE
	my $rdfxml	= <<"END";
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:eg="http://example.org/">
  <rdf:Description rdf:about="http://example.org/s" eg:value="$value" />
</rdf:RDF>
END
	$mech->post('/gsp?graph=' . uri_escape($graph),
		Content_Type	=> 'form-data',
		Content			=> [ data => [ undef, 'data.rdf', Content_Type => 'application/rdf+xml', Content => $rdfxml ] ],
	);
	ok( $mech->success, 'RDF/XML upload with non-ASCII content accepted' );
	is( literal_length($graph), 6, 'RDF/XML upload decoded as UTF-8' );
};

subtest 'POST multipart upload (Turtle, non-ASCII)' => sub {
	my $graph	= 'http://example.org/upload-turtle';
	my $turtle	= encode('UTF-8', qq[<http://example.org/s> <http://example.org/t> "na\x{ef}ve \x{263a}" .\n]); # "naïve" + U+263A WHITE SMILING FACE
	$mech->post('/gsp?graph=' . uri_escape($graph),
		Content_Type	=> 'form-data',
		Content			=> [ data => [ undef, 'data.ttl', Content_Type => 'text/turtle', Content => $turtle ] ],
	);
	ok( $mech->success, 'Turtle upload with non-ASCII content accepted' );
	is( literal_length($graph), 7, 'Turtle upload decoded as UTF-8' );
};

done_testing();

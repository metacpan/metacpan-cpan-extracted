use v5.14;
use warnings;
use autodie;
use Test::Modern;
use Test::Exception;
use utf8;

use Attean;
use Attean::RDF;

subtest 'parser construction and metadata' => sub {
	my $parser	= Attean->get_parser('JSONLD')->new();
	isa_ok( $parser, 'AtteanX::Parser::JSONLD' );
	is($parser->canonical_media_type, 'application/ld+json', 'canonical_media_type');
	my %extensions	= map { $_ => 1 } @{ $parser->file_extensions };
	ok(exists $extensions{'jsonld'}, 'file_extensions');
};

subtest 'empty JSON object' => sub {
	my $parser	= Attean->get_parser('JSONLD')->new();
	my @list	= $parser->parse_list_from_bytes('{}');
	is(scalar(@list), 0);
};

subtest 'simple triple parse with namespaces' => sub {
	my $map		= URI::NamespaceMap->new();
	my $parser	= Attean->get_parser('JSONLD')->new( namespaces => $map );
	my $store		= Attean->get_store('Memory')->new();
	my $content	= <<'END';
{
  "@context": {"foaf": "http://xmlns.com/foaf/0.1/"},
  "@id": "http://greggkellogg.net/foaf#me",
  "foaf:name": "Gregg Kellogg"
}
END
	my @list	= $parser->parse_list_from_bytes($content);
	is(scalar(@list), 1);
	my ($t)		= @list;
	does_ok($t, 'Attean::API::Triple');
	is($t->as_string, '<http://greggkellogg.net/foaf#me> <http://xmlns.com/foaf/0.1/name> "Gregg Kellogg" .');
};

done_testing();

use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More;
use Catmandu -all;
use Catmandu::RDF;
use RDF::Trine;
use Encode;
use HTTP::Response;
use Test::LWP::UserAgent;
use utf8;

RDF::Trine->default_useragent(user_agent());

{
    note("importing turtle");
    my $importer = importer('RDF', url => 'http://www.w3.org/TR/examples/example1.ttl', type => 'turtle');
    my $aref = $importer->first;
    is $aref->{'http://www.w3.org/TR/rdf-syntax-grammar'}->{dc_title},
       'RDF/XML Syntax Specification (Revised)@', 'Import from URL';
} 

{
    note("importing rdf/xml");
    my $importer = importer('RDF', url => 'http://www.w3.org/TR/examples/example2.rdf', type => 'xml');
    my $aref = $importer->first;
    is $aref->{'http://www.w3.org/TR/rdf-syntax-grammar'}->{dc_title},
       'RDF/XML Syntax Specification (Revised)@', 'Import from URL';
}

{
    note("importing NTriples");
    my $importer = importer('RDF', url => 'http://www.w3.org/TR/examples/example3.nt', type => 'NTriples');
    my $aref = $importer->first;
    is $aref->{'http://www.w3.org/TR/rdf-syntax-grammar'}->{dc_title},
       'RDF/XML Syntax Specification (Revised)@', 'Import from URL';
} 

done_testing;

sub user_agent {
    my $ua = Test::LWP::UserAgent->new( agent => "Catmandu::RDF/$Catmandu::RDF::VERSION" );

    my $example =<<EOF;
\@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
\@prefix dc: <http://purl.org/dc/elements/1.1/> .
\@prefix ex: <http://example.org/stuff/1.0/> .

<http://www.w3.org/TR/rdf-syntax-grammar>
  dc:title "RDF/XML Syntax Specification (Revised)" ;
  ex:editor [
    ex:fullname "Dave Beckett";
    ex:homePage <http://purl.org/net/dajobe/>
  ] .
EOF
    add_response(
        $ua,
        'http://www.w3.org/TR/examples/example1.ttl',
        'text/turtle; charset=utf-8',
        $example
    );

    my $example2 =<<EOF;
<?xml version="1.0"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:ex="http://example.org/stuff/1.0/">

  <rdf:Description rdf:about="http://www.w3.org/TR/rdf-syntax-grammar"
             dc:title="RDF/XML Syntax Specification (Revised)">
    <ex:editor>
      <rdf:Description ex:fullName="Dave Beckett">
        <ex:homePage rdf:resource="http://purl.org/net/dajobe/" />
      </rdf:Description>
    </ex:editor>
  </rdf:Description>

</rdf:RDF>
EOF

    add_response(
        $ua,
        'http://www.w3.org/TR/examples/example2.rdf',
        'application/rdf+xml; charset=utf-8',
        $example2
    );

    my $example3 =<<EOF;
<http://www.w3.org/TR/rdf-syntax-grammar> <http://purl.org/dc/elements/1.1/title> "RDF/XML Syntax Specification (Revised)".
<http://www.w3.org/TR/rdf-syntax-grammar> <http://example.org/stuff/1.0/editor> _:b1 .
_:b1 <http://example.org/stuff/1.0/fullName> "Dave Beckett" .
_:b1 <http://example.org/stuff/1.0/homePage> <http://purl.org/net/dajobe/> .
EOF

    add_response(
        $ua,
        'http://www.w3.org/TR/examples/example3.nt',
        'text/plain; charset=utf-8',
        $example3
    );
   
    return $ua;
}

sub add_response {
    my $ua           = shift;
    my $url          = shift;
    my $content_type = shift;
    my $content      = shift;

    $ua->map_response(
        qr{^\Q$url\E$},
        HTTP::Response->new(
            '200',
            'OK',
            ['Content-Type' => $content_type ],
            Encode::encode_utf8($content)
        )    
    );
}

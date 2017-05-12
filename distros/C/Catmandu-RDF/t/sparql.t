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
    note("importing from sparql endpoint");
    my $sparql   =<<END;
PREFIX dc: <http://purl.org/dc/elements/1.1/>
SELECT * WHERE { ?book dc:title ?title . }
END

    my $url = 'http://sparql.org/books/sparql';

    my $importer = importer('RDF', url => $url, sparql => $sparql);
    is $importer->sparql, $sparql, "SPARQL";

    $importer = importer('RDF', url => $url, 
        sparql => "SELECT * WHERE { ?book dc:title ?title . }\n");
    is $importer->sparql, $sparql, "SPARQL, PREFIX added";

    my $ref = $importer->first;
    ok $ref->{title} , 'got a title';
    ok $ref->{book} , 'got a book';
}

{
     note("importing from ldf endpoint");
     my $sparql =<<EOF;
SELECT ?film WHERE { ?film dct:subject <http://dbpedia.org/resource/Category:French_films> }
EOF
     my $url = 'http://fragments.dbpedia.org/2014/en';

     my $importer = importer('RDF', url => $url, sparql => $sparql);

     my $ref = $importer->first;
     ok $ref->{film} , 'got a film';
}

{
     note("importing from ldf endpoint (utf8)");
     my $url = 'http://fragments.dbpedia.org/2014/en';

     my $importer = importer('RDF', url => $url, sparql => 't/query.sparql');

     my $ref = $importer->first;
     ok $ref->{name} , 'got a name (file sparql)';
     like $ref->{name} , qr/François Schuiten/ , 'utf8 test';
}

done_testing;

sub user_agent {
    my $ua = Test::LWP::UserAgent->new( agent => "Catmandu::RDF/${Catmandu::RDF::VERSION}" );

    my $example =<<EOF;
<?xml version="1.0"?>
<sparql xmlns="http://www.w3.org/2005/sparql-results#">
  <head>
    <variable name="book"/>
    <variable name="title"/>
  </head>
  <results>
    <result>
      <binding name="book">
        <uri>http://example.org/book/book7</uri>
      </binding>
      <binding name="title">
        <literal>Harry Potter and the Deathly Hallows</literal>
      </binding>
    </result>
  </results>
</sparql>
EOF
    add_response(
        $ua,
        'http://sparql.org/books/sparql?query=PREFIX%20dc%3A%20%3Chttp%3A%2F%2Fpurl.org%2Fdc%2Felements%2F1.1%2F%3E%0ASELECT%20%2A%20WHERE%20%7B%20%3Fbook%20dc%3Atitle%20%3Ftitle%20.%20%7D%0A',
        'application/sparql-results+xml; charset=utf-8',
        $example
    );

    my $example2 =<<EOF;
\@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
\@prefix xsd: <http://www.w3.org/2001/XMLSchema#>.
\@prefix dc: <http://purl.org/dc/terms/>.
\@prefix foaf: <http://xmlns.com/foaf/0.1/>.
\@prefix dbpedia: <http://dbpedia.org/resource/>.
\@prefix dbpedia-owl: <http://dbpedia.org/ontology/>.
\@prefix dbpprop: <http://dbpedia.org/property/>.
\@prefix hydra: <http://www.w3.org/ns/hydra/core#>.
\@prefix void: <http://rdfs.org/ns/void#>.

<http://fragments.dbpedia.org/2014/en/#dataset> hydra:member <http://fragments.dbpedia.org/2014/en#dataset>.
<http://fragments.dbpedia.org/2014/en#dataset> a void:Dataset, hydra:Collection;
    void:subset <http://fragments.dbpedia.org/2014/en>;
    void:uriLookupEndpoint "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}";
    hydra:search _:triplePattern.
_:triplePattern hydra:template "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}";
    hydra:mapping _:subject, _:predicate, _:object.
_:subject hydra:variable "subject";
    hydra:property rdf:subject.
_:predicate hydra:variable "predicate";
    hydra:property rdf:predicate.
_:object hydra:variable "object";
    hydra:property rdf:object.
<http://example.org/uri3> <http://example.org/predicate3> <http://example.org/uri3>, <http://example.org/uri4>, <http://example.org/uri5>.
<http://example.org/uri1> <http://example.org/predicate1> "literal1", "literalA", "literalB", "literalC";
    <http://example.org/predicate2> <http://example.org/uri3>, <http://example.org/uriA3>.
<http://example.org/uri2> <http://example.org/predicate1> "literal2".
<http://fragments.dbpedia.org/2014/en> void:subset <http://fragments.dbpedia.org/2014/en>;
    a hydra:Collection, hydra:PagedCollection;
    dc:title "Linked Data Fragment of Test"\@en;
    dc:description "Triple Pattern Fragment of the 'Test' dataset containing triples matching the pattern { ?s ?p ?o }."\@en;
    dc:source <http://fragments.dbpedia.org/2014/en#dataset>;
    hydra:totalItems "10"^^xsd:integer;
    void:triples "10"^^xsd:integer;
    hydra:itemsPerPage "100"^^xsd:integer;
    hydra:firstPage <http://fragments.dbpedia.org/2014/en?page=1>.
EOF
    add_response(
        $ua,
        'http://fragments.dbpedia.org/2014/en',
        'text/turtle; charset=utf-8',
        $example2
    );

    my $example2b =<<EOF;
\@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
\@prefix owl: <http://www.w3.org/2002/07/owl#>.
\@prefix skos: <http://www.w3.org/2004/02/skos/core#>.
\@prefix xsd: <http://www.w3.org/2001/XMLSchema#>.
\@prefix dc: <http://purl.org/dc/terms/>.
\@prefix dcterms: <http://purl.org/dc/terms/>.
\@prefix dc11: <http://purl.org/dc/elements/1.1/>.
\@prefix foaf: <http://xmlns.com/foaf/0.1/>.
\@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>.
\@prefix dbpedia: <http://dbpedia.org/resource/>.
\@prefix dbpedia-owl: <http://dbpedia.org/ontology/>.
\@prefix dbpprop: <http://dbpedia.org/property/>.
\@prefix hydra: <http://www.w3.org/ns/hydra/core#>.
\@prefix void: <http://rdfs.org/ns/void#>.

<http://fragments.dbpedia.org/#dataset> hydra:member <http://fragments.dbpedia.org/2014/en#dataset>.
<http://fragments.dbpedia.org/2014/en#dataset> a void:Dataset, hydra:Collection;
    void:subset <http://fragments.dbpedia.org/2014/en?predicate=http://purl.org/dc/terms/subject&object=http://dbpedia.org/resource/Category:French_films>, <http://fragments.dbpedia.org/2014/en?predicate=http%3A%2F%2Fpurl.org%2Fdc%2Fterms%2Fsubject&object=http%3A%2F%2Fdbpedia.org%2Fresource%2FCategory%3AFrench_films>;
    void:uriLookupEndpoint "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}";
    hydra:search _:triplePattern.
_:triplePattern hydra:template "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}";
    hydra:mapping _:subject, _:predicate, _:object.
_:subject hydra:variable "subject";
    hydra:property rdf:subject.
_:predicate hydra:variable "predicate";
    hydra:property rdf:predicate.
_:object hydra:variable "object";
    hydra:property rdf:object.
<http://dbpedia.org/resource/...Sans_laisser_d'adresse> dcterms:subject <http://dbpedia.org/resource/Category:French_films>.
<http://fragments.dbpedia.org/2014/en?predicate=http%3A%2F%2Fpurl.org%2Fdc%2Fterms%2Fsubject&object=http%3A%2F%2Fdbpedia.org%2Fresource%2FCategory%3AFrench_films> void:subset <http://fragments.dbpedia.org/2014/en?predicate=http://purl.org/dc/terms/subject&object=http://dbpedia.org/resource/Category:French_films>.
<http://fragments.dbpedia.org/2014/en?predicate=http://purl.org/dc/terms/subject&object=http://dbpedia.org/resource/Category:French_films> a hydra:Collection, hydra:PagedCollection;
    dcterms:title "Linked Data Fragment of DBpedia 2014"\@en;
    dcterms:description "Triple Pattern Fragment of the 'DBpedia 2014' dataset containing triples matching the pattern { ?s <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:French_films>  }."\@en;
    dcterms:source <http://fragments.dbpedia.org/2014/en#dataset>;
    hydra:totalItems "1"^^xsd:integer;
    void:triples "1"^^xsd:integer;
    hydra:itemsPerPage "100"^^xsd:integer;
    hydra:firstPage <http://fragments.dbpedia.org/2014/en?predicate=http%3A%2F%2Fpurl.org%2Fdc%2Fterms%2Fsubject&object=http%3A%2F%2Fdbpedia.org%2Fresource%2FCategory%3AFrench_films&page=1>;
    hydra:nextPage <http://fragments.dbpedia.org/2014/en?predicate=http%3A%2F%2Fpurl.org%2Fdc%2Fterms%2Fsubject&object=http%3A%2F%2Fdbpedia.org%2Fresource%2FCategory%3AFrench_films&page=2>.
EOF
    add_response(
        $ua,
        'http://fragments.dbpedia.org/2014/en?predicate=http%3A%2F%2Fpurl.org%2Fdc%2Fterms%2Fsubject&object=http%3A%2F%2Fdbpedia.org%2Fresource%2FCategory%3AFrench_films',
        'text/turtle; charset=utf-8',
        $example2b
    );

    my $example3=<<EOF;
\@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
\@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
\@prefix owl: <http://www.w3.org/2002/07/owl#>.
\@prefix skos: <http://www.w3.org/2004/02/skos/core#>.
\@prefix xsd: <http://www.w3.org/2001/XMLSchema#>.
\@prefix dc: <http://purl.org/dc/terms/>.
\@prefix dcterms: <http://purl.org/dc/terms/>.
\@prefix dc11: <http://purl.org/dc/elements/1.1/>.
\@prefix foaf: <http://xmlns.com/foaf/0.1/>.
\@prefix geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>.
\@prefix dbpedia: <http://dbpedia.org/resource/>.
\@prefix dbpedia-owl: <http://dbpedia.org/ontology/>.
\@prefix dbpprop: <http://dbpedia.org/property/>.
\@prefix hydra: <http://www.w3.org/ns/hydra/core#>.
\@prefix void: <http://rdfs.org/ns/void#>.

<http://fragments.dbpedia.org/#dataset> hydra:member <http://fragments.dbpedia.org/2014/en#dataset>.
<http://fragments.dbpedia.org/2014/en#dataset> a void:Dataset, hydra:Collection;
    void:subset <http://fragments.dbpedia.org/2014/en?subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FFran%C3%A7ois_Schuiten&predicate=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23label>;
    void:uriLookupEndpoint "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}";
    hydra:search _:triplePattern.
_:triplePattern hydra:template "http://fragments.dbpedia.org/2014/en{?subject,predicate,object}";
    hydra:mapping _:subject, _:predicate, _:object.
_:subject hydra:variable "subject";
    hydra:property rdf:subject.
_:predicate hydra:variable "predicate";
    hydra:property rdf:predicate.
_:object hydra:variable "object";
    hydra:property rdf:object.
<http://dbpedia.org/resource/François_Schuiten> rdfs:label "François Schuiten"\@de, "François Schuiten"\@en, "François Schuiten"\@es, "François Schuiten"\@fr, "François Schuiten"\@it, "François Schuiten"\@nl, "フランソワ・スクイテン"\@ja.
<http://fragments.dbpedia.org/2014/en?subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FFran%C3%A7ois_Schuiten&predicate=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23label> void:subset <http://fragments.dbpedia.org/2014/en?subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FFran%C3%A7ois_Schuiten&predicate=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23label>;
    a hydra:Collection, hydra:PagedCollection;
    dcterms:title "Linked Data Fragment of DBpedia 2014"\@en;
    dcterms:description "Triple Pattern Fragment of the 'DBpedia 2014' dataset containing triples matching the pattern { <http://dbpedia.org/resource/François_Schuiten> <http://www.w3.org/2000/01/rdf-schema#label> ?o }."\@en;
    dcterms:source <http://fragments.dbpedia.org/2014/en#dataset>;
    hydra:totalItems "7"^^xsd:integer;
    void:triples "7"^^xsd:integer;
    hydra:itemsPerPage "100"^^xsd:integer;
    hydra:firstPage <http://fragments.dbpedia.org/2014/en?subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FFran%C3%A7ois_Schuiten&predicate=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23label&page=1>
EOF
    add_response(
        $ua,
        'http://fragments.dbpedia.org/2014/en?subject=http%3A%2F%2Fdbpedia.org%2Fresource%2FFran%C3%A7ois_Schuiten&predicate=http%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23label',
        'text/turtle; charset=utf-8',
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
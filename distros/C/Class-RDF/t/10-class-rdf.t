#!perl

use blib;
use Test::More 'no_plan';
use Data::Dumper;
use strict;
use warnings;

use_ok( "Class::RDF" );

Class::RDF->is_transient;
#isa_ok( Class::RDF::Store->db_Main, "Ima::DBI::db", "database handle" );

my %ns = (
    rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    rdfs => "http://www.w3.org/2000/01/rdf-schema#",
    foaf => "http://xmlns.com/foaf/0.1/",
    geo => "http://www.w3.org/2003/01/geo/wgs84_pos#"
);
Class::RDF->define(%ns);
isa_ok( $Class::RDF::NS::Cache{rdf}, "Class::RDF::NS", 
    "namespace define hit cache" );
is( $Class::RDF::NS::Cache{rdf}->prefix, "rdf", "namespace define prefix" );
is( $Class::RDF::NS::Cache{rdf}->uri, $ns{rdf}, "namespace define uri" );

Class::RDF::NS->export(qw( foaf rdf ));
ok( foaf->can("AUTOLOAD"), "namespace export" );

my $uri = "file:t/foaf.rdf";

my @import = Class::RDF->parse(uri => $uri);
is( scalar(@import), 5, "parsed 5 objects from $uri" );

my @statements = Class::RDF::Statement->search( context => $uri );
is( scalar(@statements), 20, "20 statements fetched" );

my $node = Class::RDF::Node->find("Jo Walsh");
isa_ok( $node, "Class::RDF::Node", "node found" );
is( $node->value, "Jo Walsh", "node found has right value" );

$node = Class::RDF::Node->find;
is( $node, undef, "finding undef node doesn't wreak havoc" );

my ($zool) = Class::RDF::Object->search(
    "http://xmlns.com/foaf/0.1/name" => "Jo Walsh" );
isa_ok( $zool, "Class::RDF::Object", "fetched object" );
is( $zool->foaf::name, "Jo Walsh", "foaf:name is correct" );
isa_ok( $zool->rdf::type, "Class::RDF::Object", "rdf:type" );
is( $zool->rdf::type->uri->value, "$ns{foaf}Person", "rdf:type is correct" );

my $type = $zool->rdf::type->uri;
is( "$type", foaf->Person, "node stringification works" );

$type = $zool->rdf::type;
is( "$type", foaf->Person, "object stringification works" );

is( $type eq $zool->rdf::type, 1,"object eq overload works");    
my $nick = $zool->foaf::holdsAccount->foaf::accountName;
is( $nick, "metazool",
    "foaf::holdsAccount->foaf::accountName (striping works)" );

my @who = $zool -> foaf::knows;
is( scalar(@who), 3, "foaf:knows has correct cardinality" );

my ($sderle) = grep(( ref $_ and
    $_->foaf::mbox_sha1sum eq "4eb63c697f5b945727bad08cd889b19be41bd9aa" ),
    @who );

isa_ok($sderle, "Class::RDF::Object", "linked object" );
is($sderle->foaf::name, "Schuyler Erle", 
    "linked object has correct foaf:name" );

is( foaf->knows, "http://xmlns.com/foaf/0.1/knows", "namespace lookup" );

($sderle) = Class::RDF::Object->search( foaf->name, "%Erle", {like => 1});

isa_ok($sderle, "Class::RDF::Object", "fuzzy match" );
is($sderle->foaf::name, "Schuyler Erle", 
    "matched object has correct foaf:name" );

@who = Class::RDF::Object->search( foaf->name => undef, {order => "desc"});
isa_ok($who[0], "Class::RDF::Object", "ordered match" );
is($who[0]->foaf::name, "Schuyler Erle", 
    "ordered match has correct foaf:name" );

$sderle = Class::RDF::Object->find_or_create(
    { foaf->name => "Schuyler Erle" });
isa_ok($sderle, "Class::RDF::Object", "find_or_create existing" );
is($sderle->foaf::mbox_sha1sum, "4eb63c697f5b945727bad08cd889b19be41bd9aa",
    "find_or_create existing has correct foaf:mbox_sha1sum" );

my $lwall = Class::RDF::Object->find_or_create({ foaf->name => "Larry Wall" });
isa_ok($lwall, "Class::RDF::Object", "find_or_create new" );
is($lwall->foaf::name, "Larry Wall", 
    "find_or_create new has correct foaf:name" );

my $rdf = Class::RDF->serialize($zool,$sderle,$lwall);
my @found = Class::RDF->parse(xml => $rdf);
is(scalar(@found),3,"happily serialised and re-parsed 3 objects");

# deletion
my $z_uri = $zool->uri->value;
my @s = $zool->statements;
is(scalar(@s),8,"zool object has 8 statements before mad deletion");
$zool->delete;
@found = Class::RDF::Statement->search(subject => $z_uri);
is(scalar(@found),0,"no statements left with zool's subject");

@found = Class::RDF::Statement->search(object => $z_uri);
is(scalar(@found),0,"no statements left with zool's object");



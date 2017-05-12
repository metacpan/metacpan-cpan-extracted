#!perl

use blib;
use Test::More tests => 21;
use Data::Dumper;
use strict;
use warnings;

SKIP: {
  skip "Cache::Memcached not installed", 21
      unless eval "require Cache::Memcached";

  use_ok( "Class::RDF::Cache" );

  Class::RDF::Cache->is_transient;
  Class::RDF::Cache->set_cache({
    servers => ["localhost:11211"], 
    # debug => 1 ,
  });

  skip "memcached not running", 20
	unless Class::RDF::Cache->cache->set("test", 1);

  my %ns = (
	  rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	  rdfs => "http://www.w3.org/2000/01/rdf-schema#",
	  foaf => "http://xmlns.com/foaf/0.1/",
	  geo => "http://www.w3.org/2003/01/geo/wgs84_pos#"
	  );
  Class::RDF::Cache->define(%ns);
  Class::RDF::NS->export(keys %ns);
  my $uri = "file:t/foaf.rdf";

  my @import = Class::RDF::Cache->parse(uri => $uri);
  is( scalar(@import), 5, "parsed 5 objects from $uri" );

  my ($zool) = Class::RDF::Cache::Object->search(
	  "http://xmlns.com/foaf/0.1/name" => "Jo Walsh" );
  isa_ok( $zool, "Class::RDF::Cache::Object", "fetched object" );
  is( $zool->foaf::name, "Jo Walsh", "foaf:name is correct" );
  isa_ok( $zool->rdf::type, "Class::RDF::Cache::Object", "rdf:type" );
  is( $zool->rdf::type->uri->value, "$ns{foaf}Person", "rdf:type is correct" );

  my @who = $zool -> foaf::knows;
  is( scalar(@who), 3, "foaf:knows has correct cardinality" );

  my ($sderle) = grep(( ref $_ and
	      $_->foaf::mbox_sha1sum eq "4eb63c697f5b945727bad08cd889b19be41bd9aa" ),
	  @who );

  isa_ok($sderle, "Class::RDF::Cache::Object", "linked object" );
  is($sderle->foaf::name, "Schuyler Erle", 
	  "linked object has correct foaf:name" );

  is( foaf->knows, "http://xmlns.com/foaf/0.1/knows", "namespace lookup" );

  ($sderle) = Class::RDF::Cache::Object->search( foaf->name, "%Erle", {like => 1});

  isa_ok($sderle, "Class::RDF::Cache::Object", "fuzzy match" );
  is($sderle->foaf::name, "Schuyler Erle", 
	  "matched object has correct foaf:name" );

  @who = Class::RDF::Cache::Object->search( foaf->name => undef, {order => "desc"});
  isa_ok($who[0], "Class::RDF::Cache::Object", "ordered match" );
  is($who[0]->foaf::name, "Schuyler Erle", 
	  "ordered match has correct foaf:name" );

  $sderle = Class::RDF::Cache::Object->find_or_create(
	  { foaf->name => "Schuyler Erle" });
  isa_ok($sderle, "Class::RDF::Cache::Object", "find_or_create existing" );
  is($sderle->foaf::mbox_sha1sum, "4eb63c697f5b945727bad08cd889b19be41bd9aa",
	  "find_or_create existing has correct foaf:mbox_sha1sum" );

  my $lwall = Class::RDF::Cache::Object->find_or_create({ foaf->name => "Larry Wall" });
  isa_ok($lwall, "Class::RDF::Cache::Object", "find_or_create new" );
  is($lwall->foaf::name, "Larry Wall", 
	  "find_or_create new has correct foaf:name" );

  my ($zool3) = Class::RDF::Cache::Object->new($zool->uri->value);
  is($zool3->{cached}, 1, "zool3 object came from the cache");

  my ($zool2) = Class::RDF::Cache::Object->search(
	  "http://xmlns.com/foaf/0.1/name" => "Jo Walsh" );

  is($zool2->{cached}, undef, "zool2 object didn't from the cache yet");
  is(ref($zool2),'Class::RDF::Cache::Object',"new object is a Cache object");

  ($zool2) = Class::RDF::Cache::Object->search(
	  "http://xmlns.com/foaf/0.1/name" => "Jo Walsh" );
  is($zool2->{cached}, 1, "zool2 object did come from the cache this time");
  is(ref($zool2),'Class::RDF::Cache::Object',"new object is a Cache object");
}

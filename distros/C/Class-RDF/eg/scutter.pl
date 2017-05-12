#!/usr/bin/perl

use Class::RDF;
use strict;

my %ns = (
    rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    rdfs => "http://www.w3.org/2000/01/rdf-schema#",
    foaf => "http://xmlns.com/foaf/0.1/",
<<<<<<< scutter.pl
=======
    scutter => "http://purl.org/net/scutter/"
>>>>>>> 1.3
);

Class::RDF->set_db( "dbi:SQLite:scutter.db", "", "" );
Class::RDF->define( %ns );
Class::RDF::NS->export('rdf','rdfs','scutter','foaf');

<<<<<<< scutter.pl
my %visited;
my @plan = shift(@ARGV) || "http://iconocla.st/misc/foaf.rdf";
my $seeAlso = Class::RDF::Node->new( "$ns{rdfs}seeAlso" );

while (1) {
    while (my $uri = shift @plan) {
	warn "$uri\n";

	$visited{$uri} = time;
	my $count = eval { Class::RDF->parse(uri => $uri) };
	if ($@) {
	    warn $@;
	    next;
	}
	warn "    + $count triples added\n";
=======
my $start = Class::RDF->new( data => {
    rdf->type => scutter->Context,
    scutter->source => "http://iconocla.st/misc/foaf.rdf",
    scutter->last_fetched => -1
});

my @plan;

while (my $prospect = Class::RDF::Object->search( scutter->last_fetched => -1 )) {
    warn $prospect->scutter::source->uri->value, "\n";
    my @parsed = eval { Class::RDF->parse(
	uri => $prospect->scutter::source->uri->value) };
    $prospect->scutter::last_fetched( time );
    if ($@) {
	warn $@;
	next;
>>>>>>> 1.3
    }
    warn "+ ", scalar(@parsed), " objects added\n";

    for my $obj (@parsed) {
	if (my @seeAlso = $obj->rdfs::seeAlso) {
	    for my $target (@seeAlso) {
		my $uri = $target->uri->value;
		warn "+ seeAlso: $uri\n";
		my $source = Class::RDF::Object->find_or_create(
		    { scutter->source => $uri });
		warn $source->scutter::source->uri->value, " => ", $source->scutter::last_fetched; 
		unless ($source->scutter::last_fetched) {
		    $source->rdf::type( scutter->Context );
		    $source->scutter::last_fetched( -1 );
		    warn "+ Adding ", $uri, " to scutter plan.\n";
		}
	    }
	}
    }
}

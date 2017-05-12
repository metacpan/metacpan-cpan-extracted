#!/usr/bin/env perl

use strict;
use warnings;


use Plack::Request;
use Plack::Builder;
use Plack::App::AtteanX::Query::Cache;
use LWP::MediaTypes qw(add_type);
use RDF::Trine;
use Log::Any::Adapter;
use Log::Dispatch;
#use Carp::Always;

my $log = Log::Dispatch->new(
    outputs => [
        [
            'Screen',
            min_level => 'warn',
            stderr    => 1,
            newline   => 1
        ]
    ],
);
Log::Any::Adapter->set( 'Dispatch', dispatcher => $log );


add_type( 'application/rdf+xml' => qw(rdf xrdf rdfx) );
add_type( 'text/turtle' => qw(ttl) );
add_type( 'text/plain' => qw(nt) );
add_type( 'text/x-nquads' => qw(nq) );
add_type( 'text/json' => qw(json) );
add_type( 'text/html' => qw(html xhtml htm) );

my $cacher = Plack::App::AtteanX::Query::Cache->new;



builder {
	enable "AccessLog", format => "combined";
	enable "LogDispatch", logger => $log;
#	enable "LogAny", category => 'qr/Attean/';
	$cacher->to_app;
};

#!/usr/bin/perl

use v5.36;

use Future::AsyncAwait;

use Conduit;

use Future::IO;
use Metrics::Any::Adapter 'Prometheus';
use Net::Prometheus;

Future::IO->load_impl(qw( UV Glib IOAsync ));

my $conduit = Conduit->new(
   port => 8080,
   psgi_app => Net::Prometheus->new->psgi_app,
);

await $conduit->run;

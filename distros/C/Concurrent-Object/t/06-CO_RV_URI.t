#!/usr/bin/perl -s
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 06-CO_RV_URI.t,v 1.2 2001/06/11 20:07:02 vipul Exp $

use lib '../lib';
use Test;
BEGIN { plan tests => 11 };
use Concurrent::Object;
use URI::URL;
use Concurrent::Debug qw(debuglevel);

unless ((eval "require URI::URL")) { 
    for (1..11) { print "ok $_ # skip URI::URL not installed.\n" }
    exit 0;
}

my $URL = "http://www.vipul.net/perl/software/concurrency.cgi?abc=xyz";

my $uril = new URI::URL ($URL);
my $uri = Concurrent('URI::URL', Method => 3)->new ($URL);

ok( $uril->abs(),        $uri->abs->value );
ok( $uril->full_path(),  $uri->full_path->value );
ok( $uril->path_query(), $uri->path_query->value );
ok( $uril->crack(),      $uri->crack()->value );
ok( $uril->epath(),      $uri->epath()->value );
ok( $uril->netloc(),     $uri->netloc()->value );
ok( $uril->rel(),        $uri->rel()->value );
ok( $uril->scheme(),     $uri->scheme()->value );
ok( $uril->canonical(),  $uri->canonical()->value );
ok( $uril->as_string(),  $uri->as_string()->value );

my @pcl = $uril->path_components;
my @lc  = $uri->path_components;
ok ("@lc", "@pcl");

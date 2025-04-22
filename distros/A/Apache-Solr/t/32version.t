#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

use lib 'lib';
use Apache::Solr;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

my $server;
BEGIN {
    $server = $ENV{SOLR_TEST_SERVER}
        or plan skip_all => "no SOLR_TEST_SERVER provided";
}

my $solr = Apache::Solr->new
  ( server     => $server
  , retry_max  => 3
  , retry_wait => 2
  );

my $self = $solr;
{
    my $params = {};
    my $endpoint = $self->endpoint('info/system', core => 'admin', params => $params);

    my @params   = %$params;
    my $result   = Apache::Solr::Result->new(params => [ %$params ]
      , endpoint => $endpoint, core => $self);

    $self->request($endpoint, $result);
    warn Dumper $result;
}

done_testing;

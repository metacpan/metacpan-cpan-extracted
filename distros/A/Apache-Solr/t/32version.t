#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;

use lib 'lib';
use Apache::Solr::JSON;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

my $server;
BEGIN {
    $server = $ENV{SOLR_TEST_SERVER}
        or plan skip_all => "no SOLR_TEST_SERVER provided";
}

my $solr = Apache::Solr::JSON->new
  ( server     => $server
  , retry_max  => 3
  , retry_wait => 2
  );

my $self = $solr;
{
    my $endpoint = $self->endpoint('info/system', core => 'admin');
    my $result   = Apache::Solr::Result->new(endpoint => $endpoint, core => $self);

    $self->request($endpoint, $result);
	ok $result->success, 'got system info';
#   warn Dumper $result;
}

done_testing;

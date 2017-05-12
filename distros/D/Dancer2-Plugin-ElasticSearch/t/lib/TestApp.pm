package TestApp;

use strict;
use warnings;
use 5.012;
use Carp;
use autodie;
use utf8;

use Try::Tiny;
use Dancer2;
use Dancer2::Plugin::ElasticSearch;

set 'plugins' => {
    ElasticSearch => {
        default => {
            params => {
                nodes => $ENV{D2_PLUGIN_ES} } } } };
                

get '/client_status' => sub {
    return try {
        elastic;
        return 'available';
    } catch {
        return $_;
    };
};

get '/client_refname' => sub {
    # used to check that each call returns the same object
    return "".elastic;
};

get '/count' => sub {
    return to_json(elastic->search(
                       search_type => q{count},
                       body => { query => { match_all => {} } }));
};

1;

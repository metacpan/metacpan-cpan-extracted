#!/usr/bin/env perl

use t::TestHelper;
use Data::Dumper;

plan tests => 7;

use_ok('Bio::Cellucidate::Book');

TestHelper->setup;
eval {
    # Find
    is(Bio::Cellucidate::Book->find()->[0]->{name}, 'My First Book');
    is(Bio::Cellucidate::Book->find()->[1]->{name}, 'My Second Book');
    is(Bio::Cellucidate::Book->find( { foo => 'bar' } )->[1]->{name}, 'My Second Book');
    is(Bio::Cellucidate::Book->client->responseCode(), '200');

    # Show
    is(Bio::Cellucidate::Book->get(1)->{name}, 'My First Book');
    is(Bio::Cellucidate::Book->get(1)->{id}, 1);
};

warn "Tests died: $@" if $@;

TestHelper->teardown;

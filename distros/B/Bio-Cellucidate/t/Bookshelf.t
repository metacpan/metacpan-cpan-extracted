#!/usr/bin/env perl

use t::TestHelper;
use Data::Dumper;

plan tests => 9;

use_ok('Bio::Cellucidate::Bookshelf');

TestHelper->setup;

eval {
    # Find
    is(Bio::Cellucidate::Bookshelf->find()->[0]->{name}, 'My First Bookshelf');
    is(Bio::Cellucidate::Bookshelf->find()->[1]->{name}, 'My Second Bookshelf');
    is(Bio::Cellucidate::Bookshelf->find( { foo => 'bar' } )->[1]->{name}, 'My Second Bookshelf');
    is(Bio::Cellucidate::Bookshelf->client->responseCode(), '200');

    # Show
    is(Bio::Cellucidate::Bookshelf->get(1)->{name}, 'My First Bookshelf');
    is(Bio::Cellucidate::Bookshelf->get(1)->{id}, 1);

    # Books
    ok(Bio::Cellucidate::Bookshelf->books(1));
    is(TestHelper->last_request->{path}, '/bookshelves/1/books'); 
};

warn "Tests died: $@" if $@;

TestHelper->teardown;


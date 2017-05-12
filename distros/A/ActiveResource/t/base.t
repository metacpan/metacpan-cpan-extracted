#!/usr/bin/env perl
use strict;

package Stuff;
use parent 'ActiveResource::Base';

package main;
use Test::More;

subtest "Stuff should respond to certain class methods" => sub {
    for my $method (qw(new site user password find create connection)) {
        ok(Stuff->can($method), "There is a Stuff->$method");
    }

    done_testing;
};

subtest "Stuff->site is default to be the same as ActiveResource::Base->site" => sub {
    ActiveResource::Base->site("http://example.com");
    is(ActiveResource::Base->site, "http://example.com");
    is(Stuff->site, "http://example.com");

    done_testing;
};

subtest "Stuff->site can be overrided without effecting the value of ActiveResource::Base->site" => sub {
    Stuff->site("http://example2.com");
    ok(ActiveResource::Base->site ne Stuff->site);
    is(ActiveResource::Base->site, "http://example.com");
    is(Stuff->site, "http://example2.com");

    done_testing;
};

subtest "Stuff->collection_path", sub {
    is(Stuff->collection_path(), "/stuffs.xml", "No args.");
    is(
        Stuff->collection_path({ user_id => 3 }),
        "/users/3/stuffs.xml",
        "prefixed /users/3"
    );
    is(
        Stuff->collection_path({ user_id => 3 }, { tags => "foo bar" }),
        "/users/3/stuffs.xml?tags=foo+bar",
        "prefixed /users/3 with extra query parameters"
    );

    done_testing;
};

subtest "Stuff->element_path", sub {
    is(Stuff->element_path(42), "/stuffs/42.xml", "with the arg id");

    is(
        Stuff->element_path(42, { user_id => 3 }),
        "/users/3/stuffs/42.xml",
        "prefixed /users/3"
    );

    is(
        Stuff->element_path(42, { user_id => 3 }, { tags => "foo bar" }),
        "/users/3/stuffs/42.xml?tags=foo+bar",
        "prefixed /users/3 with extra query parameters"
    );

    done_testing;
};

subtest "Stuff instances", sub {
    my $o = Stuff->new;
    ok($o->can("attributes"), "Stuff#attributes");
    ok($o->can("load"),       "Stuff#load");

    $o->load({ description => "OHAI" });

    subtest "attribute names are accessor methods", sub {
        is($o->description, "OHAI");
        $o->description("OHAI2");
        is($o->description, "OHAI2");

        done_testing;
    };

    done_testing;
};

done_testing;

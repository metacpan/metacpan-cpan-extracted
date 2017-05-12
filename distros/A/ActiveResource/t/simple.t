#!/usr/bin/env perl
use common::sense;

package Issue;
use parent 'ActiveResource::Base';

package main;
use Test::More;

for my $method (qw(site user password)) {
    ok(Issue->can($method));
}

done_testing;

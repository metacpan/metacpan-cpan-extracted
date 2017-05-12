#!/usr/bin/perl -s
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 04-ProxySetScalar.t,v 1.5 2001/06/11 20:07:02 vipul Exp $

use lib '../lib';
use Test;
BEGIN { plan tests => 4 };
use Concurrent::Object::Proxy;
use Concurrent::Debug qw(debuglevel);

unless ((eval "require Set::Scalar")) { 
    for (1..4) { print "ok $_ # skip Set::Scalar not installed.\n" }
    exit 0;
}

my $set = new Concurrent::Object::Proxy (
               Class => 'Set::Scalar', 
               Constructor => 'new', 
               ProxyOverloading => 'Yes',
            );


$set->call ( Method => 'insert', Args => [ 'a', 'b' ] );
my @members = $set->rv ( Id => $set->call ( Method => 'members', Context => 'list' ), Context => 'list' );
ok($members[0], 'a');
ok($members[1], 'b');
ok(2, $set->rv ( Id => $set->call ( Method => 'size' ) ) );
ok('a', $set->rv ( Id => $set->call ( Method => 'has', Args => ['a'] ) ) );

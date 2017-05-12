#!/usr/bin/perl -s
##
## Concurrent::Object Test Suite
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 01-LinkedPipes.t,v 1.1.1.1 2001/06/10 14:39:39 vipul Exp $

use lib '../lib', 'lib';
use Test;
BEGIN { plan tests => 11 };
use Concurrent::Channel::LinkedPipes;

my @SQUARES = qw(0 1 4 9 16 25 36 49 64 81 100);

my $channel = new Concurrent::Channel::LinkedPipes;

if (fork == 0) { 
    $channel->init();
    my $data;
    while ($data = $channel->getline()) { 
        chomp $data;
        my $square = $data * $data;
        $channel->print ("$square\n");
    } 
    $channel->destroy();
    exit;
}

$channel->init();

for (0..10) { $channel->print ("$_\n") }

for (0..10) { 
    my $data = $channel->getline;
    chomp $data;
    ok($SQUARES[$_], $data);
}

$channel->destroy();

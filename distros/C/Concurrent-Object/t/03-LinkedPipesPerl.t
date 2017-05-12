#!/usr/bin/perl -s
##
## Concurrent::Object Test Suite
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 03-LinkedPipesPerl.t,v 1.1.1.1 2001/06/10 14:39:39 vipul Exp $

use lib '../lib', 'lib';
use Test;
BEGIN { plan tests => 2 };
use Concurrent::Channel::LinkedPipes;
use Data::Dumper;

my $sample = { 'abc' => 123,
               'def' => { 'ghi' => 456 }
             };

my $channel = new Concurrent::Channel::LinkedPipes ( Payload => 'Perl' );

if (fork == 0) { 
    $channel->init();
    my $data = $channel->getline();
    $channel->print($data);
    $channel->destroy();
    exit;
}

$channel->init();
$channel->print ($sample);
my $data = $channel->getline();
$channel->destroy();

ok($$data{abc}, 123);
ok($$data{def}{ghi}, 456);


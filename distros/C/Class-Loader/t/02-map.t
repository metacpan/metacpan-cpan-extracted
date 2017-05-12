#!/usr/bin/perl -s
##
## Class::Loader Test Suite
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 02-map.t,v 1.1.1.1 2001/04/22 01:11:40 vipul Exp $

use lib '../lib', 'lib';
package Class::Loader::Test02;
use Class::Loader;
use vars qw(@ISA);
@ISA = (Class::Loader);

sub new { 

    my $self = { Method => 'new' };
    return bless $self, shift;

}

sub test { 

    my $self = shift;
    $self->_storemap ( 'URLFILTER' => { Module => "Class::LoaderTest",
                                        Constructor => "foo" } );

}

sub load {

    my $self = shift;
    $self->_load ( 'Handler', Name => 'URLFILTER' );

}

package main;

use Data::Dumper;
use Test;
BEGIN { plan tests => 3 };

my $test = new Class::Loader::Test02;
$test->test();
$test->load();
my $map = $test->_retrmap;
ok(1) if $map;
ok(ref $test->{Handler}, "Class::LoaderTest");
ok($test->{Handler}->{Method}, "foo");


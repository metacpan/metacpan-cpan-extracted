#!/usr/bin/perl -st
##
## Class::Loader Test Suite
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 01-require.t,v 1.2 2001/04/28 03:21:47 vipul Exp $

use lib '../lib', 'lib';
package Class::Loader::Test01;
use Class::Loader;
use vars qw(@ISA);
@ISA = (Class::Loader);

sub new { 

    my $self = { Method => 'new' };
    return bless $self, shift;

}

sub test { 

    my $self = shift;
    $self->{Handler} = $self->_load ( Module => "Class::LoaderTest" );

}

sub test2 { 

    my ($self, $param) = @_;
    if ($param) { 
        $self->_load ( 'Handler2', Module => "Class::LoaderTest", 
                                       Constructor => "foo",
                                       Args => ["$param"],
                       );
    } else { 
        $self->_load ( 'Handler2', Module => "Class::LoaderTest", Constructor => "foo" );
    }

}


package main;

use Data::Dumper;
use Test;
BEGIN { plan tests => 5 };

print "construction by module name...\n";
my $test = new Class::Loader::Test01;
$test->test();
ok(1) if ref $test->{Handler} eq "Class::LoaderTest";

print "construction by module name and constructor name...\n";
$test = new Class::Loader::Test01;
$test->test2;
ok(ref $test->{Handler2}, "Class::LoaderTest");
ok($test->{Handler2}{Method}, "foo");

print "construction by module, constructor and arguments...\n";
$test = new Class::Loader::Test01;
$test->test2 ("few");
ok(ref $test->{Handler2}, "Class::LoaderTest");
ok($test->{Handler2}{Method}, "few");




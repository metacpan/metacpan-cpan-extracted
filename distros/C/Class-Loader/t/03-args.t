#!/usr/bin/perl -st
##
## Class::Loader Test Suite
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 03-args.t,v 1.1 2001/05/02 02:57:03 vipul Exp $

use lib '../lib', 'lib';
package Class::Loader::Test01;
use Class::Loader;
use vars qw(@ISA);
@ISA = (Class::Loader);

sub new { 

    return bless {}, shift;

}

sub test { 

    my $self = shift;
    my $n = "value";
    my $ref = { 4 => 2 };
    $self->{Handler} = $self->_load ( 
            Module => "Class::LoaderTest", 
            Constructor => "blah", 
            Args => [ "abc" => "xyz", $n => [qw(sd ds dd)], 'c' => $ref ],
    ) || die $!;

}

package main;

use Test;
BEGIN { plan tests => 4 };

my $test = new Class::Loader::Test01;
$test->test();
ok("sd", @{$test->{Handler}->{value}}[0]);
ok("dd", @{$test->{Handler}->{value}}[2]);
ok("xyz", $test->{Handler}->{abc});
ok("2", $test->{Handler}->{c}->{4});


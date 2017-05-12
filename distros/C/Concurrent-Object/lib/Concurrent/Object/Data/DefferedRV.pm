#!/usr/bin/perl -sw
##
## 
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: DefferedRV.pm,v 1.1.1.1 2001/06/10 14:39:39 vipul Exp $

package Concurrent::Object::Data::DefferedRV; 
use Concurrent::Debug qw(debug);
use Data::Dumper;


sub new { 

    my ($class, %params) = @_;
    my $self = { %params };
    return bless $self, $class;
    
} 


sub value { 

    my $self = shift;
    my $value = $self->{CO}->__method_fg ( Id => $self->{Id} );
    return $value;

} 

1;


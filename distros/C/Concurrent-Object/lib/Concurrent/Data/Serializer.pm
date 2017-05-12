#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Serializer.pm,v 1.3 2001/06/11 20:06:57 vipul Exp $

package Concurrent::Data::Serializer; 
use Storable qw(freeze thaw);
use Data::Dumper;
use MIME::Base64;

sub new { 
    my ($class, %params) = @_;
    $params{Method} ||= 'Storable';
    return bless {%params}, $class 
}


sub serialize { 

    my ($self, $params) = @_;
    my $dump   = $$self{Method} eq "Dumper" ? Dumper($params) : freeze($params);
    my $string = encode_base64 ($dump);
    $string =~ s/\n/\0/mg;
    return "$string\n";

}


sub deserialize {

    my ($self, $string) = @_;
    $string =~ s/\0/\n/mg;
    my $decoded = decode_base64 ($string);
    return $$self{Method} eq "Dumper" ? eval $decoded : thaw( $decoded );

}


1;


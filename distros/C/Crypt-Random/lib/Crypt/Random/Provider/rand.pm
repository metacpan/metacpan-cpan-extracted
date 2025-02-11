##
## Copyright (c) 1998-2025, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use strict;
use warnings;
package Crypt::Random::Provider::rand; 
use Math::Pari qw(pari2num);
use Crypt::URandom qw/urandom/;

our $VERSION = '1.57';

sub new { 

    my ($class, %params) = @_;
    my $self = { Source => $params{Source} || sub { Crypt::URandom::urandom($_[0]) } };
    return bless $self, $class;

}

sub get_data { 

    my ($self, %params) = @_;
    $self = {} unless ref $self;

    my $size = $params{Size}; 
    my $skip = $params{Skip} || $$self{Skip} || '';
    my $q_skip = quotemeta($skip);

    if ($size && ref $size eq "Math::Pari") { 
        $size = pari2num($size);
    }

    my $bytes = $params{Length} || (int($size / 8) + 1);

    my $source = $$self{Source} || sub { Crypt::URandom::urandom($_[0]) };
    
    my($r, $read, $rt) = ('', 0);
    while ($read < $bytes) {
        $rt = &$source($bytes - $read);
        $rt =~ s/[$q_skip]//g if $skip;
        $r .= $rt; 
        $read = length $r;
    }

    $r;

}


sub available { 

    return 1;

}


1;
 

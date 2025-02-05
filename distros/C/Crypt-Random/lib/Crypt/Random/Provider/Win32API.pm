##
## Copyright (c) 1998-2025, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
## The WIN32API implementation below is based on code written by
## Leon Timmermans (Leont) as implemented here by Timothy Legge (timlegge)

use strict;
use warnings;
package Crypt::Random::Provider::Win32API; 
use Math::Pari qw(pari2num);
use Crypt::URandom qw/urandom/;

our $VERSION = '1.56';

sub new { 

    my ($class, %params) = @_;
    my $self = { Source => $params{Source} };
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
    my $source;

    if (eval { require Win32::API }) {
	my $genrand = Win32::API->new('advapi32', 'INT SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength)')
	    or Carp::croak("Could not import SystemFunction036: $^E");

        $source = sub {
            my ($count) = @_;
            return '' if $count == 0;
            Carp::croak('The Length argument must be supplied and must be an integer') if not defined $bytes or $bytes =~ /\D/;
            my $buffer = chr(0) x $count;
            $genrand->Call($buffer, $count) or Carp::croak("Could not read random data");
            return $buffer;
        };
    }
    else {
	    Carp::croak('Win32::API is required');
    }

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
    if (eval { require Win32::API }) {
        return 1;
    } else {
        return 0;
    };
}

1;

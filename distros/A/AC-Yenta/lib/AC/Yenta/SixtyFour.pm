# -*- perl -*-

# Copyright (c) 2010 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2010-Dec-23 11:39 (EST)
# Function: 64 bit numbers as native integers or math::bigints?
#
# $Id$

package AC::Yenta::SixtyFour;
use strict;

# export one set of functions as x64_<name>
sub import {
    my $class  = shift;
    my $caller = caller;

    my $l = length(sprintf '%x', -1);
    my $prefix;
    if( $l >= 16 ){
        $prefix = 'native_';
    }else{
        $prefix = 'bigint_';
        require Math::BigInt;
    }

    no strict;
    no warnings;
    for my $f qw(number_to_hex hex_to_number sixty_four_ones one_million){
        *{$caller . '::' . 'x64_' . $f} = \&{ $prefix . $f };
    }
}

################################################################

sub native_number_to_hex {
    my $v = shift;
    return sprintf '%016X', $v;
}

sub native_hex_to_number {
    my $v = shift;
    return hex($v);
}

# prevent overflow warning on 32 bit system
my $sfo = '0xFFFFFFFF_FFFFFFFF';
sub native_sixty_four_ones {
    return hex($sfo);
}

sub native_one_million {
    return 1_000_000;
}

################################################################


sub bigint_number_to_hex {
    my $v = shift;

    if( ref $v ){
        my $h = $v->as_hex();

        # remove leading '0x', and pad to length 16
        $h =~ s/^0x//;
        return ('0' x (16 - length($h))) . $h;

    }else{
        # QQQ?
        return sprintf '%016X', $v;
    }
}

sub bigint_hex_to_number {
    my $v = shift;
    return Math::BigInt->new('0x' . $v);
}

sub bigint_sixty_four_ones {
    return Math::BigInt->new($sfo);
}

sub bigint_one_million {
    return Math::BigInt->new('1_000_000');
}


################################################################

1;

use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use B;
use Carp qw/croak/;
use Config;
use JSON::MaybeXS;

use base 'Exporter';
our @EXPORT = qw/sv_type packed_is bytes_are to_extjson to_myjson try_or_fail/;

my $json_codec = JSON::MaybeXS->new(
    ascii => 1,
    pretty => 0,
    canonical => 1,
    allow_blessed => 1,
    convert_blessed => 1,
);

sub to_extjson {
    local $ENV{BSON_EXTJSON} = 1;
    return $json_codec->encode( shift );
}

sub to_myjson {
    return $json_codec->encode( shift );
}

sub sv_type {
    my $v     = shift;
    my $b_obj = B::svref_2object( \$v );
    my $type  = ref($b_obj);
    $type =~ s/^B:://;
    return $type;
}

sub packed_is {
    croak("Not enough args for packed_is()") unless @_ >= 3;
    my ( $template, $got, $exp, $label ) = @_;
    $label = '' unless defined $label;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $ok;
    if ( $template eq 'q' && ! $Config{use64bitint} ) {
        if ( !ref($got) && !ref($exp) ) {
            # regular scalar will fit in 32 bits, so downgrade the template
            $template = 'l';
        }
        else {
            # something is a reference, so must be BigInt or equivalent
            $ok = ok( $got eq $exp, $label );
            diag "Got: $got, Expected: $exp" unless $ok;
            return $ok;
        }
    }

    $ok = ok( pack( $template, $got ) eq pack( $template, $exp ), $label );
    diag "Got: $got, Expected: $exp" unless $ok;

    return $ok;
}

sub bytes_are {
    croak("Not enough args for bytes_are()") unless @_ >= 2;
    my ( $got, $exp, $label ) = @_;
    $label = '' unless defined $label;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $ok = ok( $got eq $exp, $label );
    diag "Got:\n", unpack( "H*", $got ), "\nExpected:\n", unpack( "H*", $exp )
      unless $ok;

    return $ok;
}

sub try_or_fail {
    my ($code, $label) = @_;
    eval { $code->() };
    if ( my $err = $@ ) {
        fail($label);
        diag "Error:\n$err";
        return;
    }
    return 1;
}


1;
#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2016 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: set ts=4 sts=4 sw=4 et tw=75:

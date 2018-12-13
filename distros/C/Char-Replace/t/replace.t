#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Char::Replace;

#use Devel::Peek

{
    note "invalid cases";
    is Char::Replace::replace( undef, undef ), undef, "replace(undef, undef)";
    is Char::Replace::replace( undef, [] ), undef, "replace(undef, [])";
    is Char::Replace::replace( [], [] ), undef, "replace([]], [])";
}

{
    note "invalid map";
    is Char::Replace::replace( "abcd", undef ), "abcd", "replace( q[abcd], undef)";
    is Char::Replace::replace( "abcd", [] ), "abcd", "replace( q[abcd], [] )";
}

note "string replacement";

our @MAP;
our $STR;
$MAP[$_] = chr($_) for 0 .. 255;
$MAP[ ord('a') ] = 'X';

is Char::Replace::replace( "abcd", \@MAP ), "Xbcd", "a -> X";

$MAP[ ord('b') ] = 'Y';
is Char::Replace::replace( "abcd", \@MAP ), "XYcd", "a -> X ; b => Y";

$MAP[ ord('b') ] = 'ZZ';
is Char::Replace::replace( "abcd", \@MAP ), "XZZcd", "a -> X ; b => ZZ";

$MAP[$_] = chr($_) for 0 .. 255;
$MAP[ ord('a') ] = 'AAAA';
$MAP[ ord('c') ] = 'CCCC';

my $got = Char::Replace::replace( "abcd" x 20, \@MAP );
my $expect = "AAAAbCCCCd" x 20;
is $got, $expect, "need to grow the string" or diag ":$got:\n", ":$expect:\n";

{
    note "checking all chars from 0..255";
    my $str = '';
    $str .= chr($_) for 1 .. 255;
    @MAP = @{ Char::Replace::identity_map() };

    is Char::Replace::replace( $str, \@MAP ), $str, q[check chars from 1 to 255];

    $str = "\0\0my string\0\0";
    is Char::Replace::replace( $str, \@MAP ), $str, q[check string with \0];
}

done_testing;

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

{
    note "invalid cases";
    is Char::Replace::trim(undef), undef, "trim(undef)";
    is Char::Replace::trim( [] ), undef, "trim( [] )";
    is Char::Replace::trim( {} ), undef, "trim( {} )";
}

{
    note "string without trailing/leading spaces: plain and utf8";
    is Char::Replace::trim('hello'),          'hello',          "trim( 'hello' )";
    is Char::Replace::trim('hêllô'),        'hêllô',        "trim( 'hêllô )";
    is Char::Replace::trim('hello world'),    'hello world',    "trim( 'hello world' )";
    is Char::Replace::trim('hėllõ wòrld'), 'hėllõ wòrld', "trim( 'hėllõ wòrld' )";
}

{
    note "trailing / leading spaces: plain";
    is Char::Replace::trim('   hello'),         'hello', "trim( '  hello' )";
    is Char::Replace::trim(qq[\n\t\r\f hello]), 'hello', q[\n\t\r\f hello];
    is Char::Replace::trim('hello   '),         'hello', "trim( 'hello  ' )";
    is Char::Replace::trim(qq[hello\n\t\r\f ]), 'hello', q[hello\n\t\r\f ];
}

{
    note "trailing / leading spaces: utf8";
    is Char::Replace::trim('   hėllõ wòrld'),         'hėllõ wòrld', "trim( '  hėllõ wòrld' )";
    is Char::Replace::trim(qq[\n\t\r\f hėllõ wòrld]), 'hėllõ wòrld', q[\n\t\r\f hėllõ wòrld];
    is Char::Replace::trim('hėllõ wòrld   '),         'hėllõ wòrld', "trim( 'hėllõ wòrld  ' )";
    is Char::Replace::trim(qq[hėllõ wòrld\n\t\r\f ]), 'hėllõ wòrld', q[hėllõ wòrld\n\t\r\f ];
}

{
    note "checking original STR";
    my $str = q[   some spaces   ];
    is Char::Replace::trim( $str ), 'some spaces', 'trim'; 
    is $str, q[   some spaces   ], 'original PV preserved';
} 

done_testing;

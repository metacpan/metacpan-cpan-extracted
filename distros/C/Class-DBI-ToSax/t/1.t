# @(#) $Id: 1.t,v 1.1 2003/03/27 15:00:26 dom Exp $

use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Class::DBI::ToSax' );
}

can_ok( 'Class::DBI::ToSax', qw( to_sax ) );

# vim: set ai et sw=4 syntax=perl :

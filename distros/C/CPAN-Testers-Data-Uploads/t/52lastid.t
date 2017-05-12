#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;

use lib 't';
use CTDU_Testing;

ok( my $obj = CTDU_Testing::getObj(), "got object" );

my $f = 't/_DBDIR/lastid.txt';
unlink($f)  if(-f $f);

ok( ! -f $f, 'lastid.txt absent' );
is( $obj->_lastid, 0, "retrieve from absent file" );
ok( -f $f, 'lastid.txt now exists' );
is( $obj->_lastid, 0, "retrieve 0" );
is( $obj->_lastid(3), 3, "set 3" );
is( $obj->_lastid, 3, "retreive 3" );

ok( unlink($f), 'removed last_id.txt' );

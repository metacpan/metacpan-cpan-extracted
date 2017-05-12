#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Addresses;
use Test::More tests => 23;

my $config = 't/20attributes.ini';
my $lastid = 't/_DBDIR/lastid.txt';

ok( my $obj = CPAN::Testers::Data::Addresses->new(config => $config), "got object" );

# Class::Accessor::Fast method tests

# predefined attributes
foreach my $k ( qw/
    dbh
    lastfile
    logclean
/ ){
  my $label = "[$k]";
  SKIP: {
    ok( $obj->can($k), "$label can" ) or skip "'$k' attribute missing", 3;
    isnt( $obj->$k(), undef, "$label has default" );
    is( $obj->$k(123), 123, "$label set" ); # chained, so returns object, not value.
    is( $obj->$k, 123, "$label get" );
  };
}

# undefined attributes
foreach my $k ( qw/
    logfile
/ ){
  my $label = "[$k]";
  SKIP: {
    ok( $obj->can($k), "$label can" )
	or skip "'$k' attribute missing", 3;
    is( $obj->$k(), undef, "$label has no default" );
    is( $obj->$k(123), 123, "$label set" ); # chained, so returns object, not value.
    is( $obj->$k, 123, "$label get" );
  };
}


### Last ID Tests

$obj->lastfile($lastid);
unlink($lastid)  if(-f $lastid);

ok( ! -f $lastid, 'lastid.txt absent' );
is( $obj->_lastid, 0, "retrieved from absent file" );
ok( -f $lastid, 'lastid.txt now exists' );
is( $obj->_lastid, 0, "retrieved 0" );
is( $obj->_lastid(3), 3, "set 3" );
is( $obj->_lastid, 3, "retreived 3" );

unlink($lastid);

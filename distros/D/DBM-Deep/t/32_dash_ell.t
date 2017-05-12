#!/usr/bin/perl -l

# Test for interference from -l on the commandline.
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

my ($fh, $filename) = new_fh();
my $db = DBM::Deep->new( $filename );

##
# put/get key
##
$db->{key1} = "value1";
is( $db->get("key1"), "value1", "get() works with hash assignment" );
is( $db->fetch("key1"), "value1", "... fetch() works with hash assignment" );
is( $db->{key1}, "value1", "... and hash-access also works" );

done_testing;

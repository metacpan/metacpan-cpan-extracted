#!/usr/bin/perl -w

# http://rt.cpan.org/Ticket/Display.html?id=27107 
# can't call as_isbn13 on an already isbn13 object

use Test::More 'no_plan';

use_ok( Business::ISBN );

my $ISBN = "9789607771278";

my $isbn = Business::ISBN->new( $ISBN );
isa_ok( $isbn, 'Business::ISBN' );

#use Data::Dumper; print STDERR Dumper( $isbn );

ok( $isbn->is_valid, "Valid ISBN" );
is( $isbn->as_string([]), $ISBN, "String version comes back as undef" );

ok( ! $isbn->fix_checksum, "Checksum was just fine, thank you." );
#use Data::Dumper; print STDERR Dumper( $isbn );

my $isbn13 = $isbn->as_isbn13;

#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Will it get past something that returns undef?
{
my $die_sub   = sub { die { message => "Made it to the die sub" } };
my $undef_sub = sub { return };
my $zero_sub  = sub { 0 };
my $pass_sub  = sub { 1 };

{
my $sub = $bucket->__compose_pass_or_stop( $pass_sub, $undef_sub, $die_sub );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

my $result = eval { $sub->( {}) };
my $at = $@;
ok( ! $result, "Satisfied one" );
ok( ! ref $at, "No error in \$@" );
#print STDERR Data::Dumper->Dump( [$at], [qw(at)] );
}

{
my $sub = $bucket->__compose_pass_or_stop( $undef_sub, $undef_sub );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

my $result = eval { $sub->({}) };
my $at = $@;

is( $result, undef, "Satisfied none and failed, as expected" );
ok( ! ref $at, "No error in \$@" );
}

{
my $sub = $bucket->__compose_pass_or_stop( $pass_sub, $die_sub );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

my $result = eval { $sub->({}) };
my $at = $@;

is( $result, undef, "Satisfied none, died, and failed, as expected" );
ok( ref $at, "There's an error in \$@ for die_sub" );
#print STDERR Data::Dumper->Dump( [$at], [qw(at)] );
}

}

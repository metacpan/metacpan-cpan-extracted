#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use CPS qw( dropk );

my $kadd = sub { $_[2]->( $_[0] + $_[1] ) };

my $add = dropk { } $kadd;

is( ref $add, "CODE", 'dropk returns plain CODE reference' );

my $sum = $add->( 1, 2 );
is( $sum, 3, 'dropped function returns result' );

my $later;
my $kwait = sub {
   my $k = pop; my @args = @_;
   $later = sub { $k->( @args ) }
};

my $identity = dropk { $later->() } $kwait;

my $result = $identity->( "hello" );
is( $result, "hello", 'idenity in scalar context' );

my @result = $identity->( 10, 20, 30 );
is_deeply( \@result, [ 10, 20, 30 ], 'identity in list context' );

#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use CPS qw( liftk );

my $kadd = liftk { shift() + shift() };

is( ref $kadd, "CODE", 'liftk returns plain CODE reference' );

my $sum;
$kadd->( 1, 2, sub { $sum = shift } );

is( $sum, 3, 'liftk on BLOCK' );

sub mul { shift() * shift() };
my $kmul = liftk \&mul;

my $product;
$kmul->( 2, 3, sub { $product = shift } );

is( $product, 6, 'liftk on \&func' );

sub splitwords { split m/\s+/, $_[0] };
my $ksplitwords = liftk \&splitwords;

my @words;
$ksplitwords->( "my message here", sub { @words = @_ } );

is_deeply( \@words, [qw( my message here )], 'liftk works on list-returning functions' );

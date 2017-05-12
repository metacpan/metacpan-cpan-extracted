#!perl
use strict;
use Test::More tests => 15;
BEGIN { use_ok( 'Data::Sorting' => ':basics', ':arrays' ); }
require 't/sort_tests.pl';

my @values = qw( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 );
my @params = ( -compare=>'numeric' );

my @v_array;
my $v_aryref;
my ($v1, $v2, $v3, $v4, @v5);
my @ordered;

### sorted_by

{ 
  my @v_array = shuffle(@values);
  my $v_aryref = [ shuffle(@values) ];
  my($v1, $v2, $v3, $v4, @v5) = shuffle(@values);
  my @ordered;
  
  @ordered = sorted_by( \@params, @v_array );
  ok( arrays_match( \@ordered, \@values ) );
  
  @ordered = sorted_by( \@params, @$v_aryref );
  ok( arrays_match( \@ordered, \@values ) );
  
  @ordered = sorted_by( \@params, $v1, $v2, $v3, $v4, @v5 );
  ok( arrays_match( \@ordered, \@values ) );
}

{ 
  my @v_array = shuffle(@values);
  my $v_aryref = [ shuffle(@values) ];
  my($v1, $v2, $v3, $v4, @v5) = shuffle(@values);
  my @ordered;
  
  @ordered = sort_function( @params )->( @v_array );
  ok( arrays_match( \@ordered, \@values ) );
  
  @ordered = sort_function( @params )->( @$v_aryref );
  ok( arrays_match( \@ordered, \@values ) );
  
  @ordered = sort_function( @params )->( $v1, $v2, $v3, $v4, @v5 );
  ok( arrays_match( \@ordered, \@values ) );
}

### sorted_array, sorted_arrayref

{ 
  my @v_array = shuffle(@values);
  my $v_aryref = [ shuffle(@values) ];
  my @ordered;
  
  @ordered = sorted_array( @v_array, @params );
  ok( arrays_match( \@ordered, \@values ) );
  
  @ordered = sorted_array( @$v_aryref, @params );
  ok( arrays_match( \@ordered, \@values ) );
}

{ 
  my @v_array = shuffle(@values);
  my $v_aryref = [ shuffle(@values) ];
  my @ordered;
  
  @ordered = sorted_arrayref( \@v_array, @params );
  ok( arrays_match( \@ordered, \@values ) );
  
  @ordered = sorted_arrayref( $v_aryref, @params );
  ok( arrays_match( \@ordered, \@values ) );
}

###

{ 
  my @v_array = shuffle(@values);
  my $v_aryref = [ shuffle(@values) ];
  
  sort_array( @v_array, @params );
  ok( arrays_match( \@v_array, \@values ) );
  
  sort_array( @$v_aryref, @params );
  ok( arrays_match( $v_aryref, \@values ) );
}

{ 
  my @v_array = shuffle(@values);
  my $v_aryref = [ shuffle(@values) ];
  
  sort_arrayref( \@v_array, @params );
  ok( arrays_match( \@v_array, \@values ) );
  
  sort_arrayref( $v_aryref, @params );
  ok( arrays_match( $v_aryref, \@values ) );
}

###

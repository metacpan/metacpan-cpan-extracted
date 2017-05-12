#!/usr/bin/env perl
# created on 2014-01-16

use warnings;
use strict;
use 5.010;

use Pod::Usage;
use Getopt::Long qw(:config auto_help);
use Bio::Gonzales::Util::File;
use Bio::Gonzales::Matrix::IO;
use Data::Dumper;

my %opt = ( concat => 0 );
GetOptions( \%opt, 'va=i@', 'vb=i@', 'a=i@', 'b=i@', 'concat' ) or pod2usage(2);

my %a;
my %b;

my ( $a_f, $b_f ) = @ARGV;
pod2usage("$a_f is no file") unless ( -f $a_f );
pod2usage("$b_f is no file") unless ( -f $b_f );

my $a_fh = openod( $a_f, '<' );

my @va;
my @vb;
@va = @{ $opt{va} } if ( exists( $opt{va} ) );
@vb = @{ $opt{vb} } if ( exists( $opt{vb} ) );

my $a_data
  = dict_slurp( $a_f, { key_idx => $opt{a}, val_idx => $opt{va}, uniq => 0, concat_keys => $opt{concat} } );
my $b_data
  = dict_slurp( $b_f, { key_idx => $opt{b}, val_idx => $opt{vb}, uniq => 0, concat_keys => $opt{concat} } );

my @both     = grep { exists( $b_data->{$_} ) } keys %$a_data;
my @not_in_a = grep { !exists( $a_data->{$_} ) } keys %$b_data;
my @not_in_b = grep { !exists( $b_data->{$_} ) } keys %$a_data;

say "A: $a_f";
say "B: $b_f";
say "";

say "A DISTINCT:   " . scalar keys %$a_data;
if ( scalar keys %$b_data > 0 ) {
  say "first 3:";
  say "    " . join( "\n    ", ( keys %$a_data )[ 0 .. 2 ] );
}
say "";

say "B DISTINCT:   " . scalar keys %$b_data;
if ( scalar keys %$b_data > 0 ) {
  say "first 3:";
  say "    " . join( "\n    ", ( keys %$b_data )[ 0 .. 2 ] );
}
say "";

say "INTERSECTION: " . scalar @both;
if ( scalar @both > 0 ) {
  say "first 3:";
  say "    " . join( "\n    ", @both[ 0 .. 2 ] );
}
say "";

say "UNIQUE TO A:  " . scalar @not_in_b;
if ( scalar @not_in_b > 0 ) {
  say "first 3:";
  say "    " . join( "\n    ", @not_in_b[ 0 .. 2 ] );
}
say "";

say "UNIQUE TO B:  " . scalar @not_in_a;
if ( scalar @not_in_a > 0 ) {
  say "first 3:";
  say "    " . join( "\n    ", @not_in_a[ 0 .. 2 ] );
}
say "";

my %both = map { $_ => 1 } @both;

for ( my $idx = 0; $idx < @va; $idx++ ) {
  my %uniq;
  my %total;
  for $a ( keys %$a_data ) {
    for my $v ( @{ $a_data->{$a} } ) {
      $uniq{ $v->[$idx] }++
        if ( $both{$a} );
      $total{ $v->[$idx] }++;
    }
  }
  my $num_uniq = keys %uniq;
  my $num_total = keys %total;
  my $diff = $num_total - $num_uniq;
  say "INTERSECTION A (column $va[$idx]):  $num_uniq of $num_total (diff $diff)";
  say "first 3:";
  say "    " . join( "\n    ", ( keys %uniq )[ 0 .. 2 ] );
  say "";
}
for ( my $idx = 0; $idx < @vb; $idx++ ) {
  my %uniq;
  my %total;
  for $b ( keys %$b_data ) {
    for my $v ( @{ $b_data->{$b} } ) {
      $uniq{ $v->[$idx] }++
        if ( $both{$b} );
      $total{ $v->[$idx] }++;
    }
  }
  my $num_uniq = keys %uniq;
  my $num_total = keys %total;
  my $diff = $num_total - $num_uniq;
  say "INTERSECTION B (column $vb[$idx]):  $num_uniq of $num_total (diff $diff)";
  say "first 3:";
  say "    " . join( "\n    ", ( keys %uniq )[ 0 .. 2 ] );
  say "";
}

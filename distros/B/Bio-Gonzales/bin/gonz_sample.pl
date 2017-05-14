#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Pod::Usage;
use Getopt::Long qw(:config auto_help);
use File::Spec::Functions;
use File::Slurp;

my %opt = ();
GetOptions( \%opt, 'header|h', 'frac=f') or pod2usage(2);

my $f = shift;
pod2usage("$f is no file") unless(-f $f);

<STDIN> if ( $opt{header} );

my $frac     = $opt{frac}


while(<STDIN>) {

      print
    if ( rand() <= $frac );

  my %result;
  for my $g (@go) {
    $result{ join( "\t", @$g ) } = 1 if ( exists( $train_set{ $g->[0] } ) );
  }

  die "not enough data to sample training data set" unless ( keys %result > 0 );

  my $train_file = catfile( $base_dir, "go.cv_train.$i.in" );

  open my $go_train_fh, '>', $train_file or die "Can't open filehandle: $!";
  # no chomp done, so print
  for ( keys %result ) { print $go_train_fh $_; }
  for ( keys %pass ) { print $go_train_fh $_ if ( !exists( $result{$_} ) ); }
  close $go_train_fh;

  # write test and train sets to file, too
  my $cv_split_file = catfile( $base_dir, "go.cv_split.$i.lst" );

  # use say to print also newline
  open my $cv_split_fh, '>', $cv_split_file or die "Can't open filehandle: $!";
  for ( keys %test_set ) { say $cv_split_fh join("\t", $_, 'test'); }
  for ( keys %train_set ) { say $cv_split_fh join("\t", $_, 'train'); }
  close $cv_split_fh;

  system( "gzip", "-f", $cv_split_file );

  system( "gzip", "-f", $train_file );
}

#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Encode 'encode';
use Data::Dumper;
use Test::More;

use D;

# $ perl -Mblib test.t 
# run du() test
{
  my $ref_data1 = {
    hira=>"いとう",
    kanji=>"伊藤",
  };

  my $output;

  local $SIG{__WARN__} = sub {
    $output = shift;
  };

  du($ref_data1);

  like( $output, qr/hira/);
  like( $output, qr/kanji/);
  my $em1 = encode("UTF-8",'いとう');
  like( $output, qr/$em1/);
  my $em2 = encode("UTF-8",'伊藤');
  like( $output, qr/$em2/);
}

# run dw() test
{
  my $ref_data2 = {
    hira=>"いとう",
    kanji=>"伊藤",
  };

  my $output;

  local $SIG{__WARN__} = sub {
    $output = shift;
  };

  dw($ref_data2);

  like( $output, qr/hira/);
  like( $output, qr/kanji/);
  my $em1 = encode("cp932",'いとう');
  like( $output, qr/$em1/);
  my $em2 = encode("cp932",'伊藤');
  like( $output, qr/$em2/);
}

done_testing;

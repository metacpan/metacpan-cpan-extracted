#!perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the Action class, with CSV reading, CSV generation and HTML generation
#
use 5.38.0;
use utf8;
use strict;
use warnings;
use Test::More;
use Arithmetic::PaperAndPencil;
use feature qw/class/;
use open ':encoding(UTF-8)';

plan(tests => 3);

my $csv_name = 't/data/01-action.csv';
open my $fh, '<', $csv_name
    or die "opening $csv_name $!";
my $ref = '';
{ local $/ = undef;
  $ref =  <$fh>;
}
close $fh
    or die "closing $csv_name $!";
my $sheet = Arithmetic::PaperAndPencil->new();
$sheet->from_csv($ref);
is($sheet->csv, $ref, "There and back again");

my $html_name = 't/data/01-action-simple.html';
open $fh, '<', $html_name
    or die "opening $html_name $!";
$ref = '';
{ local $/ = undef;
  $ref =  <$fh>;
}
close $fh
    or die "closing $html_name $!";
my $result = $sheet->html(silent => 1, level => 0);
is($result, $ref, "HTML generation without css");


my $css = { 'underline' => 'under'
          , 'strike'    => 'striken'
          , 'write'     => 'writing'
          , 'read'      => 'reading'
          , 'talk'      => 'talking'
          };
$html_name = 't/data/01-action-classy.html';
open $fh, '<', $html_name
    or die "opening $html_name $!";
$ref = '';
{ local $/ = undef;
  $ref =  <$fh>;
}
close $fh
    or die "closing $html_name $!";
$result = $sheet->html(lang => 'fr', silent => 1, level => 0, css => $css);
is($result, $ref, "HTML generation with css");

#!/usr/bin/perl -w

use warnings;
use strict;
use Carp;

use Test::More tests => 36;
use_ok('CAM::PDF');

is_deeply([CAM::PDF->rangeToArray(0,10)],
          [0,1,2,3,4,5,6,7,8,9,10], 'range test');
is_deeply([CAM::PDF->rangeToArray(0,10,'1-2')],
          [1,2], 'range test');
is_deeply([CAM::PDF->rangeToArray(0,10,'-3')],
          [0,1,2,3], 'range test');
is_deeply([CAM::PDF->rangeToArray(0,10,'8-')],
          [8,9,10], 'range test');
is_deeply([CAM::PDF->rangeToArray(0,10,3,4,'6-8',11,2)],
          [3,4,6,7,8,2], 'range test');
is_deeply([CAM::PDF->rangeToArray(0,10,'7-4')],
          [7,6,5,4], 'range test');
is_deeply([CAM::PDF->rangeToArray(10,20,'1-3,6,22,25-28')],
          [], 'range test');
is_deeply([CAM::PDF->rangeToArray(10,20,'-3')],
          [], 'range test');
is_deeply([CAM::PDF->rangeToArray(10,20,'25-')],
          [], 'range test');
is_deeply([CAM::PDF->rangeToArray(1, 15, '1,3-5,12,9', '14-', '8 - 6, -2')],
          [1,3,4,5,12,9,14,15,8,7,6,1,2], 'range test');

is(CAM::PDF->new('nosuchfile.pdf'), undef, 'open non-existent file');

foreach my $strtest (
   ['(foo)', 'foo'],
   ['(foo)(bar)', 'foo'], # parsing should stop at the end of the string
   ['((foo))', '(foo)'],
   ['(\\(foo\\))', '(foo)'],
   ['(\\(foo)', '(foo'],
   ['(foo\\))', 'foo)'],
   ['(foo\\\\)', 'foo\\'],
   ['(foo\\\\\\))', 'foo\\)'],
   ['(foo\\n)', 'foo'."\n"],
   ['(foo\\r)', 'foo'."\r"],
   ['(foo\\t)', 'foo'."\t"],
   ['(octal\\040)', 'octal '],
   ['(octal\\40)', 'octal '],
   ['(\134\\\\)', '\\\\'],
   ['(\134\\\\\\))', '\\\\)'],
   ['(\134a\\\\\\))', '\\a\\)'],
   ['(\(\134\\\\\\))', '(\\\\)'],
)
{
   my $orig = $strtest->[0];
   my $expect = $strtest->[1];
   is(CAM::PDF->parseString(\$orig)->{value}, $expect,
      'parseString '.$orig);
}


foreach my $strtest (
   ['<20>', ' '],
   ['<2>', ' '],
   ['<666f6f>', 'foo'],
)
{
   my $orig = $strtest->[0];
   my $expect = $strtest->[1];
   is(CAM::PDF->parseHexString(\$orig)->{value}, $expect,
      'parseHexString '.$orig);
}

is(CAM::PDF->parseBoolean(\'true')->{value}, 'true', 'parseBoolean');
is(CAM::PDF->parseBoolean(\'TRUE')->{value}, 'true', 'parseBoolean');
is(CAM::PDF->parseBoolean(\'false')->{value}, 'false', 'parseBoolean');
is(CAM::PDF->parseNull(\'null')->{value}, undef, 'parseNull');

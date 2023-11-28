#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use v5.20;

use CodeGen::Cpppp::CParser;

for (
   [  'For loop',
      'for(int i=0; i<1; i++){}',
      [ [ keyword => 'for', 0, 3 ],
        [ '('     => '(',   3, 1 ],
        [ keyword => 'int', 4, 3 ],
        [ ident   => 'i',   8, 1 ],
        [ '='     => '=',   9, 1 ],
        [ integer => 0,    10, 1 ],
        [ ';'     => ';',  11, 1 ],
        [ ident   => 'i',  13, 1 ],
        [ '<'     => '<',  14, 1 ],
        [ integer => 1,    15, 1 ],
        [ ';'     => ';',  16, 1 ],
        [ ident   => 'i',  18, 1 ],
        [ '++'    => '++', 19, 2 ],
        [ ')'     => ')',  21, 1 ],
        [ '{'     => '{',  22, 1 ],
        [ '}'     => '}',  23, 1 ],
      ]
   ],
   [  'Strings',
      q{ "test" "" "line1\nline2\x20" "start\\}."\n".q{ end" "\0\012\""},
      [ [ string => 'test',           1,  6 ],
        [ string => '',               8,  2 ],
        [ string => "line1\nline2 ", 11, 18 ],
        [ string => "start end",     30, 13 ],
        [ string => "\0\n\"",        44, 10 ],
      ]
   ],
   [  'Comments', <<END,
 /* Test1 */  /** Test2 **//*
Test3
More3
/*/
test // foo /*
*/
END
      [ [ comment => ' Test1 ',  D, D ],
        [ comment => '* Test2 *', D, D ],
        [ comment => "\nTest3\nMore3\n/", D, D ],
        [ ident   => 'test', D, D ],
        [ comment => ' foo /*', D, D ],
        [ '*'     => '*', D, D ],
        [ '/'     => '/', D, D ],
      ]
   ],
   [ 'Parse errors str', q{"test},
      [ [ string => 'test', 0, 5, D ],
      ]
   ],
   [ 'Parse errors character', q{'fg'},
      [ [ char => 'f', 0, 2, D ],
        [ ident => 'g', 2, 1 ],
        [ unknown => "'", 3, 1, D ],
      ]
   ],
   [ 'Parse errors comment', qq{/* foo \n \n \n},
      [ [ comment => " foo \n \n \n", 0, D, D ],
      ]
   ],
) {
   my ($name, $code, $expected)= @$_;
   my @tokens;
   @tokens= CodeGen::Cpppp::CParser->tokenize($code);
   is( \@tokens, $expected, $name );
}

done_testing;

#!/usr/bin/env perl
# -*- Perl -*-
use warnings;
use Test::More;
use rlib '../lib';
use Test::More;

BEGIN {
    use_ok( Array::Columnize::columnize );
}

use Array::Columnize::columnize;

note( "Testing degenerate cases" );
is(Array::Columnize::columnize([]), "<empty>\n");
is( Array::Columnize::columnize(["oneitem"]), "oneitem\n");

note( "Testing horizontal placement" );
is(Array::Columnize::columnize(['1', '2', '3', '4'],
                               {displaywidth => 4, colsep => '  ', 
				arrange_vertical => 0}),
   "1  2\n3  4\n");

my @data = (0..54);
is(
    Array::Columnize::columnize(\@data, 
				{colsep => ', ', 
				 displaywidth => 39,
				 arrange_veritical => 0, 
				 ljust => 0}),
    "0,  6, 12, 18, 24, 30, 36, 42, 48, 54\n" .
    "1,  7, 13, 19, 25, 31, 37, 43, 49\n" .
    "2,  8, 14, 20, 26, 32, 38, 44, 50\n" .
    "3,  9, 15, 21, 27, 33, 39, 45, 51\n" .
    "4, 10, 16, 22, 28, 34, 40, 46, 52\n" .
    "5, 11, 17, 23, 29, 35, 41, 47, 53\n"
);
    
note( "Testing vertical placement" );
my $args = ['step', 'next', 'kill', 'quit'];
my $b = Array::Columnize::columnize($args);
is("step  next  kill  quit\n", $b);

is("1  3\n2  4\n", 
   Array::Columnize::columnize(['1', '2', '3', '4'], {displaywidth => 4}));

note( "Testing array formatting" );
@data = (1..30);
is(Array::Columnize::columnize(\@data,
			       {arrange_array => 1, ljust =>0, 
				displaywidth => 70}),
   "( 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15\n" .
   " 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30)\n");

# is(
#     " 0,  1,  2,  3,  4,  5,  6,  7,  8,  9\n" .
#     "10, 11, 12, 13, 14, 15, 16, 17, 18, 19\n" .
#     "20, 21, 22, 23, 24, 25, 26, 27, 28, 29\n" .
#     "30, 31, 32, 33, 34, 35, 36, 37, 38, 39\n" .
#     "40, 41, 42, 43, 44, 45, 46, 47, 48, 49\n" .
#     "50, 51, 52, 53, 54\n",
#     Array::Columnize::columnize(\@data, 
# 				{colsep => ', ', 
# 				 displaywidth => 39,
# 				 arrange_veritical => 0}));
    

# is(
#     "   0,  1,  2,  3,  4,  5,  6,  7,  8\n" +
#     "   9, 10, 11, 12, 13, 14, 15, 16, 17\n" +
#     "  18, 19, 20, 21, 22, 23, 24, 25, 26\n" +
#     "  27, 28, 29, 30, 31, 32, 33, 34, 35\n" +
#     "  36, 37, 38, 39, 40, 41, 42, 43, 44\n" +
#     "  45, 46, 47, 48, 49, 50, 51, 52, 53\n" +
#     "  54\n",
#     columnize(data, 39, ', ', false, false, '  '));

# $data = ["one",       "two",         "three",
# 	 "for",       "five",        "six",
# 	 "seven",     "eight",       "nine",
# 	 "ten",       "eleven",      "twelve",
# 	 "thirteen",  "fourteen",    "fifteen",
# 	 "sixteen",   "seventeen",   "eightteen",
# 	 "nineteen",  "twenty",      "twentyone",
# 	 "twentytwo", "twentythree", "twentyfour",
# 	 "twentyfive","twentysix",   "twentyseven"];

# is(
#     "one         two         three        for          five         six        \n" +
#     "seven       eight       nine         ten          eleven       twelve     \n" +
#     "thirteen    fourteen    fifteen      sixteen      seventeen    eightteen  \n" +
#     "nineteen    twenty      twentyone    twentytwo    twentythree  twentyfour \n" +
#     "twentyfive  twentysix   twentyseven\n", columnize(data, 80, '  ', false));

# is(
#     "one    five   nine    thirteen  seventeen  twentyone    twentyfive \n" +
#     "two    six    ten     fourteen  eightteen  twentytwo    twentysix  \n" +
#     "three  seven  eleven  fifteen   nineteen   twentythree  twentyseven\n" +
#     "for    eight  twelve  sixteen   twenty     twentyfour \n", columnize(data));

done_testing();

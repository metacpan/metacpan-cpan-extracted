#! /usr/bin/env perl
use Modern::Perl;
use Test::More;

my ($module, @methods);

BEGIN {
  $module = "Common::Routine";
  @methods = qw/max min sum mean median var sd trim
            ltrim rtrim ceil floor round format_number/;
  use_ok($module, @methods);
}


for my $method (@methods) {
  can_ok($module, $method);
}

my @list = 1..10;

is (max(@list), 10, "max");
is (min(@list), 1, "min");
is (sum(@list), 55, "sum");
is (mean(@list), 5.5, "mean");
is (median(@list), 5.5, "median");
is (sprintf("%.3f", var(@list)), 9.167, "var");
is (sprintf("%.3f", sd(@list)), 3.028, "sd");

my $str = "  abc  ";
is (trim($str), "abc", "trim");
is (ltrim($str), "abc  ", "ltrim");
is (rtrim($str), "  abc", "rtrim");

my $num = 3.56;
is (round($num), 4, "round");

#my $format_num = format_number($num, 1);
#$format_num =~s/,/\./;
#say $format_num . "#";
#cmp_ok ($format_num, "eq", '3.6', "format_number" );

done_testing;

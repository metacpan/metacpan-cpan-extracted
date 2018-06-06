#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../../lib';

use Test::More;
note( "Testing B::DeparseTree B::DeparseTree::Fragment" );

BEGIN {
use_ok( 'B::DeparseTree::Fragment' );
}

my ($parent_text, $pu, $child_text, $start_pos, $got, $expect);
$parent_text = "now is the time";
$child_text = 'is';
$start_pos = index($parent_text, $child_text);
$pu = underline_parent($child_text, $parent_text, '-');
$got  = trim_line_pair($parent_text, $child_text,
		       $pu, $start_pos);
is_deeply $got, ["now is the time",   "    --"];

$parent_text = "if (\$a) {\n\$b\n}";
$child_text = '$b';
$start_pos = index($parent_text, $child_text);
$pu = underline_parent($child_text, $parent_text, '-');
$got = trim_line_pair($parent_text, $child_text,
		      $pu, $start_pos);
is_deeply $got, ["if (\$a) {...", '$b', '--'];

$parent_text = "if (\$a) {\n  \$b;\n  \$c}";
$child_text = '$b';
$start_pos = index($parent_text, $child_text);
$pu = underline_parent($child_text, $parent_text, '-');
$got = trim_line_pair($parent_text, $child_text,
			    $pu, $start_pos);
is_deeply $got, ['if ($a) {...', '  $b;', '  --'];

$parent_text = "if (\$a) {\n  \$b;\n  \$c}";
$child_text = "\$b;\n  \$c";
$start_pos = index($parent_text, $child_text);
$pu = underline_parent($child_text, $parent_text, '-');
$got = trim_line_pair($parent_text, $child_text,
		      $pu, $start_pos);
is_deeply $got, ['if ($a) {...', '  $b;', '  --...'];

ok 1;

done_testing();

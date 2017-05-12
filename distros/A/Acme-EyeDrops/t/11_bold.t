#!/usr/bin/perl
# 11_bold.t (was vshape.t)
# This tests OK as taint-safe (i.e. with -Tw added to first line above).

use strict;
use Acme::EyeDrops qw(get_eye_string get_eye_shapes
                      get_builtin_shapes
                      make_triangle make_siertri
                      border_shape invert_shape reflect_shape
                      hjoin_shapes sightly
                      reduce_shape expand_shape rotate_shape);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------
# A valid shape should:
#  1) contain only ' ' '#' and "\n"
#  2) be left-justified
#  3) no line should contain trailing spaces
#  4) be properly newline-terminated
#  5) contain no leading or trailing newlines
# This test verifies that is the case for all .eye shapes
# and for all subroutines that generate shapes.
# --------------------------------------------------

my @eye_shapes = get_eye_shapes();
my $n_tests = @eye_shapes * 6 + 13 * 6;
$n_tests += 2;   # plus builtin shape tests

print "1..$n_tests\n";

my $itest = 0;

sub test_one_shape {
   my ($e, $s) = @_;
   $s =~ tr/ #\n//c and print "not ";
   ++$itest; print "ok $itest - $e valid chars\n";
   $s =~ /^#/m or print "not ";
   ++$itest; print "ok $itest - $e left justified\n";
   $s =~ / +$/m and print "not ";
   ++$itest; print "ok $itest - $e trailing spaces\n";
   substr($s, 0, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e leading blank lines\n";
   substr($s, -1, 1) eq "\n" or print "not ";
   ++$itest; print "ok $itest - $e trailing blank lines\n";
   substr($s, -2, 1) eq "\n" and print "not ";
   ++$itest; print "ok $itest - $e properly newline terminated\n";
}

for my $e (@eye_shapes) { test_one_shape($e, get_eye_string($e)) }
my $s = get_eye_string('camel');
test_one_shape('border_shape', border_shape($s, 1, 1, 1, 1, 1, 1, 1, 1));
test_one_shape('invert_shape', invert_shape($s));
test_one_shape('reflect_shape', reflect_shape($s));
test_one_shape('hjoin_shapes', hjoin_shapes(3, $s, $s));
test_one_shape('reduce_shape', reduce_shape($s, 1));
test_one_shape('expand_shape', expand_shape($s, 1));
test_one_shape('rotate_shape-90', rotate_shape($s, 90, 0, 0));
test_one_shape('rotate_shape-180', rotate_shape($s, 180, 0, 0));
test_one_shape('rotate_shape-270', rotate_shape($s, 270, 0, 0));
test_one_shape('make_triangle', make_triangle(71));
test_one_shape('make_triangle', make_triangle(2));
test_one_shape('make_siertri', make_siertri(5));

my $p = sightly( { SourceString  => "knob\n",
                   Print         => 1,
                   Regex         => 1,
                   Shape         => 'camel,mongers',
                   Gap           => 3 } );
$p =~ tr/!-~/#/;
test_one_shape('multiple_shapes', $p);

my @oldb = get_builtin_shapes();
@oldb == 5 or print "not ";
++$itest; print "ok $itest - get_builtin_shape n\n";
"@oldb" eq 'all banner siertri srcbanner triangle' or print "not ";
++$itest; print "ok $itest - get_builtin_shape v\n";

# Old tests -- add_builtin_shape/del_builtin_shape have been removed.

# add_builtin_shape('knobsiertri', sub { make_siertri($_[0]->{Width}) } );

# my @newb = get_builtin_shapes();
# @newb == 6 or print "not ";
# ++$itest; print "ok $itest - get_builtin_shape n\n";
# "@newb" eq 'all banner knobsiertri siertri srcbanner triangle' or print "not ";
# ++$itest; print "ok $itest - get_builtin_shape v\n";

# my $ksier = sightly( { SourceString  => "knob\n",
#                        Print         => 1,
#                        Regex         => 1,
#                        Shape         => 'knobsiertri',
#                        Gap           => 3 } );
# my $osier = sightly( { SourceString  => "knob\n",
#                        Print         => 1,
#                        Regex         => 1,
#                        Shape         => 'siertri',
#                        Gap           => 3 } );
# $ksier eq $osier or print "not ";
# ++$itest; print "ok $itest - siertr eq knobsiertri\n";

# del_builtin_shape('knobsiertri');
# @oldb = get_builtin_shapes();
# @oldb == 5 or print "not ";
# ++$itest; print "ok $itest - get_builtin_shape n\n";
# "@oldb" eq 'all banner siertri srcbanner triangle' or print "not ";
# ++$itest; print "ok $itest - get_builtin_shape v\n";

# -----------------------------------------------------------------------

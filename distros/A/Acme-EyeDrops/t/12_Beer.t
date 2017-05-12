#!/usr/bin/perl
# 12_Beer.t (was banner test in vshape.t)
# This test is not taint-safe (rest of vshape.t is, so separate this one)
# Test make_banner.

use strict;
use Acme::EyeDrops qw(make_banner);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

# make_banner is linux only (also requires /usr/games/banner executable)
my $have_banner = $^O eq 'linux' && -x '/usr/games/banner';

print "1..7\n";

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

sub skip_one_shape {
   my $e = shift;
   ++$itest; print "ok $itest # skip $e, valid chars\n";
   ++$itest; print "ok $itest # skip $e, left justified\n";
   ++$itest; print "ok $itest # skip $e, trailing spaces\n";
   ++$itest; print "ok $itest # skip $e, leading blank lines\n";
   ++$itest; print "ok $itest # skip $e, trailing blank lines\n";
   ++$itest; print "ok $itest # skip $e, properly newline terminated\n";
}

if ($have_banner) {
   test_one_shape('make_banner', make_banner(70, "a bc"));
} else {
   skip_one_shape('Linux /usr/games/banner not available');
}

# Test invalid /usr/games/banner
# XXX: Improve make_banner() interface to make testable.

my $b_exe = '/usr/games/banner';
if (-x $b_exe) {
   ++$itest; print "ok $itest # skip invalid banner exe (you have '$b_exe')\n";
} else {
   eval { make_banner(70, "a bc") };
   $@ =~ m|\Q'$b_exe'\E not available on this platform| or print "not ";
   ++$itest; print "ok $itest - invalid banner exe\n";
}

# -----------------------------------------------------------------------

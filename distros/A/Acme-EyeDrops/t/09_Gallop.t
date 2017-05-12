#!/usr/bin/perl
# 09_Gallop.t (was recur.t)

use strict;
use Acme::EyeDrops qw(sightly get_eye_string);

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

# --------------------------------------------------

sub build_file {
   my ($f, $d) = @_;
   local *F; open(F, '>'.$f) or die "open '$f': $!";
   print F $d or die "write '$f': $!"; close(F);
}

# --------------------------------------------------

# Fails with "Out of memory!" with perl 5.10.0: comment out tests 4-6 for now.
# print "1..6\n";
print "1..3\n";

my $hellostr = <<'HELLO';
print "hello world\n";
HELLO
my $camelstr = get_eye_string('camel');
$camelstr .= get_eye_string('window');
my $tmpf = 'bill.tmp';

# -------------------------------------------------

my $itest = 0;
my $prog;

# Run camel,window helloworld.pl on itself twice ---

$prog = sightly({ Shape         => 'camel,window',
                  SourceString  => $hellostr,
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);
my $progorig = $prog;
my $outstr = `$^X -w -Mstrict $tmpf`;
my $rc = $? >> 8;
$rc == 0 or print "not ";
++$itest; print "ok $itest - twice rc\n";
$outstr eq "hello world\n" or print "not ";
++$itest; print "ok $itest - twice output\n";
$prog =~ tr/!-~/#/;
$prog =~ s/^.+\n// if $] >= 5.017;   # remove leading use re 'eval' line
$prog eq $camelstr or print "not ";
++$itest; print "ok $itest - twice shape\n";

# Prior to Acme::EyeDrops v1.42, test 4 fails on Perl 5.8.1
# with the error: panic: pad_free curpad (Perl bug #23143).
# And you can make it fail again, by adding the attribute:
#   FillerVar  => [ '$_' ],
# to all sightly() calls in this test program.

$prog = sightly({ Shape         => 'camel,window',
                  SourceString  => $progorig,
                  InformHandler => sub {},
                  Regex         => 1 } );
build_file($tmpf, $prog);
# Fails with "Out of memory!" with perl 5.10.0: comment out tests 4-6 for now.
# $outstr = `$^X -w -Mstrict $tmpf`;
# $rc = $? >> 8;
# $rc == 0 or print "not ";
# ++$itest; print "ok $itest - twice rc\n";
# $outstr eq "hello world\n" or print "not ";
# ++$itest; print "ok $itest - twice output\n";
# my $teststr = $camelstr x 16;
# $prog =~ tr/!-~/#/;
# $prog eq $teststr or print "not ";
# ++$itest; print "ok $itest - twice shape\n";

# --------------------------------------------------

unlink($tmpf) or die "error: unlink '$tmpf': $!";

# --------------------------------------------------
# Original Perl bug report #23143 follows:
# The following program works under Perl 5.8.0 but fails under
# 5.8.1 with the error: "panic: pad_free curpad".
#
# ''=~m<(?{eval'print 4;$_=9'})>;($_)=9;
#
# If you change it to:
#
# ''=~m<(?{eval'print 4;$_=9'})>;$_=9;
#
# it works fine. Take out the eval:
#
# ''=~m<(?{print 4;$_=9})>;($_)=9;
#
# and it fails with "Modification of a read-only value attempted"
# on all Perl versions that I tested on. However, Perl 5.8.1
# then goes on to further fail with: "panic: pad_free curpad".
#
# BTW, the next two work fine on all versions that I tested:
#
# ''=~m<(?{print 4;local $_=9})>;($_)=9;
# ''=~m<(?{eval'print 4;local $_=9'})>;($_)=9;

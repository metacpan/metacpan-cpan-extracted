#!/usr/bin/perl -w -- -*- mode: cperl -*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use vars qw($loaded);

BEGIN {print "1..7\n";}
END {print "not ok 1\n" unless $loaded;}
use Convert::UU;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub bytometer ( $ ) {
    my($byte) = @_;
    my($result,$i) = "";
    for ($i=5;$i<=$byte;$i+=5) {
	if ( $i==5 || substr($i,-2) eq "05" && $i<10000 ) {
	    $result .=  join "", "\n", "." x (4-length($i)), $i;
	} elsif ( $i<=10000 ) {
	    $result .=  join "", "." x (5-length($i)), $i;
	} elsif ( substr($i,-2) eq "10" ) {
	    $result .=  join "", "\n", "." x (9-length($i)), $i;
	} elsif ( substr($i,-1) eq "0" ) {
	    $result .=  join "", "." x (10-length($i)), $i;
	}
    }
    $result .= "." x ($byte%5);
    $result;
}

use Convert::UU 'uuencode';

my $astring = bytometer(3000);
my $uu = uuencode($astring,"foo","644");
my $back = Convert::UU::uudecode($uu);
if ($astring eq $back){
    print "ok 2\n";
} else {
    print "not ok 2: astring[$astring] uu[$uu] back[$back]\n";
}

if (open F, "MANIFEST") {
  print "ok 3\n";
  binmode(*F);
} else {
  print "not ok 3\n";
}
undef $/;
$astring = <F>;
open F, "MANIFEST";
use Convert::UU 'uudecode';
if ($back = uudecode(uuencode(*F)) and $back eq $astring) {
    print "ok 4\n";
} else {
    print "not ok 4: astring[$astring] back[$back]\n";
}

$astring = [ "begin 644 foo\n",
	     '$9F]O"@``' . "\n",
	     "end\n" ];

if (($back=uudecode($astring)) =~ /^foo/) {
    print "ok 5\n";
} else {
    print "not ok 5: astring[$astring] back[$back]\n";
}

# Check if the last-line-backtick is silent with -w
{
#  $SIG{__WARN__} = sub { die };
  print uudecode(qq{begin 444 bla
M,\"\`Q.3DV\"\@IO<FEG:6YA;\"!V97)S:6\]N.R!C<F5A=&5D(&)Y\(&\@R>\',\@,2XQ
\#-\@H*
\`
end
}
) ? "ok 6\n" : "not ok 6\n";
}

# Neuralgic file with a 0\n in line 24
my $badzero = "0\n" x 24;
my $badzero_uu = uuencode($badzero);
$back = uudecode($badzero_uu);
my $back2 = uudecode(qq{begin 644 ttt2
M,\`HP\"C\`*,\`HP\"C\`*,\`HP\"C\`*,\`HP\"C\`*,\`HP\"C\`*,\`HP\"C\`*,\`HP\"C\`*,\`HP
\#\"C\`*
\`
end
});
print $back2 eq $back ?  "ok 7\n" : "#back[$back]back2[$back2]\nnot ok 7\n";


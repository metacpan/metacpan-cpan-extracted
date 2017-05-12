#!/usr/bin/perl

use strict;
use warnings;

# I would like more tests, but contents change over every perl version
use Test::More tests => 6;
use Test::NoWarnings;

use Data::Peek;

$Data::Peek::has_perlio = $Data::Peek::has_perlio = 0;

ok (1, "DDump () NOT using PerlIO");

my @tests;
{   local $/ = "==\n";
    chomp (@tests = <DATA>);
    }

# Determine what newlines this perl generates in sv_peek
my @nl = ("\\n") x 2;

my $var = "";

foreach my $test (@tests) {
    my ($in, $expect) = split m/\n--\n/ => $test;
    $in eq "" and next;
    SKIP: {
	eval "\$var = $in;";
	my $dump = DDump ($var);

	if ($in =~ m/20ac/) {
	    if ($] < 5.008) {
		skip "No UTF8 in ancient perl", 1;
		}
	    else {
		@nl = ($dump =~ m/PV = 0x\w+ "([^"]+)".*"([^"]+)"/);
		diag "# This perl dumps \\n as (@nl)";
		# Catch differences in \n
		$dump =~ s/"ab\Q$nl[0]\E(.*?)"ab\Q$nl[1]\E/"ab\\n$1"ab\\n/g;
		}
	    }

	$dump =~ s/\b0x[0-9a-f]+\b/0x****/g;
	$dump =~ s/\b(REFCNT =) [0-9]{4,}/$1 -1/g;

	$dump =~ s/\bLEN = (?:[1-9]|1[0-6])\b/LEN = 8/g; # aligned at long long?

	$dump =~ s/\bPADBUSY\b,?//g	if $] < 5.010;

	$dump =~ s/\bUV = /IV = /g	if $] < 5.008;
	$dump =~ s/,?\bIsUV\b//g	if $] < 5.008;

	my @expect = split m/(?<=\n)\|(?:\s*#.*)?\n+/ => $expect;

	$in   =~ s/[\s\n]+/ /g;

	my @match = grep { $dump eq $_ } @expect;
	if (@match == 1) {
	    is ($dump, $match[0], "DDump ($in)");
	    }
	else {
	    my $match = shift @expect;
	    is ($dump, $match, "DDump ($in)");
	    diag ("DDump ($in) neither matches\n$_") for @expect;
	    }
	}
    }

1;

__END__
undef
--
SV = PV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY)
  PV = 0x**** ""\0
  CUR = 0
  LEN = 8
| # as of 5.19.3
SV = PV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY)
  PV = 0
| # as of 5.21.5
SV = PV(0x****) at 0x****
  REFCNT = 1
  FLAGS = ()
  PV = 0
==
0
--
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,IOK,pIOK)
  IV = 0
  PV = 0x**** ""\0
  CUR = 0
  LEN = 8
| # as of 5.19.3
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,IOK,pIOK)
  IV = 0
  PV = 0
| # as of 5.21.5
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (IOK,pIOK)
  IV = 0
  PV = 0
==
1
--
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,IOK,pIOK)
  IV = 1
  PV = 0x**** ""\0
  CUR = 0
  LEN = 8
| # as of 5.19.3
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,IOK,pIOK)
  IV = 1
  PV = 0
| # as of 5.21.5
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (IOK,pIOK)
  IV = 1
  PV = 0
==
""
--
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,POK,pPOK)
  IV = 1
  PV = 0x**** ""\0
  CUR = 0
  LEN = 8
| # as of 5.19.3
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (PADMY,POK,IsCOW,pPOK)
  IV = 1
  PV = 0x**** ""\0
  CUR = 0
  LEN = 8
  COW_REFCNT = 0
| # as of 5.21.5
SV = PVIV(0x****) at 0x****
  REFCNT = 1
  FLAGS = (POK,IsCOW,pPOK)
  IV = 1
  PV = 0x**** ""\0
  CUR = 0
  LEN = 8
  COW_REFCNT = 0

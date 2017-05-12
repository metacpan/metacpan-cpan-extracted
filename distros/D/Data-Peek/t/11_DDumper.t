#!/usr/bin/perl

use strict;
use warnings;

my $ntests;
BEGIN { $ntests = 33 };

use Test::More tests => $ntests;
#se Test::NoWarnings;

BEGIN {
    eval q{use Perl::Tidy};
    # Version is also checked in Peek.pm
    if ($@ || $Perl::Tidy::VERSION <= 20120714) {
	diag "A usable Perl::Tidy is not available";
	ok (1) for 1..$ntests;
	exit 0;
	}
    use_ok ("Data::Peek", ":tidy");
    die "Cannot load Data::Peek\n" if $@;
    }

my ($dump, $var) = ("", "");
while (<DATA>) {
    chomp;
    my ($v, $exp, $re) = split m/\t+ */;

    if ($v eq "--") {
	ok (1, "** $exp");
	next;
	}

    $v =~ s/^S:([^:]*):// and DDsort ($1), $v =~ m/^()/; # And reset $1 for below

    unless ($v eq "") {
	eval "\$var = $v";
	ok ($dump = DDumper ($var),	"DDumper ($v)");
	$dump =~ s/\A\$VAR1 = //;
	$dump =~ s/;?\n\Z//;
	}
    if ($re) {
	like ($dump, qr{$exp}ms,	".. content $re");
	$1 and diag "# '$1' (", length ($1), ")\n";
	}
    else {
	is   ($dump,    $exp,		".. content");
	}
    }
unlink "perltidy.LOG", "perltidy.ERR";

1;

__END__
--	Basic values
undef				undef
1				1
""				''
"\xa8"				'¨'
1.24				'1.24'
\undef				\undef
\1				\1
\""				\''
\"\xa8"				\'¨'
(0, 1)				1
\(0, 1)				\1
--	Structures
[0]				\A\[\s*0\s*]\s*\Z			tidy array 1
[0, 1]				\A\[\s*0\s*,\s*1\s*]\s*\Z		tidy array 2
[0,1,2]				\A\[\s*0\s*,\s*1\s*,\s*2\s*]\s*\Z	tidy array 3
[[0],{foo=>1}]			\A\[\s*\[\s*0\s*]\s*,\s*\{\s*'foo'\s*=>\s*1\s*}\s*]\s*\Z	structure

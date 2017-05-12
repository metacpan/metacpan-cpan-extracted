#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 55;
use Test::NoWarnings;

BEGIN {
    use_ok "Data::Peek";
    die "Cannot load Data::Peek\n" if $@;	# BAIL_OUT not avail in old Test::More
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
[0, 1]				^\[   0,\n				line 1
				^    1\n				line 2
				^    ]\Z				line 3
[0,1,2]				\A\[\s+0,\n\s+1,\n\s+2\n\s+]\Z		line splitting
--	Indentation
[0]				\A\[   0\n    ]\Z			single indent
[[0],{foo=>1}]			^\[\n					outer list
				^ {4}\[   0\n {8}],\n {4}		inner list
				^ {4}\{   foo {14}=> 1\n {8}}\n		inner hash
				^ {4}]\Z				outer list end
[[0],{foo=>1}]			\A\[\n {4}\[   0\n {8}],\n {4}\{   foo {14}=> 1\n {8}}\n {4}]\Z	full struct
--	Sorting
S:1:{ab=>1,bc=>2,cd=>3,de=>13}	ab.*bc.*cd.*de	default sort
S:R:{ab=>1,bc=>2,cd=>3,de=>13}	de.*cd.*bc.*ab	reverse sort
S:V:{ab=>1,bc=>2,cd=>3,de=>13}	1.*13.*2.*3	sort by value
S:VR:{ab=>1,bc=>2,cd=>3,de=>13}	3.*2.*13.*1	reverse sort by value
S:VN:{ab=>1,bc=>2,cd=>3,de=>13}	1.*2.*3.*13	sort by value numeric
S:VNR:{ab=>1,bc=>2,cd=>3,d=>13}	13.*3.*2.*1	reverse sort by value numeric

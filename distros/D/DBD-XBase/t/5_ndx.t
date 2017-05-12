#!/usr/bin/perl -w

use strict;

BEGIN   { $| = 1; print "1..12\n"; }
END     { print "not ok 1\n" unless $::XBaseloaded; }

$| = 1;

print "Load the module: use XBase\n";
use XBase;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;        # We want to see any problems


print "Open table $dir/ndx-char\n";
my $table = new XBase "$dir/ndx-char" or do
	{
	print XBase->errstr, "not ok 2\n";
	exit
	};
print "ok 2\n";


print "prepare_select_with_index\n";
my $cur = $table->prepare_select_with_index("$dir/ndx-char.ndx") or
	print $table->errstr, 'not ';
print "ok 3\n";


my $result = '';
print "Fetch all data\n";
while (my @data = $cur->fetch)
	{ $result .= "@data\n"; }

my $expected_result = '';
my $line;
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 4\n";


print "find_eq('6g') and fetch\n";
$cur->find_eq('6g');
$result = ''; $expected_result = '';
while (my @data = $cur->fetch())
	{ $result .= "@data\n"; }
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 5\n";

print "find_eq('6e') and fetch (it doesn't exist, so the result should be the same)\n";
$cur->find_eq('6e');
$result = '';
while (my @data = $cur->fetch())
	{ $result .= "@data\n"; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 6\n";

print "Before we look at the numeric and data index files, let's check
if it makes sense (because of the way we implement double floats ;-)\n";

my $doubleoneseven = pack 'd', 1.7;
my $okoneseven = '3ffb333333333333';

if (join('', unpack 'H16', $doubleoneseven) ne $okoneseven
	and join('', unpack 'H16', reverse($doubleoneseven)) ne $okoneseven)
	{
	print "Number 1.7 encoded as natural double on your machine gives ",
		join('', unpack 'H16', $doubleoneseven),
		",\nwhich is not what I would expect.\n";
	print STDERR <<EOF;

	The following tests will probably fail because your machine
	encodes double numbers differently than XBase::Index expects.
	If they do, you can still use XBase and DBD::XBase. Send me
	perl -V and make test TEST_VERBOSE=1 and I will see what we
	could do about it.
EOF
	}
else
	{ print "Looks good.\n"; }


print "Open ndx-num and index\n";
$table = new XBase "$dir/ndx-num.dbf" or print XBase->errstr, 'not ';
print "ok 7\n";
$cur = $table->prepare_select_with_index("$dir/ndx-num.ndx") or
					print $table->errstr, 'not ';
print "ok 8\n";

print "find_eq(1042) and fetch results\n";
$cur->find_eq(1042);
$result = ''; $expected_result = '';
while (my @data = $cur->fetch())
	{ last if $data[0] != 1042; $result .= "@data\n"; }
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 9\n";


print "Open ndx-date and index\n";
$table = new XBase "$dir/ndx-date.dbf" or print XBase->errstr, 'not ';
print "ok 10\n";
$cur = $table->prepare_select_with_index("$dir/ndx-date.ndx") or
					print $table->errstr, 'not ';
print "ok 11\n";

print "find_eq(2450795), which is Julian date for 1997/12/12 and fetch results\n";

### use Data::Dumper;
### print Dumper $cur;

$cur->find_eq(2450795);

### print Dumper $cur;

$result = ''; $expected_result = '';
while (my @data = $cur->fetch())
	{ $result .= "@data\n"; }
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 12\n";



__END__
1
1
10
10
15
1z
2
2
2h
2z
3
3
3a
4
4
4e
5
5
5b
6
6
6g
7
7
8
8
8d
9
__END_DATA__
6g
7
7
8
8
8d
9
__END_DATA__
1042
1042
1042
1042
1042
1042
__END_DATA__
19971212
19971212
19971212
19971213
19971213
19971213
19971214
19971214
19971214
19971215
19971215
19971215
19971216
19971216
19971216
__END_DATA__

#!/usr/bin/perl
# 00_Coffee.t (was convert.t)

# Test ascii_to_sightly() and sightly_to_ascii().

use strict;
use Acme::EyeDrops qw(ascii_to_sightly sightly_to_ascii);

$|=1;

# XXX: The print "not " hack used below does not work on VMS apparently
# (for some odd reason, I think it prints a newline after the "not ")

print "1..10\n";

my $t1 = 'abcdefghijklmnopqrstuvwxyz';
my $f1 = ascii_to_sightly($t1);
# There are 32 characters in the sightly character set, namely:
# 33-47 (15), 58-64 (7), 91-96 (6), 123-126 (4).
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 1\n";

my $t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 2\n";

$t1 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 3\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 4\n";

$t1 = '0123456789';
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 5\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 6\n";

$t1 = "\n";
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 7\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 8\n";

$t1 = join("", map(chr, 0..255));
$f1 = ascii_to_sightly($t1);
$f1 =~ /[^!"#\$%&'()*+,\-.\/:;<=>?\@\[\\\]^_`\{|\}~]/ and print "not ";
print "ok 9\n";

$t1a = sightly_to_ascii($f1);
$t1 eq $t1a or print "not ";
print "ok 10\n";

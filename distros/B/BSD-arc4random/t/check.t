# $MirOS: contrib/hosted/tg/code/BSD::arc4random/t/check.t,v 1.4 2011/06/05 23:12:09 tg Exp $
#-
# Copyright (c) 2008, 2011
#	Thorsten Glaser <tg@mirbsd.org>
#
# Provided that these terms and disclaimer and all copyright notices
# are retained or reproduced in an accompanying document, permission
# is granted to deal in this work without restriction, including un-
# limited rights to use, publicly perform, distribute, sell, modify,
# merge, give away, or sublicence.
#
# This work is provided "AS IS" and WITHOUT WARRANTY of any kind, to
# the utmost extent permitted by applicable law, neither express nor
# implied; without malicious intent or gross negligence. In no event
# may a licensor, author or contributor be held liable for indirect,
# direct, other damage, loss, or other issues arising in any way out
# of dealing in the work, even if advised of the possibility of such
# damage or existence of a defect, except proven that it results out
# of said person's immediate fault when using the work as intended.

print "1..23\n";

use BSD::arc4random qw(:all);

my $enta = $RANDOM;
my $entb = $RANDOM;

# $RANDOM must output numerics
print "not " unless $enta =~ /^[0-9]+$/;
print "ok 1\n";

print "not " unless $entb =~ /^[0-9]+$/;
print "ok 2\n";

# $RANDOM output must be inside [0; 32767]
print "not " if (($enta < 0) || ($enta > 32767));
print "ok 3\n";

print "not " if (($entb < 0) || ($entb > 32767));
print "ok 4\n";

# $RANDOM output should differ each time
print "not " if ($enta == $entb);
print "ok 5\n";

# Check exported variables
my $v = ${BSD::arc4random::VERSION};
my $k = BSD::arc4random::have_kintf();
print "not " unless (($v =~ /^[0-9]+.[0-9]+$/) && (($k == 0) || ($k == 1)));
print "ok 6\n";
print STDERR "DIAG: BSD::arc4random $v with";
print STDERR "out" if $k == 0;
print STDERR " kernel interface\n";

# test storing to the tied variable
$RANDOM = 123;
$enta = $RANDOM;
$RANDOM = 456;
$entb = $RANDOM;
print "not " unless $enta =~ /^[0-9]+$/;
print "ok 7\n";
print "not " unless $entb =~ /^[0-9]+$/;
print "ok 8\n";
print "not " if (($enta < 0) || ($enta > 32767));
print "ok 9\n";
print "not " if (($entb < 0) || ($entb > 32767));
print "ok 10\n";
print "not " if ($enta == $entb);
print "ok 11\n";
print "not " if (($enta == 123) && ($entb == 456));
print "ok 12\n";

sub timed_out {
	die "GOT TIRED OF WAITING";
}
$SIG{ALRM} = \&timed_out;
eval {
	alarm(10);

	# test arc4random_uniform lower half
	$enta = arc4random_uniform(10000);
	$entb = arc4random_uniform(10000);
	print "not " unless $enta =~ /^[0-9]+$/;
	print "ok 13\n";
	print "not " unless $entb =~ /^[0-9]+$/;
	print "ok 14\n";
	print "not " if (($enta < 0) || ($enta > 9999));
	print "ok 15\n";
	print "not " if (($entb < 0) || ($entb > 9999));
	print "ok 16\n";
	print "not " if ($enta == $entb);
	print "ok 17\n";
	# test arc4random_uniform upper half
	$enta = arc4random_uniform(2999999901);
	$entb = arc4random_uniform(2999999901);
	print "not " unless $enta =~ /^[0-9]+$/;
	print "ok 18\n";
	print "not " unless $entb =~ /^[0-9]+$/;
	print "ok 19\n";
	print "not " if (($enta < 0) || ($enta > 2999999900));
	print "ok 20\n";
	print "not " if (($entb < 0) || ($entb > 2999999900));
	print "ok 21\n";
	print "not " if ($enta == $entb);
	print "ok 22\n";

	alarm(0);
};
if ($@ =~ /GOT TIRED OF WAITING/) {
	print STDERR "DIAG: 10 second timeout on execution reached\n";
	print STDERR "DIAG: this is probably a bug wrt. use64bitint\n";
	print "not ok 23\n";
} else {
	print "ok 23\n";
}

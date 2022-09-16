use warnings;
use strict;

use Test::More tests => 3*3;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

sub x {}
our($oref, $aref, $bref);
foreach(
	\&x,
	sub{},
	sub { my $x; sub{$x} }->(),
) {
	$oref = $_;
	$aref = $bref = undef;
	eval q{
		use Lexical::Sub foo => $oref;
		$aref = \&foo;
		$bref = \&foo;
	};
	is $@, "";
	ok $aref == $oref;
	ok $bref == $oref;
}

1;

use v5.14;
use strict;
use warnings;

use File::Temp qw/tempdir/;
use Test::More tests => 5;
BEGIN { use_ok('Apache2::AuthzCaps', qw/setcap hascaps/) };

$Apache2::AuthzCaps::rootdir = tempdir CLEANUP => 1;

sub checkcaps{
	my ($user, $testname, @caps) = @_;
	ok hascaps ($user, @caps), $testname
}

sub checknocaps{
	my ($user, $testname, @caps) = @_;
	ok !(hascaps $user, @caps), $testname
}

setcap marius => dostuff => 1;
checkcaps marius => 'Set cap and check it', qw/dostuff/;
checknocaps marius => 'Check an inexistent cap', qw/dootherstuff/;

setcap marius => goaway => 1;
checkcaps marius => 'Check multiple caps', qw/dostuff goaway/;
setcap marius => goaway => 0;
checknocaps marius => 'Remove cap', qw/dostuff goaway/;

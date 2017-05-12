#!/usr/bin/perl -I. -w

use Cisco::Reconfig;
use Test;
use Carp qw(verbose);
use Scalar::Util qw(weaken);

my $debugdump = 0;

if ($debugdump) {
	$Cisco::Reconfig::nonext = 1;
}

BEGIN { plan test => 2 };

sub wok
{
	my ($a, $b) = @_;
	require File::Slurp;
	import File::Slurp;
	write_file('x', $a);
	write_file('y', $b);
	return ok($a,$b);
}

my $config = readconfig(\*DATA);

if ($debugdump) {
	require File::Slurp;
	require Data::Dumper;
	import File::Slurp;
	import Data::Dumper;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Indent = 1;
	$Data::Dumper::Indent = 1;
	write_file("dumped", Dumper($config));
	exit(0);
}

ok(defined $config);

# -----------------------------------------------------------------

$x = $config->get('a b c');
#print "X=$x.\n";
ok($x,<<END);
a b c d
a b c e
END


# -----------------------------------------------------------------
# -----------------------------------------------------------------


__DATA__
a b c d
a b c e

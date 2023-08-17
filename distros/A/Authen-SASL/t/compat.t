#!perl

# Test of the methods marked "Compat" in Authen::SASL
# Heavily based on the compat_pl script at the root level
# (which this essentially replaces)

use strict;
use warnings;

use Test::More tests => 8;

use Authen::SASL;

my $sasl = Authen::SASL->new('CRAM-MD5', password => 'fred');

$sasl->user('foo');
is ($sasl->user('gbarr'), 'foo', 'user method returns previous value');
is ($sasl->user, 'gbarr', 'user method with no args returns value');

my $initial = $sasl->initial;
is ($initial, '', 'initial method returns empty string');
my $mech = $sasl->name;
is ($mech, 'CRAM-MD5', 'mech method returns mechanism');

#print "$mech;", unpack("H*",$initial),";\n";

#print unpack "H*", $sasl->challenge('xyz');
is ((unpack "H*", $sasl->challenge('xyz')),
  '6762617272203336633933316665343766336665396337616462663831306233633763346164',
  "$mech challenge matches");

$sasl = Authen::SASL->new(mech => 'CRAM-MD5', password => 'fred');
$mech = $sasl->name;
is ($mech, 'CRAM-MD5', 'constructor allows "mech" as first key');

$sasl = Authen::SASL->new(foo => 'CRAM-MD5', password => 'fred');
$mech = $sasl->name;
is ($mech, undef, 'constructor with no mechanism at all');

is ($sasl->error, undef, 'no errors');

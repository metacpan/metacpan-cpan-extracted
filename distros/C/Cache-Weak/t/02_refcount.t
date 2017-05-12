#
# $Id$

use strict;

use Test::More tests => 2;

eval {
	use Devel::Peek qw(SvREFCNT);
};

plan skip_all => "Devel::Peek required for refcount test" if $@;

use Cache::Weak;
my $cache = Cache::Weak->new();
my $data = { 'foo' => 'bar' };
my $initial_refcount = SvREFCNT($data);

$cache->set("test", $data);

is($initial_refcount, SvREFCNT($data), "refcount is unchanged");

my $copy = \$data;

isnt($initial_refcount, SvREFCNT($data), "refcount is changed");

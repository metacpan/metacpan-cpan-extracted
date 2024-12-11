# -*- perl -*-
use lib qw(t lib);
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 5; 
    use_ok('Test::HAProxy');
}

my $hp1 = new Test::HAProxy;
isa_ok($hp1,'Config::Proxy::Impl::haproxy');

# First, look for 'mysection' with default settings.  It is treated as
# a statement, and a statement at top level of a haproxy configuration
# file is not allowed.  Thus, an empty set is returned.
is_deeply([$hp1->select(name => 'mysection')],[],'Not found');

# Now, declare 'mysection' as a section, and parse the same configuration
# again.
Test::HAProxy->declare_section('mysection');
my $hp2 = new Test::HAProxy;
isa_ok($hp2,'Config::Proxy::Impl::haproxy');

# Looking for 'mysection' now should return its subtree.
my ($value) = map {
    map { $_->arg(0) } $_->select(name => 'stmt1')
} $hp2->select(name => 'mysection');
is($value, "value1", 'Found');

__DATA__
global
# comment
    log /dev/log daemon
    user haproxy
    group haproxy
mysection
    stmt1 value1
    stmt2 value2

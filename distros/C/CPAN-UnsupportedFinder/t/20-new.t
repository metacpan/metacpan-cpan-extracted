#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 9;

BEGIN { use_ok('CPAN::UnsupportedFinder') }

isa_ok(CPAN::UnsupportedFinder->new(), 'CPAN::UnsupportedFinder', 'Creating CPAN::UnsupportedFinder object');
isa_ok(CPAN::UnsupportedFinder::new(), 'CPAN::UnsupportedFinder', 'Creating CPAN::UnsupportedFinder object');
isa_ok(CPAN::UnsupportedFinder->new()->new(), 'CPAN::UnsupportedFinder', 'Cloning CPAN::UnsupportedFinder object');
# ok(!defined(CPAN::UnsupportedFinder::new()));

# Create a new object with direct key-value pairs
my $obj = CPAN::UnsupportedFinder->new(api_url => 'http://example.com');
cmp_ok($obj->{'cpan_testers'}, 'eq', 'https://api.cpantesters.org/api/v1', 'clone adds new args');
cmp_ok($obj->{'api_url'}, 'eq', 'http://example.com', 'direct key-value pairs');

# Test cloning behaviour by calling new() on an existing object
my $obj2 = $obj->new({ cpan_testers => 'https://www.google.com' });
cmp_ok($obj2->{'api_url'}, 'eq', 'http://example.com', 'clone keeps old args');
cmp_ok($obj2->{'cpan_testers'}, 'eq', 'https://www.google.com', 'clone adds new args');

# Invalid argument
ok(!defined(CPAN::UnsupportedFinder->new('foo')));

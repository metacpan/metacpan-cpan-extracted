use strict;
use Test::More 0.98;
use Data::TOON;
use JSON::PP;

# Test 1: Nested object encoding
{
    my $data = {
        user => {
            id => 123,
            name => 'Ada'
        }
    };
    
    my $toon = Data::TOON->encode($data);
    ok($toon, 'encode() with nested object returns string');
    like($toon, qr/user:/, 'encoded TOON contains parent key');
    like($toon, qr/id:/, 'encoded TOON contains nested id');
}

# Test 2: Deep nested object encoding
{
    my $data = {
        user => {
            id => 123,
            name => 'Ada',
            address => {
                street => '123 Main St',
                city => 'Portland'
            }
        }
    };
    
    my $toon = Data::TOON->encode($data);
    ok($toon, 'encode() with deep nesting returns string');
    like($toon, qr/address:/, 'encoded TOON contains nested address');
}

# Test 3: Nested object decoding
{
    my $toon_text = <<'TOON';
user:
  id: 123
  name: Ada
TOON
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode() with nested object returns data');
    is(ref $data->{user}, 'HASH', 'user is a hash');
    is($data->{user}->{id}, 123, 'nested id is correct');
    is($data->{user}->{name}, 'Ada', 'nested name is correct');
}

# Test 4: Deep nested object decoding
{
    my $toon_text = <<'TOON';
user:
  id: 123
  name: Ada
  address:
    street: 123 Main St
    city: Portland
TOON
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode() with deep nesting returns data');
    is(ref $data->{user}, 'HASH', 'user is a hash');
    is(ref $data->{user}->{address}, 'HASH', 'address is a hash');
    is($data->{user}->{address}->{street}, '123 Main St', 'deeply nested street is correct');
    is($data->{user}->{address}->{city}, 'Portland', 'deeply nested city is correct');
}

# Test 5: Mixed nested and simple fields
{
    my $data = {
        id => 1,
        name => 'Alice',
        profile => {
            age => 30,
            email => 'alice@example.com'
        },
        active => 1
    };
    
    my $encoded = Data::TOON->encode($data);
    my $decoded = Data::TOON->decode($encoded);
    
    is($decoded->{id}, 1, 'simple field preserved');
    is(ref $decoded->{profile}, 'HASH', 'nested profile is hash');
    is($decoded->{profile}->{age}, 30, 'nested age preserved');
    is($decoded->{active}, 1, 'field after nested object preserved');
}

done_testing;

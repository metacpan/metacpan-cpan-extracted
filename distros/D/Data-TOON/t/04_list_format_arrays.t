use strict;
use Test::More 0.98;
use Data::TOON;

# Test 1: List format with objects
{
    my $toon_text = <<'TOON';
items[2]:
  - id: 1
    name: First
  - id: 2
    name: Second
TOON
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode() list format returns data');
    is(ref $data->{items}, 'ARRAY', 'items is an array');
    is(scalar @{$data->{items}}, 2, 'items array has 2 elements');
    is($data->{items}->[0]->{id}, 1, 'first item id is correct');
    is($data->{items}->[0]->{name}, 'First', 'first item name is correct');
}

# Test 2: List format with primitives
{
    my $toon_text = <<'TOON';
tags[3]:
  - admin
  - user
  - guest
TOON
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode() list format primitives returns data');
    is(ref $data->{tags}, 'ARRAY', 'tags is an array');
    is(scalar @{$data->{tags}}, 3, 'tags array has 3 elements');
    is($data->{tags}->[0], 'admin', 'first tag is correct');
}

# Test 3: Encoding with list format (mixed objects)
{
    my $data = {
        items => [
            { id => 1, name => 'First' },
            { id => 2, name => 'Second' }
        ]
    };
    
    my $encoded = Data::TOON->encode($data);
    ok($encoded, 'encode() mixed objects returns string');
    # Should produce either tabular or list format
    like($encoded, qr/items\[2\]/, 'encoded contains array header');
}

done_testing;

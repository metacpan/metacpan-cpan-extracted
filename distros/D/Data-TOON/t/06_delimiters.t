use strict;
use Test::More 0.98;
use Data::TOON;
use Data::Dumper;

# Test 1: Tab delimiter with tabular format
{
    my $tab = "\t";
    my $toon_text = "items[2$tab]{id${tab}name}:\n  1${tab}Alice\n  2${tab}Bob\n";
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode with tab delimiter');
    is(scalar @{$data->{items}}, 2, 'correct number of items');
    is($data->{items}->[0]->{id}, 1, 'first item id');
    is($data->{items}->[0]->{name}, 'Alice', 'first item name');
    is($data->{items}->[1]->{name}, 'Bob', 'second item name');
}

# Test 2: Pipe delimiter with tabular format
{
    my $toon_text = "items[2|]{id|name}:\n  1|Alice\n  2|Bob\n";
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode with pipe delimiter');
    is(scalar @{$data->{items}}, 2, 'correct number of items');
    is($data->{items}->[0]->{name}, 'Alice', 'pipe: first item name');
}

# Test 3: Tab delimiter with primitive array
{
    my $toon_text = 'tags[3	]: a	b	c';
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode tab-delimited primitive array');
    is(scalar @{$data->{tags}}, 3, 'correct number of tags');
    is($data->{tags}->[0], 'a', 'first tag');
}

# Test 4: Pipe delimiter with primitive array
{
    my $toon_text = 'tags[3|]: a|b|c';
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode pipe-delimited primitive array');
    is(scalar @{$data->{tags}}, 3, 'correct number of tags');
    is($data->{tags}->[1], 'b', 'second tag');
}

# Test 5: Tab delimiter round-trip encode/decode
{
    my $data = {
        records => [
            { field1 => 'value1', field2 => 'value2' },
            { field1 => 'value3', field2 => 'value4' }
        ]
    };
    
    my $encoder = Data::TOON::Encoder->new(delimiter => "\t");
    my $encoded = $encoder->encode($data);
    my $decoded = Data::TOON->decode($encoded);
    
    is_deeply($decoded, $data, 'tab round-trip preserves data');
}

# Test 6: Pipe delimiter round-trip
{
    my $data = {
        records => [
            { field1 => 'value1', field2 => 'value2' },
            { field1 => 'value3', field2 => 'value4' }
        ]
    };
    
    my $encoder = Data::TOON::Encoder->new(delimiter => '|');
    my $encoded = $encoder->encode($data);
    my $decoded = Data::TOON->decode($encoded);
    
    is_deeply($decoded, $data, 'pipe round-trip preserves data');
}

# Test 7: Delimiter with comma in values (should be quoted)
{
    my $data = {
        items => [
            { desc => 'hello,world', id => 1 },
            { desc => 'foo,bar', id => 2 }
        ]
    };
    
    my $encoder = Data::TOON::Encoder->new(delimiter => '|');
    my $encoded = $encoder->encode($data);
    my $decoded = Data::TOON->decode($encoded);
    
    is($decoded->{items}->[0]->{desc}, 'hello,world', 'comma in value with pipe delimiter');
}

done_testing;

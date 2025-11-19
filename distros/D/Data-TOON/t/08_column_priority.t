use strict;
use Test::More 0.98;
use Data::TOON;

# Test 1: Column priority in tabular format
{
    my $data = {
        users => [
            { id => 1, name => 'Alice', role => 'admin' },
            { id => 2, name => 'Bob', role => 'user' }
        ]
    };
    
    my $toon = Data::TOON->encode($data, column_priority => ['id', 'name', 'role']);
    
    like($toon, qr/users\[2\]\{id,name,role\}:/, 'tabular format with correct column order');
    like($toon, qr/^\s+1,Alice,admin/m, 'first row values in correct order');
    like($toon, qr/^\s+2,Bob,user/m, 'second row values in correct order');
}

# Test 2: Partial column priority (some columns specified)
{
    my $data = {
        products => [
            { id => 1, name => 'Widget', price => 9.99, stock => 100 },
            { id => 2, name => 'Gadget', price => 19.99, stock => 50 }
        ]
    };
    
    my $toon = Data::TOON->encode($data, column_priority => ['name', 'id']);
    
    # Should have name first, then id, then remaining columns alphabetically (price, stock)
    like($toon, qr/products\[2\]\{name,id,/, 'partial priority: priority columns first');
    like($toon, qr/\{name,id,price,stock\}/, 'remaining columns sorted alphabetically');
}

# Test 3: Column priority in list format
{
    my $data = {
        items => [
            { id => 1, name => 'Item1', extra => 'data1' },
            { id => 2, name => 'Item2' }
        ]
    };
    
    my $toon = Data::TOON->encode($data, column_priority => ['name', 'id']);
    
    # In list format, first field should be from priority list
    like($toon, qr/- name: Item1/, 'list format respects column priority');
    like($toon, qr/- name: Item2/, 'list format respects column priority for all items');
}

# Test 4: Columns in priority that don't exist
{
    my $data = {
        users => [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' }
        ]
    };
    
    # Priority specifies non-existent columns, shouldn't break
    my $toon = Data::TOON->encode($data, column_priority => ['name', 'missing_col', 'id']);
    
    like($toon, qr/\{name,id\}/, 'non-existent priority columns ignored');
    like($toon, qr/^\s+Alice,1/m, 'values correct despite non-existent column in priority');
}

# Test 5: Empty priority list (should behave like default)
{
    my $data = {
        users => [
            { zebra => 'z', apple => 'a', middle => 'm' }
        ]
    };
    
    my $toon = Data::TOON->encode($data, column_priority => []);
    
    # Should fall back to alphabetical sort
    like($toon, qr/\{apple,middle,zebra\}/, 'empty priority list uses alphabetical sort');
}

# Test 6: Nested objects with column priority (priority applies to root level)
{
    my $data = {
        zebra => 1,
        apple => { id => 1, name => 'nested' },
        middle => 2
    };
    
    my $toon = Data::TOON->encode($data, column_priority => ['apple']);
    
    # apple should come first despite alphabetical sort
    like($toon, qr/^apple:/, 'nested object priority respected at root level');
}

# Test 7: Tabular format with different delimiters and priority
{
    my $data = {
        users => [
            { id => 1, name => 'Alice', city => 'NYC' },
            { id => 2, name => 'Bob', city => 'LA' }
        ]
    };
    
    my $toon = Data::TOON->encode(
        $data,
        delimiter => '|',
        column_priority => ['id', 'name']
    );
    
    like($toon, qr/\|/, 'pipe delimiter used');
    like($toon, qr/\{id\|name\|city\}/, 'column priority respected with pipe delimiter');
}

done_testing;

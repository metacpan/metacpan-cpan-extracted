use strict;
use Test::More 0.98;
use Data::TOON;

# Test 1: Root primitive - number
{
    my $toon_text = '42';
    my $data = Data::TOON->decode($toon_text);
    is($data, 42, 'decode root primitive number');
}

# Test 2: Root primitive - string
{
    my $toon_text = 'hello';
    my $data = Data::TOON->decode($toon_text);
    is($data, 'hello', 'decode root primitive string');
}

# Test 3: Root primitive - boolean true
{
    my $toon_text = 'true';
    my $data = Data::TOON->decode($toon_text);
    is($data, 1, 'decode root primitive true');
}

# Test 4: Root primitive - boolean false
{
    my $toon_text = 'false';
    my $data = Data::TOON->decode($toon_text);
    is($data, 0, 'decode root primitive false');
}

# Test 5: Root primitive - null
{
    my $toon_text = 'null';
    my $data = Data::TOON->decode($toon_text);
    is($data, undef, 'decode root primitive null');
}

# Test 6: Root array - primitive inline
{
    my $toon_text = '[3]: apple,banana,cherry';
    my $data = Data::TOON->decode($toon_text);
    is(ref $data, 'ARRAY', 'decode root array');
    is(scalar @$data, 3, 'root array has 3 elements');
    is($data->[0], 'apple', 'first element');
}

# Test 7: Root array - with pipe delimiter
{
    my $toon_text = '[3|]: apple|banana|cherry';
    my $data = Data::TOON->decode($toon_text);
    is(scalar @$data, 3, 'root array with pipe delimiter');
    is($data->[1], 'banana', 'second element with pipe');
}

# Test 8: Encoding root primitive - number
{
    my $data = 42;
    my $encoded = Data::TOON->encode($data);
    is($encoded, '42', 'encode root primitive number');
}

# Test 9: Encoding root primitive - string
{
    my $data = 'hello';
    my $encoded = Data::TOON->encode($data);
    is($encoded, 'hello', 'encode root primitive string');
}

# Test 10: Encoding root primitive - numeric 1 (appears as 1, not true in Perl)
{
    my $data = 1;
    my $encoded = Data::TOON->encode($data);
    # In Perl, 1 is numeric, so it encodes as '1' not 'true'
    is($encoded, '1', 'encode root primitive numeric 1');
}

# Test 11: Encoding root array
{
    my $data = [1, 2, 3];
    my $encoded = Data::TOON->encode($data);
    like($encoded, qr/\[3\]/, 'encode root array');
}

# Test 12: Canonical number form - remove trailing zeros
{
    my $toon_text = 'data: 1.5000';
    my $data = Data::TOON->decode($toon_text);
    # After normalization should be 1.5
    is($data->{data}, 1.5, 'canonical: remove trailing zeros');
}

# Test 13: Canonical number form - -0 becomes 0
{
    my $toon_text = 'data: -0';
    my $data = Data::TOON->decode($toon_text);
    is($data->{data}, 0, 'canonical: -0 becomes 0');
}

# Test 14: Canonical number form - no leading zeros
{
    my $toon_text = 'data: 01';
    my $data = eval { Data::TOON->decode($toon_text) };
    # Should either error or treat as string
    ok($@ || $data->{data} eq '01', 'canonical: leading zeros rejected or as string');
}

# Test 15: Canonical number form - scientific notation
{
    my $toon_text = 'data: 1e3';
    my $data = Data::TOON->decode($toon_text);
    is($data->{data}, 1000, 'canonical: scientific notation');
}

# Test 16: Round-trip root primitive
{
    for my $value (42, 3.14, 'hello', 1, 0) {
        my $encoded = Data::TOON->encode($value);
        my $decoded = Data::TOON->decode($encoded);
        is($decoded, $value, "round-trip: $value");
    }
}

# Test 17: Round-trip root array
{
    my $data = [1, 2, 3];
    my $encoded = Data::TOON->encode($data);
    my $decoded = Data::TOON->decode($encoded);
    is_deeply($decoded, $data, 'round-trip root array');
}

done_testing;

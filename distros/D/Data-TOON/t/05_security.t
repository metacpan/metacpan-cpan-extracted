use strict;
use Test::More 0.98;
use Data::TOON;

# Test 1: Invalid escape sequences (not valid in TOON)
{
    my $toon_text = 'name: "test\\x00"';
    
    my $data = eval { Data::TOON->decode($toon_text) };
    # \x is not a valid escape - only \n, \r, \t, \\, \" are valid
    # Should be treated as literal string or error
    ok(defined $data || $@, 'decode handles invalid escape sequence');
}

# Test 2: Deep nesting (DoS risk) - should have limit
{
    my $depth = 150;  # Exceeds default max_depth of 100
    my $toon_text = "";
    for (my $i = 0; $i < $depth; $i++) {
        $toon_text .= ("  " x $i) . "level$i:\n";
    }
    
    my $data = eval { Data::TOON->decode($toon_text) };
    like($@ // '', qr/depth|exceed|limit/i, 'decode rejects excessive nesting');
}

# Test 3: Very long string (memory bomb risk)
{
    my $long_string = "x" x (1024 * 100);  # 100KB (reduced for test)
    my $toon_text = "data: \"$long_string\"";
    
    my $data = eval { Data::TOON->decode($toon_text) };
    ok(defined $data, 'decode handles large strings');
}

# Test 4: Array count mismatch
{
    my $toon_text = <<'TOON';
items[3]:
  - id: 1
  - id: 2
TOON
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode handles array count mismatch gracefully');
}

# Test 5: Malformed header - missing colon
{
    my $toon_text = "items[2]";
    
    my $data = Data::TOON->decode($toon_text);
    ok(defined $data, 'decode handles missing colon gracefully');
}

# Test 6: Invalid array size (negative)
{
    my $toon_text = 'items[-1]: value';
    
    my $data = eval { Data::TOON->decode($toon_text) };
    ok($data || $@, 'decode handles negative array size');
}

# Test 7: Unterminated quoted string
{
    my $toon_text = 'name: "unclosed string';
    
    my $data = Data::TOON->decode($toon_text);
    ok(defined $data, 'decode handles unterminated quotes gracefully');
}

# Test 8: Reserved characters in unquoted key
{
    my $toon_text = 'my-key: value';  # Hyphen not allowed in unquoted key at start
    
    my $data = Data::TOON->decode($toon_text);
    ok(defined $data, 'decode handles key with special chars');
}

# Test 9: Circular reference in encoding (DoS risk)
{
    my $data = { a => 1 };
    $data->{self} = $data;  # Circular reference
    
    my $encoder = Data::TOON::Encoder->new(max_depth => 10);  # Low limit to catch circular ref
    my $encoded = eval { $encoder->encode($data) };
    like($@ // '', qr/circular|reference|depth/i, 'encode detects circular references or depth limit');
}

# Test 10: NaN and Infinity are strings, not numbers
{
    my $toon_text = <<'TOON';
value1: NaN
value2: Infinity
TOON
    
    my $data = Data::TOON->decode($toon_text);
    is($data->{value1}, 'NaN', 'NaN decoded as string');
    is($data->{value2}, 'Infinity', 'Infinity decoded as string');
}

# Test 11: Shell injection-like patterns (data escaping)
{
    my $toon_text = 'cmd: "rm -rf /; echo pwned"';
    
    my $data = Data::TOON->decode($toon_text);
    is($data->{cmd}, "rm -rf /; echo pwned", 'dangerous string preserved literally');
}

# Test 12: SQL injection-like patterns
{
    my $toon_text = "query: \"SELECT * WHERE id='1' OR '1'='1'\"";
    
    my $data = Data::TOON->decode($toon_text);
    is($data->{query}, "SELECT * WHERE id='1' OR '1'='1'", 'SQL pattern preserved as string');
}

# Test 13: Multiple colons (HTTP URLs)
{
    my $toon_text = 'url: "http://example.com:8080/path"';
    
    my $data = Data::TOON->decode($toon_text);
    is($data->{url}, 'http://example.com:8080/path', 'URL with port parsed correctly');
}

# Test 14: Embedded quotes and escapes
{
    my $toon_text = 'message: "He said \"Hello\""';
    
    my $data = Data::TOON->decode($toon_text);
    is($data->{message}, 'He said "Hello"', 'escaped quotes handled correctly');
}

# Test 15: Max depth can be customized
{
    my $deep_data = { level1 => { level2 => { level3 => "value" } } };
    
    my $encoder_limited = Data::TOON::Encoder->new(max_depth => 2);
    my $encoded = eval { $encoder_limited->encode($deep_data) };
    like($@ // '', qr/depth|exceed|limit/i, 'encoder respects max_depth setting');
}

# Test 16: Delimiter confusion (CSV injection risk)
{
    my $toon_text = <<'TOON';
items[2]{a,b}:
  1|2
  3|4
TOON
    
    my $data = Data::TOON->decode($toon_text);
    ok($data, 'decode handles delimiter specification in header');
    # First row should try to split by comma, not pipe
}

# Test 17: Empty nested objects
{
    my $toon_text = <<'TOON';
user:
TOON
    
    my $data = Data::TOON->decode($toon_text);
    is(ref $data->{user}, 'HASH', 'empty nested object decoded as hash');
}

# Test 18: Newlines in values
{
    my $toon_text = "text: \"line1\\nline2\"";
    
    my $data = Data::TOON->decode($toon_text);
    is($data->{text}, "line1\nline2", 'escaped newline in value preserved');
}

done_testing;


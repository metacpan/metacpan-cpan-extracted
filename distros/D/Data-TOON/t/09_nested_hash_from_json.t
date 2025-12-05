use strict;
use Test::More 0.98;
use Data::TOON;
use JSON::PP;

# Test for issue: HASH references not properly serialized in nested structures
# When using Data::TOON->encode() to serialize data structures returned from JSON::PP::decode_json(),
# nested HASH references are displayed as HASH(0x...) instead of being properly expanded.

# Test 1: Basic nested hash from JSON (the original issue)
{
    my $json = '{"result":{"tools":[{"name":"test","inputSchema":{"type":"object","properties":{}}}]}}';
    my $data = JSON::PP::decode_json($json);
    my $toon = Data::TOON->encode($data);
    
    ok($toon, 'encode() returns non-empty string for nested structure from JSON');
    
    # The inputSchema should be expanded, not shown as HASH(0x...)
    unlike($toon, qr/HASH\(0x/, 'encoded TOON does not contain HASH reference strings');
    
    # Should contain the actual nested structure
    like($toon, qr/inputSchema/, 'encoded TOON contains inputSchema key');
    like($toon, qr/properties/, 'encoded TOON contains properties key');
    like($toon, qr/type:\s*object/, 'encoded TOON contains type value');
}

# Test 2: Deeper nesting from JSON
{
    my $json = '{"a":{"b":{"c":{"d":"value"}}}}';
    my $data = JSON::PP::decode_json($json);
    my $toon = Data::TOON->encode($data);
    
    ok($toon, 'encode() handles deeply nested JSON structures');
    unlike($toon, qr/HASH\(0x/, 'deeply nested structure is fully expanded');
    like($toon, qr/d:\s*value/, 'deeply nested values are present');
}

# Test 3: Array with objects containing nested hashes from JSON
{
    my $json = '{"items":[{"id":1,"meta":{"tags":["a","b"],"info":"test"}}]}';
    my $data = JSON::PP::decode_json($json);
    my $toon = Data::TOON->encode($data);
    
    ok($toon, 'encode() handles arrays with nested hashes from JSON');
    unlike($toon, qr/HASH\(0x/, 'nested hashes in array elements are expanded');
    like($toon, qr/meta/, 'meta key is present');
    like($toon, qr/info/, 'info key is present');
}

# Test 4: Compare with manually created structure vs JSON decoded
{
    # Manually created structure
    my $manual = {
        result => {
            tools => [
                {
                    name => 'test',
                    inputSchema => {
                        type => 'object',
                        properties => {}
                    }
                }
            ]
        }
    };
    
    # JSON decoded structure (should behave the same)
    my $json = '{"result":{"tools":[{"name":"test","inputSchema":{"type":"object","properties":{}}}]}}';
    my $from_json = JSON::PP::decode_json($json);
    
    my $toon_manual = Data::TOON->encode($manual);
    my $toon_json = Data::TOON->encode($from_json);
    
    # Both should not contain HASH references
    unlike($toon_manual, qr/HASH\(0x/, 'manually created structure is properly expanded');
    unlike($toon_json, qr/HASH\(0x/, 'JSON decoded structure is properly expanded');
    
    # Both should produce similar output (order may differ due to hash randomization)
    like($toon_manual, qr/inputSchema/, 'manual: contains inputSchema');
    like($toon_json, qr/inputSchema/, 'json: contains inputSchema');
}

done_testing;

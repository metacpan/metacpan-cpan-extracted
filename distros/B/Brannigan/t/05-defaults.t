#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# Test default values
my $b = Brannigan->new();

# Simple scalar defaults
$b->register_schema('scalar_defaults', {
    params => {
        name => { required => 1 },
        status => { default => 'active' },
        priority => { default => 1, integer => 1 },
        category => { default => 'general' }
    }
});

{
    my $params = { name => 'Test' };
    my $rejects = $b->process('scalar_defaults', $params);
    is($rejects, undef, 'Processing with defaults succeeds');
    is($params->{name}, 'Test', 'Required parameter preserved');
    is($params->{status}, 'active', 'String default applied');
    is($params->{priority}, 1, 'Integer default applied');
    is($params->{category}, 'general', 'Category default applied');
}

# Provided values should override defaults
{
    my $params = { name => 'Test', status => 'inactive', priority => 5 };
    my $rejects = $b->process('scalar_defaults', $params);
    is($rejects, undef, 'Processing with overridden defaults succeeds');
    is($params->{status}, 'inactive', 'Provided value overrides default');
    is($params->{priority}, 5, 'Provided priority overrides default');
    is($params->{category}, 'general', 'Unspecified default still applied');
}

# Subroutine-based defaults
$b->register_schema('dynamic_defaults', {
    params => {
        id => { 
            default => sub { int(rand(100000)) },
            integer => 1 
        },
        timestamp => {
            default => sub { time() }
        },
        author => {
            default => sub { 'system' }
        }
    }
});

{
    my $params = {};
    my $rejects = $b->process('dynamic_defaults', $params);
    is($rejects, undef, 'Processing with dynamic defaults succeeds');
    like($params->{id}, qr/^\d+$/, 'Random ID generated');
    like($params->{timestamp}, qr/^\d+$/, 'Timestamp generated');
    is($params->{author}, 'system', 'System author set');
}

# Multiple calls should generate different dynamic defaults
{
    my $params1 = {};
    my $params2 = {};
    $b->process('dynamic_defaults', $params1);
    $b->process('dynamic_defaults', $params2);
    
    isnt($params1->{id}, $params2->{id}, 'Different random IDs generated');
    is($params1->{author}, $params2->{author}, 'Static defaults are same');
}

# Complex defaults (arrays and hashes)
$b->register_schema('complex_defaults', {
    params => {
        tags => {
            array => 1,
            default => ['untagged']
        },
        metadata => {
            hash => 1,
            default => { version => 1, type => 'default' }
        },
        options => {
            default => sub { { auto_save => 1, debug => 0 } }
        }
    }
});

{
    my $params = {};
    my $rejects = $b->process('complex_defaults', $params);
    is($rejects, undef, 'Processing with complex defaults succeeds');
    is($params->{tags}, ['untagged'], 'Array default applied');
    is($params->{metadata}, { version => 1, type => 'default' }, 'Hash default applied');
    is($params->{options}, { auto_save => 1, debug => 0 }, 'Dynamic hash default applied');
}

# Defaults should be validated
$b->register_schema('validated_defaults', {
    params => {
        status => {
            default => 'pending',
            one_of => ['pending', 'active', 'inactive']
        },
        count => {
            default => 10,
            integer => 1,
            min_value => 1
        }
    }
});

{
    my $params = {};
    my $rejects = $b->process('validated_defaults', $params);
    is($rejects, undef, 'Valid defaults pass validation');
    is($params->{status}, 'pending', 'Valid default applied');
    is($params->{count}, 10, 'Valid numeric default applied');
}

# Test that defaults don't apply to required parameters that fail
$b->register_schema('required_no_default', {
    params => {
        name => { required => 1 },
        backup_name => { default => 'unnamed' }
    }
});

{
    my $params = {}; # Missing required name
    my $rejects = $b->process('required_no_default', $params);
    is($rejects, { name => { required => 1 } }, 'Required parameter failure');
    is($params->{backup_name}, 'unnamed', 'Default still applied to non-required params');
}

# Edge case: empty string and zero values should not trigger defaults
$b->register_schema('edge_cases', {
    params => {
        description => { default => 'No description' },
        count => { default => 1, integer => 1 },
        flag => { default => 'true' }
    }
});

{
    my $params = { description => '', count => 0, flag => 'false' };
    my $rejects = $b->process('edge_cases', $params);
    is($rejects, undef, 'Edge case processing succeeds');
    is($params->{description}, '', 'Empty string preserved (not replaced with default)');
    is($params->{count}, 0, 'Zero value preserved (not replaced with default)');
    is($params->{flag}, 'false', 'False value preserved (not replaced with default)');
}

# =============================================================================
# ARRAY ITEM DEFAULTS TESTS
# =============================================================================

# Test array item defaults specifically
$b->register_schema('array_defaults_test', {
    params => {
        items => {
            array => 1,
            values => {
                hash => 1,
                keys => {
                    name => { required => 1 },
                    active => { default => 1 },
                    priority => { default => 3 },
                    created_at => { default => sub { 'test_time' } }
                }
            }
        }
    }
});

# Test with missing defaults
{
    my $params = {
        items => [
            { name => 'First' },
            { name => 'Second', active => 0 },
            { name => 'Third', priority => 5 }
        ]
    };
    
    my $rejects = $b->process('array_defaults_test', $params);
    is($rejects, undef, 'Array defaults validation succeeds');
    
    # Check defaults were applied
    is($params->{items}->[0]->{active}, 1, 'First item active default applied');
    is($params->{items}->[0]->{priority}, 3, 'First item priority default applied');
    is($params->{items}->[0]->{created_at}, 'test_time', 'First item function default applied');
    
    is($params->{items}->[1]->{active}, 0, 'Second item explicit value preserved');
    is($params->{items}->[1]->{priority}, 3, 'Second item priority default applied');
    is($params->{items}->[1]->{created_at}, 'test_time', 'Second item function default applied');
    
    is($params->{items}->[2]->{active}, 1, 'Third item active default applied');
    is($params->{items}->[2]->{priority}, 5, 'Third item explicit value preserved');
    is($params->{items}->[2]->{created_at}, 'test_time', 'Third item function default applied');
}

# Test with empty array (should still work)
{
    my $params = { items => [] };
    my $rejects = $b->process('array_defaults_test', $params);
    is($rejects, undef, 'Empty array with defaults succeeds');
    is($params->{items}, [], 'Empty array unchanged');
}

# Test deep nesting: array in hash in array
$b->register_schema('deep_nesting', {
    params => {
        departments => {
            array => 1,
            values => {
                hash => 1,
                keys => {
                    name => { required => 1 },
                    active => { default => 1 },
                    employees => {
                        array => 1,
                        values => {
                            hash => 1,
                            keys => {
                                name => { required => 1 },
                                role => { default => 'employee' },
                                salary => { default => 50000 }
                            }
                        }
                    }
                }
            }
        }
    }
});

{
    my $params = {
        departments => [
            {
                name => 'Engineering',
                employees => [
                    { name => 'Alice' },
                    { name => 'Bob', role => 'manager' }
                ]
            },
            {
                name => 'Sales',
                active => 0,
                employees => [
                    { name => 'Charlie', salary => 60000 }
                ]
            }
        ]
    };
    
    my $rejects = $b->process('deep_nesting', $params);
    is($rejects, undef, 'Deep nesting defaults validation succeeds');
    
    # Check department defaults
    is($params->{departments}->[0]->{active}, 1, 'Engineering department active default');
    is($params->{departments}->[1]->{active}, 0, 'Sales department explicit value preserved');
    
    # Check employee defaults
    is($params->{departments}->[0]->{employees}->[0]->{role}, 'employee', 'Alice role default');
    is($params->{departments}->[0]->{employees}->[0]->{salary}, 50000, 'Alice salary default');
    is($params->{departments}->[0]->{employees}->[1]->{role}, 'manager', 'Bob role explicit');
    is($params->{departments}->[0]->{employees}->[1]->{salary}, 50000, 'Bob salary default');
    
    is($params->{departments}->[1]->{employees}->[0]->{role}, 'employee', 'Charlie role default');
    is($params->{departments}->[1]->{employees}->[0]->{salary}, 60000, 'Charlie salary explicit');
}

done_testing();
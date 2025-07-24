#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# Test complex nested structures (hashes and arrays)
my $b = Brannigan->new();

# Simple hash structure
$b->register_schema('user_profile', {
    params => {
        name => {
            hash => 1,
            keys => {
                first => { required => 1, min_length => 1 },
                last => { required => 1, min_length => 1 },
                middle => { required => 0 }
            }
        },
        age => { required => 1, integer => 1, min_value => 0 }
    }
});

{
    my $params = {
        name => { first => 'John', last => 'Doe' },
        age => 30
    };
    my $rejects = $b->process('user_profile', $params);
    is($rejects, undef, 'Simple hash structure validation succeeds');
}

# Hash validation failures
{
    my $params = {
        name => { first => 'John' }, # Missing required 'last'
        age => 30
    };
    my $rejects = $b->process('user_profile', $params);
    is($rejects, { 'name.last' => { required => 1 } }, 
       'Hash key validation failure reported correctly');
}

# Simple array structure
$b->register_schema('todo_list', {
    params => {
        items => {
            array => 1,
            required => 1,
            min_length => 1,
            values => {
                hash => 1,
                keys => {
                    task => { required => 1, min_length => 1 },
                    done => { required => 0, default => 0 },
                    priority => { 
                        required => 0, 
                        integer => 1, 
                        value_between => [1, 5],
                        default => 3
                    }
                }
            }
        }
    }
});

{
    my $params = {
        items => [
            { task => 'Buy milk' },
            { task => 'Write tests', priority => 1 },
            { task => 'Deploy code', done => 1, priority => 5 }
        ]
    };
    my $rejects = $b->process('todo_list', $params);
    is($rejects, undef, 'Array of hashes validation succeeds');
    
    # Note: defaults are now applied to nested array items
    is($params->{items}->[0]->{done}, 0, 'Array item default applied');
    is($params->{items}->[0]->{priority}, 3, 'Array item default applied');
    is($params->{items}->[1]->{done}, 0, 'Array item default applied');
}

# Array validation failures
{
    my $params = {
        items => [
            { task => 'Buy milk' },
            { task => '' }, # Empty task
            { task => 'Valid task', priority => 10 } # Priority too high
        ]
    };
    my $rejects = $b->process('todo_list', $params);
    is($rejects, {
        'items.1.task' => { min_length => 1 },
        'items.2.priority' => { value_between => [1, 5] }
    }, 'Array item validation failures reported correctly');
}

# Deeply nested structures
$b->register_schema('organization', {
    params => {
        departments => {
            array => 1,
            required => 1,
            values => {
                hash => 1,
                keys => {
                    name => { required => 1, min_length => 1 },
                    employees => {
                        array => 1,
                        required => 1,
                        min_length => 1,
                        values => {
                            hash => 1,
                            keys => {
                                name => { required => 1, min_length => 1 },
                                position => { required => 1, min_length => 1 },
                                skills => {
                                    array => 1,
                                    required => 0,
                                    values => {
                                        min_length => 2
                                    }
                                }
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
                    {
                        name => 'Alice Smith',
                        position => 'Senior Developer',
                        skills => ['Perl', 'JavaScript', 'Docker']
                    },
                    {
                        name => 'Bob Jones',
                        position => 'Junior Developer',
                        skills => ['Go']
                    }
                ]
            }
        ]
    };
    my $rejects = $b->process('organization', $params);
    is($rejects, undef, 'Deeply nested structure validation succeeds');
}

# Deep validation failure
{
    my $params = {
        departments => [
            {
                name => 'Engineering',
                employees => [
                    {
                        name => 'Alice Smith',
                        position => 'Senior Developer',
                        skills => ['X'] # Skill name too short
                    }
                ]
            }
        ]
    };
    my $rejects = $b->process('organization', $params);
    is($rejects, { 'departments.0.employees.0.skills.0' => { min_length => 2 } },
       'Deep nested validation failure reported correctly');
}

# Mixed array and hash defaults
$b->register_schema('config', {
    params => {
        database => {
            hash => 1,
            default => { host => 'localhost', port => 5432 },
            keys => {
                host => { required => 1 },
                port => { required => 1, integer => 1 },
                options => {
                    hash => 1,
                    default => { ssl => 1, timeout => 30 }
                }
            }
        },
        features => {
            array => 1,
            default => ['logging', 'metrics']
        }
    }
});

{
    my $params = {};
    my $rejects = $b->process('config', $params);
    is($rejects, undef, 'Complex defaults validation succeeds');
    is($params->{database}->{host}, 'localhost', 'Hash default applied');
    is($params->{database}->{options}, { ssl => 1, timeout => 30 }, 'Nested hash defaults now applied');
    is($params->{features}, ['logging', 'metrics'], 'Array default applied');
}

# Array of simple values
$b->register_schema('tags', {
    params => {
        categories => {
            array => 1,
            required => 1,
            values => {
                min_length => 2,
                matches => qr/^[a-z]+$/
            }
        }
    }
});

{
    my $params = { categories => ['tech', 'programming', 'perl'] };
    my $rejects = $b->process('tags', $params);
    is($rejects, undef, 'Array of simple values validation succeeds');
}

{
    my $params = { categories => ['tech', 'A', 'invalid-tag'] };
    my $rejects = $b->process('tags', $params);
    is($rejects->{'categories.1'}->{min_length}, 2, 'First category min_length error');
    is(ref($rejects->{'categories.1'}->{matches}), 'Regexp', 'First category matches is a regex');
    is(ref($rejects->{'categories.2'}->{matches}), 'Regexp', 'Second category matches is a regex');
}

# Edge case: empty arrays and hashes
$b->register_schema('optional_collections', {
    params => {
        tags => { array => 1, required => 0 },
        metadata => { hash => 1, required => 0 }
    }
});

{
    my $params = { tags => [], metadata => {} };
    my $rejects = $b->process('optional_collections', $params);
    is($rejects, undef, 'Empty collections validation succeeds');
}

# Validation at collection level vs item level
$b->register_schema('collection_vs_item', {
    params => {
        numbers => {
            array => 1,
            required => 1, # Collection is required
            min_length => 2, # Collection must have at least 2 items
            values => {
                integer => 1, # Each item must be integer
                min_value => 0 # Each item must be >= 0
            }
        }
    }
});

{
    my $params = { numbers => [5] }; # Only 1 item, needs 2
    my $rejects = $b->process('collection_vs_item', $params);
    is($rejects, { numbers => { min_length => 2 } },
       'Collection-level validation failure');
}

{
    my $params = { numbers => [5, -1] }; # 2 items but one is negative
    my $rejects = $b->process('collection_vs_item', $params);
    like($rejects, { 'numbers.1' => { integer => 1, min_value => 0 } },
       'Item-level validation failure');
}

done_testing();
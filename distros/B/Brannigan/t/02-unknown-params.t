#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# =============================================================================
# TOP-LEVEL UNKNOWN PARAMETER HANDLING TESTS
# =============================================================================

# Simple schema for top-level tests
my $simple_schema = {
    params => {
        subject => { required => 1 },
        text    => { required => 1 },
    }
};

# Test ignore behavior (default)
{
    my $b = Brannigan->new();
    $b->register_schema('simple', $simple_schema);
    my $params = {
        subject => 'test subject',
        text    => 'test text',
        unknown => 'unknown value',
        extra   => 'extra value'
    };
    
    my $rejects = $b->process('simple', $params);
    is($rejects, undef, 'No rejects with ignore behavior (default)');
    is($params->{unknown}, 'unknown value', 'Unknown parameter preserved with ignore');
    is($params->{extra}, 'extra value', 'Extra parameter preserved with ignore');
}

# Test ignore behavior (explicit)
{
    my $b = Brannigan->new({ handle_unknown => 'ignore' });
    $b->register_schema('simple', $simple_schema);
    my $params = {
        subject => 'test subject',
        text    => 'test text',
        unknown => 'unknown value'
    };
    
    my $rejects = $b->process('simple', $params);
    is($rejects, undef, 'No rejects with explicit ignore behavior');
    is($params->{unknown}, 'unknown value', 'Unknown parameter preserved with explicit ignore');
}

# Test remove behavior
{
    my $b = Brannigan->new({ handle_unknown => 'remove' });
    $b->register_schema('simple', $simple_schema);
    my $params = {
        subject => 'test subject',
        text    => 'test text',
        unknown => 'unknown value',
        extra   => 'extra value'
    };
    
    my $rejects = $b->process('simple', $params);
    is($rejects, undef, 'No rejects with remove behavior');
    ok(!exists $params->{unknown}, 'Unknown parameter removed');
    ok(!exists $params->{extra}, 'Extra parameter removed');
    is($params->{subject}, 'test subject', 'Known parameter preserved');
    is($params->{text}, 'test text', 'Known parameter preserved');
}

# Test reject behavior
{
    my $b = Brannigan->new({ handle_unknown => 'reject' });
    $b->register_schema('simple', $simple_schema);
    my $params = {
        subject => 'test subject',
        text    => 'test text',
        unknown => 'unknown value',
        extra   => 'extra value'
    };
    
    my $rejects = $b->process('simple', $params);
    is($rejects, {
        unknown => { unknown => 1 },
        extra   => { unknown => 1 }
    }, 'Top-level unknown parameters rejected');
    is($params->{unknown}, 'unknown value', 'Unknown parameter still in input');
    is($params->{extra}, 'extra value', 'Extra parameter still in input');
}

# =============================================================================
# NESTED UNKNOWN PARAMETER HANDLING TESTS
# =============================================================================

# Complex schema for nested tests
my $nested_schema = {
    params => {
        person => {
            hash => 1,
            keys => {
                name => { required => 1 },
                age  => { required => 1 },
            }
        },
        skills => {
            array => 1,
            values => {
                hash => 1,
                keys => {
                    name  => { required => 1 },
                    level => { required => 1 },
                }
            }
        }
    }
};

# Test ignore behavior with nested unknown parameters (default behavior)
{
    my $b = Brannigan->new();
    $b->register_schema('nested', $nested_schema);
    
    my $params = {
        person => {
            name => 'John',
            age  => 30,
            unknown_attr => 'should be ignored'
        },
        skills => [{
            name  => 'Perl',
            level => 'expert',
            extra => 'unknown skill attr'
        }],
        top_level_unknown => 'also ignored'
    };
    
    my $rejects = $b->process('nested', $params);
    is($rejects, undef, 'Nested unknown parameters ignored by default');
    is($params->{person}->{unknown_attr}, 'should be ignored', 'Nested hash unknown preserved with ignore');
    is($params->{skills}->[0]->{extra}, 'unknown skill attr', 'Array item unknown preserved');
    is($params->{top_level_unknown}, 'also ignored', 'Top level unknown preserved');
}

# Test remove behavior with nested unknown parameters  
{
    my $b = Brannigan->new({ handle_unknown => 'remove' });
    $b->register_schema('nested', $nested_schema);
    
    my $params = {
        person => {
            name => 'John',
            age  => 30,
            unknown_attr => 'should be removed'
        },
        skills => [{
            name  => 'Perl',
            level => 'expert',
            extra => 'unknown skill attr'
        }],
        top_level_unknown => 'will be removed'
    };
    
    my $rejects = $b->process('nested', $params);
    is($rejects, undef, 'No rejects with nested remove behavior');
    ok(!exists $params->{top_level_unknown}, 'Top level unknown removed');
    ok(!exists $params->{person}->{unknown_attr}, 'Nested hash unknown removed');
    ok(!exists $params->{skills}->[0]->{extra}, 'Nested array item hash unknown removed');
    # Verify known parameters are preserved
    is($params->{person}->{name}, 'John', 'Known nested parameter preserved');
    is($params->{skills}->[0]->{name}, 'Perl', 'Known array item parameter preserved');
}

# Test reject behavior with nested unknown parameters
{
    my $b = Brannigan->new({ handle_unknown => 'reject' });
    $b->register_schema('nested', $nested_schema);
    
    my $params = {
        person => {
            name => 'John',
            age  => 30,
            unknown_attr => 'will cause reject'
        },
        skills => [{
            name  => 'Perl',
            level => 'expert',
            extra => 'unknown skill attr'
        }],
        top_level_unknown => 'will be rejected'
    };
    
    my $rejects = $b->process('nested', $params);
    is($rejects, { 
        top_level_unknown => { unknown => 1 },
        'person.unknown_attr' => { unknown => 1 },
        'skills.0.extra' => { unknown => 1 }
    }, 'Top level, nested hash, and nested array item unknowns all rejected');
    # Input is preserved when using reject mode
    is($params->{person}->{unknown_attr}, 'will cause reject', 'Nested unknown still in input (reject mode)');
    is($params->{skills}->[0]->{extra}, 'unknown skill attr', 'Array nested unknown still in input');
}

# Test deeply nested unknown parameters
{
    my $deep_schema = {
        params => {
            company => {
                hash => 1,
                keys => {
                    name => { required => 1 },
                    departments => {
                        array => 1,
                        values => {
                            hash => 1,
                            keys => {
                                name => { required => 1 },
                                manager => {
                                    hash => 1,
                                    keys => {
                                        name => { required => 1 },
                                        email => { required => 1 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    };
    
    my $b = Brannigan->new({ handle_unknown => 'reject' });
    $b->register_schema('deep', $deep_schema);
    
    my $params = {
        company => {
            name => 'Acme Corp',
            unknown_company_field => 'should be rejected',
            departments => [{
                name => 'Engineering',
                unknown_dept_field => 'also rejected',
                manager => {
                    name => 'Alice Smith',
                    email => 'alice@example.com',
                    unknown_manager_field => 'deeply rejected'
                }
            }]
        },
        top_unknown => 'top level rejected'
    };
    
    my $rejects = $b->process('deep', $params);
    is($rejects, {
        'top_unknown' => { unknown => 1 },
        'company.unknown_company_field' => { unknown => 1 },
        'company.departments.0.unknown_dept_field' => { unknown => 1 },
        'company.departments.0.manager.unknown_manager_field' => { unknown => 1 }
    }, 'Deep nesting unknown parameters all rejected with correct paths');
}

# =============================================================================
# API AND CONFIGURATION TESTS  
# =============================================================================

# Test handle_unknown getter/setter
{
    my $b = Brannigan->new();
    $b->register_schema('simple', $simple_schema);
    is($b->handle_unknown, 'ignore', 'Default handle_unknown is ignore');
    
    $b->handle_unknown('remove');
    is($b->handle_unknown, 'remove', 'handle_unknown setter works');
    
    my $params = {
        subject => 'test',
        text    => 'test',
        unknown => 'value'
    };
    
    $b->process('simple', $params);
    ok(!exists $params->{unknown}, 'Changed behavior applied');
}

# Test invalid handle_unknown value
{
    my $b = Brannigan->new();
    $b->register_schema('simple', $simple_schema);
    my $error = dies { $b->handle_unknown('invalid') };
    like($error, qr/Invalid handle_unknown value/, 'Invalid value rejected');
}

# Test chainability
{
    my $b = Brannigan->new();
    $b->register_schema('simple', $simple_schema);
    my $result = $b->handle_unknown('remove');
    is($result, $b, 'handle_unknown method is chainable');
}

# Test with schema inheritance
{
    my $base_schema = {
        params => { subject => { required => 1 } }
    };
    
    my $child_schema = {
        inherits_from => 'base',
        params        => { text => { required => 1 } }
    };
    
    my $b = Brannigan->new({ handle_unknown => 'reject' });
    $b->register_schema('base', $base_schema);
    $b->register_schema('child', $child_schema);
    my $params = {
        subject => 'test',
        text    => 'test',
        unknown => 'value'
    };
    
    my $rejects = $b->process('child', $params);
    is($rejects, { unknown => { unknown => 1 } }, 'Unknown params rejected with inheritance');
}

done_testing();
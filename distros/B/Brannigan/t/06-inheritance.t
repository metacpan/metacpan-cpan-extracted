#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# Test schema inheritance
my $b = Brannigan->new();

# Base schema
$b->register_schema('base_user', {
    params => {
        name => { required => 1, min_length => 2 },
        email => { required => 1, matches => qr/\@/ },
        age => { integer => 1, min_value => 0 },
        status => { default => 'active' }
    }
});

# Test base schema works
{
    my $params = { name => 'John', email => 'john@example.com', age => 30 };
    my $rejects = $b->process('base_user', $params);
    is($rejects, undef, 'Base schema validation succeeds');
    is($params->{status}, 'active', 'Base schema default applied');
}

# Simple inheritance - child inherits all properties
$b->register_schema('admin_user', {
    inherits_from => 'base_user',
    params => {
        permissions => { required => 1, array => 1, min_length => 1 }
    }
});

{
    my $params = { 
        name => 'Admin', 
        email => 'admin@example.com',
        permissions => ['read', 'write', 'delete']
    };
    my $rejects = $b->process('admin_user', $params);
    is($rejects, undef, 'Inherited schema validation succeeds');
    is($params->{status}, 'active', 'Inherited default applied');
}

# Child should inherit parent's validation rules
{
    my $params = { 
        name => 'A', # Too short 
        email => 'admin@example.com',
        permissions => ['read']
    };
    my $rejects = $b->process('admin_user', $params);
    is($rejects, { name => { min_length => 2 } }, 'Inherited validation enforced');
}

# Overriding parent properties
$b->register_schema('guest_user', {
    inherits_from => 'base_user',
    params => {
        name => { required => 0 }, # Override: name not required for guests
        email => { required => 0 }, # Override: email not required for guests  
        guest_id => { required => 1 }
    }
});

{
    my $params = { guest_id => 'guest123' };
    my $rejects = $b->process('guest_user', $params);
    is($rejects, undef, 'Overridden requirements work');
    is($params->{status}, 'active', 'Inherited default still applies');
}

# Multiple inheritance
$b->register_schema('timestamps', {
    params => {
        created_at => { default => sub { time() } },
        updated_at => { default => sub { time() } }
    }
});

$b->register_schema('versioned', {
    params => {
        version => { default => 1, integer => 1 }
    }
});

$b->register_schema('document', {
    inherits_from => ['timestamps', 'versioned'],
    params => {
        title => { required => 1, min_length => 1 },
        content => { required => 1 }
    }
});

{
    my $params = { title => 'Test Doc', content => 'Content here' };
    my $rejects = $b->process('document', $params);
    is($rejects, undef, 'Multiple inheritance works');
    like($params->{created_at}, qr/^\d+$/, 'Inherited timestamp applied');
    is($params->{version}, 1, 'Inherited version applied');
}

# Deep inheritance chain
$b->register_schema('super_admin', {
    inherits_from => 'admin_user',
    params => {
        permissions => { 
            required => 1, 
            array => 1, 
            min_length => 3  # Override: super admin needs more permissions
        },
        sudo_access => { default => 1 }
    }
});

{
    my $params = { 
        name => 'SuperAdmin', 
        email => 'super@example.com',
        permissions => ['read', 'write'] # Only 2, but needs 3
    };
    my $rejects = $b->process('super_admin', $params);
    is($rejects, { permissions => { min_length => 3 } }, 
       'Overridden validation in inheritance chain works');
}

{
    my $params = { 
        name => 'SuperAdmin', 
        email => 'super@example.com',
        permissions => ['read', 'write', 'delete']
    };
    my $rejects = $b->process('super_admin', $params);
    is($rejects, undef, 'Deep inheritance validation succeeds');
    is($params->{status}, 'active', 'Base schema default inherited');
    is($params->{sudo_access}, 1, 'Child schema default applied');
}

# Inheritance with postprocessing
$b->register_schema('base_post', {
    params => {
        title => { required => 1 },
        slug => { 
            required => 1,
            postprocess => sub {
                my $val = shift;
                return lc($val =~ s/\s+/-/gr);
            }
        }
    }
});

$b->register_schema('blog_post', {
    inherits_from => 'base_post',
    params => {
        category => { default => 'general' }
    },
    postprocess => sub {
        my $params = shift;
        $params->{full_slug} = "$params->{category}/$params->{slug}";
    }
});

{
    my $params = { title => 'My Post', slug => 'My Great Post' };
    my $rejects = $b->process('blog_post', $params);
    is($rejects, undef, 'Inheritance with processing succeeds');
    is($params->{slug}, 'my-great-post', 'Inherited postprocessing applied');
    is($params->{full_slug}, 'general/my-great-post', 'Child postprocessing applied');
}

# Test inheritance precedence - child merges with parent (current behavior)
$b->register_schema('parent_precedence', {
    params => {
        field => { 
            required => 1, 
            min_length => 5,
            max_length => 10,
            default => 'parent_default'
        }
    }
});

$b->register_schema('child_precedence', {
    inherits_from => 'parent_precedence',
    params => {
        field => { 
            required => 0,  # Override requirement
            min_length => 2, # Override min length
            default => 'child_def' # Override default (must fit parent's max_length constraint)
            # Note: max_length from parent is preserved (merged)
        }
    }
});

{
    my $params = {}; # No field provided
    my $rejects = $b->process('child_precedence', $params);
    is($rejects, undef, 'Child overrides work');
    is($params->{field}, 'child_def', 'Child default overrides parent');
}

{
    my $params = { field => 'short' }; # Satisfies both parent and child constraints
    my $rejects = $b->process('child_precedence', $params);
    is($rejects, undef, 'Child can still validate with merged constraints');
}

{
    my $params = { field => 'very long text that exceeds parent max length constraint' };
    my $rejects = $b->process('child_precedence', $params);
    is($rejects, { field => { max_length => 10 } }, 
       'Parent constraints are preserved in inheritance (merged behavior)');
}

done_testing();
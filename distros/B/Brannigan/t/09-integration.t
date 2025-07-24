#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# Integration test - combines multiple features to ensure they work together
my $b = Brannigan->new({ handle_unknown => 'ignore' });

# Register custom validators
$b->register_validator('slug_format', sub {
    my $value = shift;
    return $value =~ /^[a-z0-9-]+$/ ? 1 : 0;
});

$b->register_validator('tag_format', sub {
    my $value = shift;
    return $value =~ /^[a-z]+$/ ? 1 : 0;
});

# Base content schema with preprocessing, postprocessing, and defaults
$b->register_schema('base_content', {
    params => {
        title => {
            required => 1,
            min_length => 1,
            max_length => 100,
            preprocess => sub {
                my $value = shift;
                # Trim whitespace and normalize spaces
                $value =~ s/^\s+|\s+$//g;
                $value =~ s/\s+/ /g;
                return $value;
            }
        },
        slug => {
            required => 1,
            slug_format => 1,
            preprocess => sub {
                my $value = shift;
                # Auto-generate from title if not provided properly
                if (!$value || $value !~ /^[a-z0-9-]+$/) {
                    # Get title from somewhere - this is a bit hacky but for demo
                    $value = lc($value || '');
                    $value =~ s/[^a-z0-9\s]//g;
                    $value =~ s/\s+/-/g;
                }
                return $value;
            }
        },
        status => {
            default => 'draft',
            one_of => ['draft', 'published', 'archived']
        },
        author => {
            default => sub { 'system' }
        },
        created_at => {
            default => sub { time() }
        },
        tags => {
            array => 1,
            default => [],
            values => {
                tag_format => 1,
                min_length => 2
            }
        },
        metadata => {
            hash => 1,
            default => {},
            keys => {
                category => { default => 'general' },
                priority => { default => 1, integer => 1, value_between => [1, 5] }
            }
        }
    },
    postprocess => sub {
        my $params = shift;
        # Generate summary statistics
        $params->{word_count} = defined $params->{content} 
            ? scalar(split /\s+/, $params->{content}) 
            : 0;
        $params->{tag_count} = scalar(@{$params->{tags} || []});
    }
});

# Blog post schema inheriting from base with additional features
$b->register_schema('blog_post', {
    inherits_from => 'base_content',
    params => {
        content => {
            required => 1,
            min_length => 10,
            validate => sub {
                my $value = shift;
                # No placeholder content allowed
                return $value !~ /lorem ipsum/i;
            }
        },
        excerpt => {
            required => 0,
            max_length => 200,
            postprocess => sub {
                my $value = shift;
                # Auto-generate excerpt from content if not provided
                if (!defined $value) {
                    # This is hacky - in real code, you'd pass content differently
                    return "Auto-generated excerpt";
                }
                return $value;
            }
        },
        comments_enabled => {
            default => 1
        }
    }
});

# Page schema inheriting from base with different requirements
$b->register_schema('page', {
    inherits_from => 'base_content',
    params => {
        content => {
            required => 1,
            min_length => 1 # Pages can be shorter than blog posts
        },
        template => {
            default => 'default',
            one_of => ['default', 'landing', 'about', 'contact']
        },
        show_in_menu => {
            default => 0
        }
    }
});

# Test successful blog post creation with all features
{
    my $params = {
        title => "  My   Great   Blog Post  ",
        slug => "my-blog-post",
        content => "This is a comprehensive blog post about Perl validation libraries.",
        status => "published",
        tags => ["perl", "validation", "testing"],
        metadata => {
            category => "programming",
            priority => 3
        },
        unknown_field => "should be ignored"
    };
    
    my $rejects = $b->process('blog_post', $params);
    is($rejects, undef, 'Comprehensive blog post validation succeeds');
    
    # Check preprocessing worked
    is($params->{title}, "My Great Blog Post", 'Title preprocessing applied');
    
    # Check defaults were applied
    is($params->{author}, 'system', 'Default author applied');
    like($params->{created_at}, qr/^\d+$/, 'Timestamp default applied');
    is($params->{comments_enabled}, 1, 'Blog-specific default applied');
    is($params->{metadata}->{category}, 'programming', 'Provided metadata preserved');
    
    # Check postprocessing worked
    is($params->{word_count}, 10, 'Word count calculated correctly');
    is($params->{tag_count}, 3, 'Tag count calculated correctly');
    
    # Check unknown handling
    is($params->{unknown_field}, 'should be ignored', 'Unknown field preserved with ignore setting');
}

# Test page creation with inheritance differences
{
    my $params = {
        title => "About Us",
        slug => "about-us", 
        content => "Short page.",
        template => "about",
        show_in_menu => 1
    };
    
    my $rejects = $b->process('page', $params);
    is($rejects, undef, 'Page validation succeeds');
    
    # Check inherited defaults
    is($params->{status}, 'draft', 'Inherited default status');
    is($params->{author}, 'system', 'Inherited default author');
    
    # Check page-specific defaults
    is($params->{template}, 'about', 'Page template preserved');
    is($params->{show_in_menu}, 1, 'Show in menu setting preserved');
    
    # Check postprocessing inheritance
    is($params->{word_count}, 2, 'Inherited postprocessing worked on short content');
    is($params->{tag_count}, 0, 'Tag count correct for empty tags');
}

# Test complex validation failures across multiple features
{
    my $params = {
        title => "", # Too short after preprocessing
        slug => "123", # Will be converted to "123" by preprocessing, which should pass slug_format
        content => "lorem ipsum", # Fails custom validation
        status => "invalid", # Not in allowed values
        tags => ["a", "INVALID"], # First too short, second wrong format
        metadata => {
            priority => 10 # Outside allowed range
        }
    };
    
    my $rejects = $b->process('blog_post', $params);
    like($rejects, {
        title => { min_length => 1 },
        content => { validate => 1 },
        status => { one_of => ['draft', 'published', 'archived'] },
        'tags.0' => { min_length => 2 },
        'tags.1' => { tag_format => 1 },
        'metadata.priority' => { value_between => [1, 5] }
    }, 'Complex validation failures reported correctly across all features');
}

# Test schema inheritance with overrides
{
    my $params = {
        title => "Test Page",
        slug => "test",
        content => "X", # Very short - should work for page but not blog post
        template => "landing"
    };
    
    # Should fail for blog post (content too short)
    my $rejects = $b->process('blog_post', $params);
    is($rejects, { content => { min_length => 10 } }, 
       'Blog post rejects short content');
    
    # Should succeed for page (allows short content)
    $rejects = $b->process('page', $params);
    is($rejects, undef, 'Page allows short content due to inheritance override');
}

# Test all processing stages work together correctly
$b->register_schema('processing_chain', {
    params => {
        input => {
            required => 1,
            preprocess => sub {
                my $value = shift;
                return "preprocessed:$value";
            },
            min_length => 15, # Will validate the preprocessed value
            postprocess => sub {
                my $value = shift;
                return "postprocessed:$value";
            }
        }
    },
    postprocess => sub {
        my $params = shift;
        $params->{final} = "global:$params->{input}";
    }
});

{
    my $params = { input => "test" };
    my $rejects = $b->process('processing_chain', $params);
    is($rejects, undef, 'Processing chain validation succeeds');
    
    # Check all processing stages applied in correct order
    is($params->{input}, 'postprocessed:preprocessed:test', 
       'Pre and post processing applied in correct order');
    is($params->{final}, 'global:postprocessed:preprocessed:test',
       'Global postprocessing applied after parameter postprocessing');
}

# Test unknown parameter handling in different modes
{
    my $b_remove = Brannigan->new({ handle_unknown => 'remove' });
    $b_remove->register_schema('simple', {
        params => { name => { required => 1 } }
    });
    
    my $params = { name => 'test', unknown => 'remove me' };
    my $rejects = $b_remove->process('simple', $params);
    is($rejects, undef, 'Remove mode validation succeeds');
    ok(!exists $params->{unknown}, 'Unknown parameter removed');
    is($params->{name}, 'test', 'Known parameter preserved');
}

{
    my $b_reject = Brannigan->new({ handle_unknown => 'reject' });
    $b_reject->register_schema('simple', {
        params => { name => { required => 1 } }
    });
    
    my $params = { name => 'test', unknown => 'reject me' };
    my $rejects = $b_reject->process('simple', $params);
    is($rejects, { unknown => { unknown => 1 } }, 'Reject mode reports unknown');
}

# Test functional interface still works
{
    my $schema = {
        params => {
            test => { required => 1, min_length => 3 }
        }
    };
    
    my $params = { test => 'hello' };
    my $rejects = Brannigan::process($schema, $params);
    is($rejects, undef, 'Functional interface works');
}

done_testing();
#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# Test custom validators (both inline and registered)
my $b = Brannigan->new();

# Inline custom validators
$b->register_schema('inline_custom', {
    params => {
        username => {
            required => 1,
            min_length => 3,
            validate => sub {
                my $value = shift;
                return $value =~ /^[a-zA-Z0-9_]+$/ ? 1 : 0;
            }
        },
        password => {
            required => 1, 
            min_length => 8,
            validate => sub {
                my $value = shift;
                # Must contain at least one uppercase, lowercase, and digit
                return ($value =~ /[A-Z]/ && $value =~ /[a-z]/ && $value =~ /\d/) ? 1 : 0;
            }
        },
        email => {
            required => 1,
            validate => sub {
                my $value = shift;
                return $value =~ /^[^@]+@[^@]+\.[^@]+$/ ? 1 : 0;
            }
        }
    }
});

{
    my $params = {
        username => 'john_doe123',
        password => 'MyPass123',
        email => 'john@example.com'
    };
    my $rejects = $b->process('inline_custom', $params);
    is($rejects, undef, 'Inline custom validators succeed');
}

# Inline custom validator failures
{
    my $params = {
        username => 'john-doe!', # Invalid characters
        password => 'mypass123', # No uppercase
        email => 'not-an-email' # Invalid format
    };
    my $rejects = $b->process('inline_custom', $params);
    is($rejects, {
        username => { validate => 1 },
        password => { validate => 1 },
        email => { validate => 1 }
    }, 'Inline custom validator failures reported correctly');
}

# Registered custom validators
$b->register_validator('no_profanity', sub {
    my ($value, @forbidden_words) = @_;
    foreach my $word (@forbidden_words) {
        return 0 if $value =~ /\b\Q$word\E\b/i;
    }
    return 1;
});

$b->register_validator('credit_card', sub {
    my $value = shift;
    # Simple Luhn algorithm check
    $value =~ s/\D//g; # Remove non-digits
    return 0 if length($value) < 13 || length($value) > 19;
    
    my $sum = 0;
    my $alternate = 0;
    for (my $i = length($value) - 1; $i >= 0; $i--) {
        my $digit = substr($value, $i, 1);
        if ($alternate) {
            $digit *= 2;
            $digit = ($digit % 10) + int($digit / 10);
        }
        $sum += $digit;
        $alternate = !$alternate;
    }
    return ($sum % 10) == 0;
});

$b->register_validator('strong_password', sub {
    my ($value, $min_score) = @_;
    my $score = 0;
    
    $score++ if $value =~ /[a-z]/;       # lowercase
    $score++ if $value =~ /[A-Z]/;       # uppercase  
    $score++ if $value =~ /\d/;          # digits
    $score++ if $value =~ /[^a-zA-Z0-9]/; # special chars
    $score++ if length($value) >= 12;    # length bonus
    
    return $score >= $min_score;
});

$b->register_schema('registered_custom', {
    params => {
        comment => {
            required => 1,
            min_length => 1,
            no_profanity => ['spam', 'hate', 'offensive']
        },
        card_number => {
            required => 1,
            credit_card => 1
        },
        secure_password => {
            required => 1,
            min_length => 8,
            strong_password => 3 # Minimum score of 3
        }
    }
});

{
    my $params = {
        comment => 'This is a great product!',
        card_number => '4532015112830366', # Valid test card
        secure_password => 'MySecure123!'
    };
    my $rejects = $b->process('registered_custom', $params);
    is($rejects, undef, 'Registered custom validators succeed');
}

# Registered custom validator failures
{
    my $params = {
        comment => 'This is spam content',
        card_number => '1234567890123456', # Invalid card
        secure_password => 'weak'
    };
    my $rejects = $b->process('registered_custom', $params);
    like($rejects, {
        comment => { no_profanity => ['spam', 'hate', 'offensive'] },
        secure_password => { min_length => 8, strong_password => 3 }
    }, 'Registered custom validator failures reported correctly');
}

# Custom validators with multiple parameters
$b->register_validator('date_range', sub {
    my ($value, $start_date, $end_date) = @_;
    # Simple date comparison (assumes YYYY-MM-DD format)
    return $value ge $start_date && $value le $end_date;
});

$b->register_schema('date_test', {
    params => {
        event_date => {
            required => 1,
            matches => qr/^\d{4}-\d{2}-\d{2}$/,
            date_range => ['2023-01-01', '2023-12-31']
        }
    }
});

{
    my $params = { event_date => '2023-06-15' };
    my $rejects = $b->process('date_test', $params);
    is($rejects, undef, 'Multi-parameter custom validator succeeds');
}

{
    my $params = { event_date => '2024-06-15' }; # Outside range
    my $rejects = $b->process('date_test', $params);
    is($rejects, { 
        event_date => { date_range => ['2023-01-01', '2023-12-31'] }
    }, 'Multi-parameter custom validator failure reported correctly');
}

# Custom validators in nested structures
$b->register_validator('valid_skill_level', sub {
    my $value = shift;
    return $value =~ /^(beginner|intermediate|advanced|expert)$/i;
});

$b->register_schema('employee', {
    params => {
        skills => {
            array => 1,
            required => 1,
            values => {
                hash => 1,
                keys => {
                    name => { required => 1, min_length => 2 },
                    level => { 
                        required => 1,
                        valid_skill_level => 1 
                    }
                }
            }
        }
    }
});

{
    my $params = {
        skills => [
            { name => 'Perl', level => 'expert' },
            { name => 'JavaScript', level => 'intermediate' }
        ]
    };
    my $rejects = $b->process('employee', $params);
    is($rejects, undef, 'Custom validators in nested structures succeed');
}

{
    my $params = {
        skills => [
            { name => 'Perl', level => 'master' }, # Invalid level
            { name => 'JS', level => 'beginner' }
        ]
    };
    my $rejects = $b->process('employee', $params);
    is($rejects, { 'skills.0.level' => { valid_skill_level => 1 } },
       'Custom validator failure in nested structure reported correctly');
}

# Overriding built-in validators
$b->register_validator('required', sub {
    my ($value, $boolean) = @_;
    # Custom required: also considers whitespace-only strings as missing
    return 1 unless $boolean;
    return 0 unless defined $value;
    return 0 if $value =~ /^\s*$/; # Whitespace-only is considered missing
    return 1;
});

$b->register_schema('strict_required', {
    params => {
        name => { required => 1 },
        description => { required => 1 }
    }
});

{
    my $params = { name => '   ', description => '' }; # Whitespace and empty
    my $rejects = $b->process('strict_required', $params);
    is($rejects, {
        name => { required => 1 },
        description => { required => 1 }
    }, 'Overridden built-in validator works');
}

# Custom validator that modifies the value (though not recommended)
$b->register_validator('normalize_phone', sub {
    my $value = shift;
    # This is not recommended - validators should not modify values
    # Use preprocess instead, but testing it works
    $_[0] = $value; # Validators shouldn't modify, but let's test
    return $value =~ /^\d{3}-\d{3}-\d{4}$/;
});

# Test validator error messages contain the parameters
{
    my $params = {
        comment => 'This contains hate speech',
        card_number => '4532015112830366',
        secure_password => 'MySecure123!'
    };
    my $rejects = $b->process('registered_custom', $params);
    
    # Check that the rejected validator includes its parameters
    is($rejects->{comment}->{no_profanity}, ['spam', 'hate', 'offensive'],
       'Custom validator rejection includes parameters');
}

done_testing();
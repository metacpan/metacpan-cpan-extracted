#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# Test preprocessing functions
my $b = Brannigan->new();

# Basic preprocessing - trim whitespace
$b->register_schema('trim_test', {
    params => {
        name => {
            required => 1,
            preprocess => sub {
                my $value = shift;
                $value =~ s/^\s+//;
                $value =~ s/\s+$//;
                return $value;
            }
        }
    }
});

{
    my $params = { name => '   John Doe   ' };
    my $rejects = $b->process('trim_test', $params);
    is($rejects, undef, 'Preprocessing succeeds');
    is($params->{name}, 'John Doe', 'Whitespace trimmed correctly');
}

# Preprocessing that converts case
$b->register_schema('case_test', {
    params => {
        username => {
            required => 1,
            preprocess => sub {
                my $value = shift;
                return lc($value);
            }
        }
    }
});

{
    my $params = { username => 'JohnDOE' };
    my $rejects = $b->process('case_test', $params);
    is($rejects, undef, 'Case preprocessing succeeds');
    is($params->{username}, 'johndoe', 'Username converted to lowercase');
}

# Preprocessing that fixes data format
$b->register_schema('format_test', {
    params => {
        phone => {
            required => 1,
            preprocess => sub {
                my $value = shift;
                # Remove all non-digits, then format as XXX-XXX-XXXX
                $value =~ s/\D//g;
                if (length($value) == 10) {
                    $value =~ s/(\d{3})(\d{3})(\d{4})/$1-$2-$3/;
                }
                return $value;
            },
            matches => qr/^\d{3}-\d{3}-\d{4}$/
        }
    }
});

{
    my $params = { phone => '(555) 123-4567' };
    my $rejects = $b->process('format_test', $params);
    is($rejects, undef, 'Phone formatting preprocessing succeeds');
    is($params->{phone}, '555-123-4567', 'Phone formatted correctly');
}

# Preprocessing with validation failure
{
    my $params = { phone => '123' }; # Too short
    my $rejects = $b->process('format_test', $params);
    is($rejects, { phone => { matches => qr/^\d{3}-\d{3}-\d{4}$/ } }, 
       'Preprocessing can still result in validation failure');
}

# Preprocessing that converts strings to arrays
$b->register_schema('array_convert_test', {
    params => {
        tags => {
            array => 1,
            preprocess => sub {
                my $value = shift;
                # Convert comma-separated string to array
                if (!ref $value) {
                    return [split /,\s*/, $value];
                }
                return $value;
            },
            min_length => 1
        }
    }
});

{
    my $params = { tags => 'perl, programming, validation' };
    my $rejects = $b->process('array_convert_test', $params);
    is($rejects, undef, 'String to array preprocessing succeeds');
    is($params->{tags}, ['perl', 'programming', 'validation'], 
       'String converted to array correctly');
}

done_testing();
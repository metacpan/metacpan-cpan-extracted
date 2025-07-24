#!/usr/bin/env perl

use lib './lib';
use strict;
use warnings;

use Test2::V0;
use Brannigan;

# Test postprocessing functions
my $b = Brannigan->new();

# Basic postprocessing - convert number to string
$b->register_schema('section_test', {
    params => {
        section => {
            required => 1,
            integer => 1,
            value_between => [1, 3],
            postprocess => sub {
                my $val = shift;
                return $val == 1 ? 'reviews'
                     : $val == 2 ? 'recipes'
                     :             'general';
            }
        }
    }
});

{
    my $params = { section => 1 };
    my $rejects = $b->process('section_test', $params);
    is($rejects, undef, 'Postprocessing succeeds');
    is($params->{section}, 'reviews', 'Number converted to section name');
}

{
    my $params = { section => 2 };
    my $rejects = $b->process('section_test', $params);
    is($rejects, undef, 'Postprocessing succeeds for section 2');
    is($params->{section}, 'recipes', 'Number 2 converted to recipes');
}

{
    my $params = { section => 3 };
    my $rejects = $b->process('section_test', $params);
    is($rejects, undef, 'Postprocessing succeeds for section 3');
    is($params->{section}, 'general', 'Number 3 converted to general');
}

# Postprocessing that formats data
$b->register_schema('currency_test', {
    params => {
        price => {
            required => 1,
            integer => 1,
            min_value => 0,
            postprocess => sub {
                my $val = shift;
                return sprintf('$%.2f', $val / 100);
            }
        }
    }
});

{
    my $params = { price => 1250 }; # cents
    my $rejects = $b->process('currency_test', $params);
    is($rejects, undef, 'Currency postprocessing succeeds');
    is($params->{price}, '$12.50', 'Cents converted to dollar format');
}

# Postprocessing that creates objects/structures
$b->register_schema('coordinate_test', {
    params => {
        lat => { required => 1, matches => qr/^-?\d+\.\d+$/ },
        lng => { required => 1, matches => qr/^-?\d+\.\d+$/ }
    },
    postprocess => sub {
        my $params = shift;
        if (exists $params->{lat} && exists $params->{lng}) {
            $params->{coordinates} = {
                latitude => $params->{lat},
                longitude => $params->{lng}
            };
            delete $params->{lat};
            delete $params->{lng};
        }
    }
});

{
    my $params = { lat => '40.7128', lng => '-74.0060' };
    my $rejects = $b->process('coordinate_test', $params);
    is($rejects, undef, 'Global postprocessing succeeds');
    is($params->{coordinates}, 
       { latitude => '40.7128', longitude => '-74.0060' },
       'Coordinates combined into object');
    ok(!exists $params->{lat}, 'Original lat removed');
    ok(!exists $params->{lng}, 'Original lng removed');
}

# Postprocessing with validation failure (postprocessing shouldn't run)
$b->register_schema('fail_test', {
    params => {
        value => {
            required => 1,
            min_length => 5,
            postprocess => sub {
                my $val = shift;
                return uc($val);
            }
        }
    }
});

{
    my $params = { value => 'hi' }; # Too short
    my $rejects = $b->process('fail_test', $params);
    is($rejects, { value => { min_length => 5 } }, 'Validation fails');
    is($params->{value}, 'hi', 'Postprocessing not applied when validation fails');
}

# Complex global postprocessing that combines multiple fields
$b->register_schema('date_combine_test', {
    params => {
        year => { required => 1, integer => 1, value_between => [1900, 2100] },
        month => { required => 1, integer => 1, value_between => [1, 12] },
        day => { required => 1, integer => 1, value_between => [1, 31] }
    },
    postprocess => sub {
        my $params = shift;
        if ($params->{year} && $params->{month} && $params->{day}) {
            $params->{date} = sprintf('%04d-%02d-%02d', 
                                    $params->{year}, $params->{month}, $params->{day});
        }
    }
});

{
    my $params = { year => 2023, month => 12, day => 25 };
    my $rejects = $b->process('date_combine_test', $params);
    is($rejects, undef, 'Date combination succeeds');
    is($params->{date}, '2023-12-25', 'Date formatted correctly');
    is($params->{year}, 2023, 'Original year preserved');
}

done_testing();
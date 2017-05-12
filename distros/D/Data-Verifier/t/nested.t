use strict;
use Test::More;

use Data::Verifier::Nested;

my $dv = Data::Verifier::Nested->new(
    filters => [ qw(trim) ],
    profile => {
        name => {
            first_name => { type => 'Str', required => 1 },
            last_name  => { type => 'Str', required => 1 },
        },
        age  => { type => 'Int' },
        sign => { required => 1 },
    }
);

# A successful verification
{
    # Pass in a hash of data
    my $results = $dv->verify({
        name => { first_name => 'Cory  ', last_name => 'Watson' },
        age  => 31,
        sign => 'Taurus'
    });

    ok( $results->success, '... this did pass' );

    ok( !$results->is_invalid('name.first_name'), '... this is not invalid' );
    ok( !$results->is_invalid('name.last_name'), '... this is not invalid' );
    ok( !$results->is_invalid('age'), '... this is not invalid' );
    ok( !$results->is_invalid('sign'), '... this is not invalid' );

    ok( !$results->is_missing('name.first_name'), '... this is not missing' );
    ok( !$results->is_invalid('name.last_name'), '... this is not missing' );
    ok( !$results->is_missing('age'), '... this is not missing' );
    ok( !$results->is_missing('sign'), '... this is not missing' );

    is( $results->get_original_value('name.first_name'), 'Cory  ', '... this is the original value');
    is( $results->get_value('name.first_name'), 'Cory', '... this is the filtered value');
    is( $results->get_value('age'), 31, '... got the right value back');
    is( $results->get_value('sign'), 'Taurus', '... got the right value back');
}

# A bad verification
{
    # Pass in a hash of data
    my $results = $dv->verify({
        name => { first_name => 'Cory  ', last_name => 'Watson' },
        age  => 'foobar'
    });

    ok( !$results->success, '... this did not pass' );

    ok( !$results->is_invalid('name.first_name'), '... this is not invalid' );
    ok( !$results->is_invalid('name.last_name'), '... this is not invalid' );
    ok( $results->is_invalid('age'), '... this is invalid' );

    ok( !$results->is_missing('name.first_name'), '... this is not missing' );
    ok( !$results->is_invalid('name.last_name'), '... this is not missing' );
    ok( $results->is_missing('sign'), '... this is missing' );

    is( $results->get_original_value('name.first_name'), 'Cory  ', '... this is the original value');
    is( $results->get_value('name.first_name'), 'Cory', '... this is the filtered value');
    is( $results->get_value('age'), undef, '... got nothing back');
}


done_testing;
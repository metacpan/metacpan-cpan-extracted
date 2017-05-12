use strict;
use warnings;
use Test::More;
use Data::TreeValidator::Sugar qw( leaf branch );
use Data::TreeValidator::Constraints qw( length required options );

{
    package Artist;
    use Moose;

    has [qw(
        name sort_name gender_id type_id country_id
        country_id comment ipi_code
    )] => ( is => 'ro' );
}

my $validator = branch {
    name => leaf(constraints => [ required ]),
    sort_name => leaf(constraints => [ required ]),
    gender_id => leaf(constraints => [ options(undef, 1, 2) ]),
    comment => leaf(constraints => [ length(max => 30) ])
};

ok($validator->process({
    name => 'Spor',
    comment => 'Drum & bass artist',
    sort_name => 'Spor',
    gender_id => 1
})->valid);

ok(!$validator->process({
    name => 'Spor',
    comment => '_______________________________',
    sort_name => 'Spoaaaarr',
    gender_id => 1
})->valid);

ok(!$validator->process({
    name => 'Spor',
    comment => 'Drum & bass artist',
    sort_name => 'Spor',
    gender_id => 100
})->valid);

done_testing;

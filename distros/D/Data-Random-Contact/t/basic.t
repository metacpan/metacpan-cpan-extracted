use strict;
use warnings;

use Test::More 0.88;

use Data::Random::Contact;

my $drc = Data::Random::Contact->new();

my $person = $drc->person();

for my $key (qw( given middle surname )) {
    ok( defined $person->{$key}, "$key is defined for person" );
}

like( $person->{gender}, qr/^(?:fe)?male$/, 'gender is male or female' );

isa_ok( $person->{birth_date}, 'DateTime' );

for my $key (qw( home mobile work )) {
    ok( defined $person->{phone}{$key}, "$key phone is defined for person" );
}

for my $key (qw( home  work )) {
    ok(
        defined $person->{address}{$key},
        "$key address is defined for person"
    );
}

done_testing();

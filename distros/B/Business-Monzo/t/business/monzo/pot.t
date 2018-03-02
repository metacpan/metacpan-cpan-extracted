#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Mojo::JSON;

use Business::Monzo::Client;

use_ok( 'Business::Monzo::Pot' );
isa_ok(
    my $Pot = Business::Monzo::Pot->new(
        'id'              => "pot_0000778xxfgh4iu8z83nWb",
        'name'            => "Savings",
        'style'           => "piggy_bank",
        'balance'         => 133700,
        'currency'        => "GBP",
        'created'         => "2017-11-09T12:30:53.695Z",
        'updated'         => "2017-11-09T12:30:53.695Z",
        'client'          => Business::Monzo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Monzo::Pot'
);

can_ok(
    $Pot,
    qw/
        id
        name
        style
        balance
        created
        updated
        deleted
    /,
);

no warnings 'redefine';

*Business::Monzo::Client::api_get = sub {
    {
        "id"         => "pot_0000778xxfgh4iu8z83nWb",
        "name"       => "Savings",
        "style"      => "piggy_bank",
        "balance"    => 133700,
        "currency"   => "GBP",
        "created"    => "2017-11-09T12:30:53.695Z",
        "updated"    => "2017-11-09T12:30:53.695Z",
    };
};

ok( $Pot = $Pot->get,'->get' );
isa_ok( $Pot->currency,'Data::Currency' );
isa_ok( $Pot->created,'DateTime' );
isa_ok( $Pot->updated,'DateTime' );

ok( $Pot->to_hash,'to_hash' );
ok( $Pot->as_json,'as_json' );
ok( $Pot->TO_JSON,'TO_JSON' );

done_testing();

# vim: ts=4:sw=4:et

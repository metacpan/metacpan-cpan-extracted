#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Institution' );
isa_ok(
    my $Institution = Business::GoCardless::Institution->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'monzo',
    ),
    'Business::GoCardless::Institution'
);

can_ok(
    $Institution,
    qw/
        endpoint
        autocompletes_collect_bank_account
        country_code
        icon_url
        id
        limits
        logo_url
        name
        roles
        status

        enabled
        disabled
        temporarily_disabled
    /,
);

is( $Institution->endpoint,'/institutions/%s','endpoint' );
is( $Institution->uri,'https://api.gocardless.com/institutions/monzo','->uri' );

note( "status checks" );

ok( ! $Institution->enabled,'! ->enabled when no status' );

my @statuses = qw/ enabled disabled temporarily_disabled /;

foreach my $status ( @statuses ) {
    $Institution->status( $status );
    ok( $Institution->$status,"->$status" );
    ok( ! $Institution->$_,"! ->$_ when $status" )
        for grep { $_ ne $status } @statuses;
}

done_testing();

# vim: ts=4:sw=4:et

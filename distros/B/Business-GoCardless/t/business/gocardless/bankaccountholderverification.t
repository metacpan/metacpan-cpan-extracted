#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::BankAccountHolderVerification' );
isa_ok(
    my $Verification = Business::GoCardless::BankAccountHolderVerification->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::BankAccountHolderVerification'
);

can_ok(
    $Verification,
    qw/
        endpoint
        actual_account_name
        id
        result
        status
        type

        pending
        completed
    /,
);

is( $Verification->endpoint,'/bank_account_holder_verifications/%s','endpoint' );
is( $Verification->uri,'https://api.gocardless.com/bank_account_holder_verifications/ID123','->uri' );

note( "status checks" );

ok( ! $Verification->pending,'! ->pending when no status' );

my @statuses = qw/ pending completed /;

foreach my $status ( @statuses ) {
    $Verification->status( $status );
    ok( $Verification->$status,"->$status" );
    ok( ! $Verification->$_,"! ->$_ when $status" )
        for grep { $_ ne $status } @statuses;
}

done_testing();

# vim: ts=4:sw=4:et

#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Address' );
isa_ok(
    my $Address = Business::Fixflo::Address->new(
        'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::Address'
);

can_ok(
    $Address,
    qw/
		url
		get
		to_hash
		to_json

        AddressLine1
        AddressLine2
        Town
        County
        PostCode
        Country
    /,
);

done_testing();

# vim: ts=4:sw=4:et

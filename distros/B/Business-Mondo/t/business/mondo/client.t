#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

use_ok( 'Business::Mondo::Client' );
isa_ok(
    my $Client = Business::Mondo::Client->new(
        token   => 'MvYX0i6snRh/1PXfPoc6',
        api_url => 'some application',
    ),
    'Business::Mondo::Client'
);

can_ok(
    $Client,
    qw/
        token
        api_url
    /,
);

done_testing();

# vim: ts=4:sw=4:et

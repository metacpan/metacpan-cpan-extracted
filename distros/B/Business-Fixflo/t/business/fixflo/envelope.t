#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Envelope' );
throws_ok(
    sub {
        my $Envelope = Business::Fixflo::Envelope->new(
            'client'          => Business::Fixflo::Client->new(
                username      => 'foo',
                password      => 'bar',
                custom_domain => 'baz',
            ),
        ),
    },
    qr/Missing required arguments/,
    '->new throws when attributes missing'
);

$Business::Fixflo::Client::request_data = {
    ( map { $_ => $_ } qw/ path params headers content / )
};

throws_ok(
    sub {
        my $Envelope = Business::Fixflo::Envelope->new(
            'Entity'             => {},
            'Errors'             => [ qw/ here is my error / ],
            'HttpStatusCodeDesc' => 'OK',
            'HttpStatusCode'     => '200',
            'Messages'           => [],
            'client'             => Business::Fixflo::Client->new(
                username         => 'foo',
                password         => 'bar',
                custom_domain    => 'baz',
            ),
        ),
    },
    'Business::Fixflo::Exception',
    '->new throws when Errors has content'
);

like(
    $@->message,
    qr/here, is, my, error/,
    ' ... with expected message'
);

cmp_deeply(
    $@->request,
    { ( map { $_ => $_ } qw/ path params headers content / ) },
    ' ... with original request'
);

isa_ok(
    my $Envelope = Business::Fixflo::Envelope->new(
        'Entity'             => {},
        'Errors'             => [],
        'HttpStatusCodeDesc' => 'OK',
        'HttpStatusCode'     => '200',
        'Messages'           => [],
        'client'             => Business::Fixflo::Client->new(
            username         => 'foo',
            password         => 'bar',
            custom_domain    => 'baz',
        ),
    ),
    'Business::Fixflo::Envelope',
    'normal instantiation with no Errors'
);

done_testing();

# vim: ts=4:sw=4:et

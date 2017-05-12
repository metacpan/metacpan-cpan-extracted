#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Business::CPI::Base::Exception;
use Test::Exception;
use Test::More;
use Try::Tiny;

throws_ok {
    Business::CPI::Base::Exception->throw(
        type => 'unknown',
        message => 'error code 123',
        gateway_data => {
            foo => 1,
            bar => 2,
        }
    );
} 'Business::CPI::Base::Exception', q{throws exception};


my $exception = $@;

is( $exception->type, 'unknown', q{code is 123} );
is( $exception->message, 'error code 123', q{message is ok} );
is_deeply(
    $exception->gateway_data,
    { foo => 1, bar => 2 },
    q{gateway_data is ok}
);

done_testing;

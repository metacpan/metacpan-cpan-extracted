#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::Exception;
use Test::More;

use AnyEvent::Net::Curl::Queued;
use AnyEvent::Net::Curl::Queued::Easy;

## no critic (ProhibitComplexRegexes)

throws_ok
    { AnyEvent::Net::Curl::Queued->new(1 .. 3) }
    qr(^Should\s+be\s+initialized\s+as\s+AnyEvent::Net::Curl::Queued->new\b)sx,
    q(non-hash used to initialize AnyEvent::Net::Curl::Queued);

throws_ok
    { AnyEvent::Net::Curl::Queued::Easy->new(1 .. 3) }
    qr(^Should\s+be\s+initialized\s+as\s+AnyEvent::Net::Curl::Queued::Easy->new\b)sx,
    q(non-hash used to initialize AnyEvent::Net::Curl::Queued::Easy);

done_testing(2);

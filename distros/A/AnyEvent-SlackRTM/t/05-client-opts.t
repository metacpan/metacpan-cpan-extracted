#!/usr/bin/env perl
use v5.14;

use Test::More tests => 4;
use AnyEvent::SlackRTM;

my $rtm;
my $token = 'stub';

$rtm = AnyEvent::SlackRTM->new($token);
ok($rtm, 'construction with no client options');

$rtm = AnyEvent::SlackRTM->new($token, {});
ok($rtm, 'construction with empty client options');

$rtm = AnyEvent::SlackRTM->new($token, { timeout => 123 });
is($rtm->{client}{timeout}, 123, 'construction with valid client options');

$rtm = eval { AnyEvent::SlackRTM->new($token, 'bazinga'); };
like($@, qr/Client options must be passed as a HashRef/, 'dies on wrong client options');

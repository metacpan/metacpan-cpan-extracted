#! perl

use strict;
use warnings;

use Test::More;

use Crypt::OpenSSL3;

my @macs = Crypt::OpenSSL3::MAC->list_all_provided;
ok @macs, 'Got macs';

my $has_hmac = grep { $_->get_name eq 'HMAC' } @macs;
ok $has_hmac, 'Has SHA-256';

my $mac = Crypt::OpenSSL3::MAC->fetch('HMAC');
ok $mac;

my $key = "0123456789ABCDEF";
my $context = Crypt::OpenSSL3::MAC::Context->new($mac);
ok $context->init($key, { digest => 'SHA2-256' });

ok $context->update("Hello, World!") or die;
my $hash = $context->final;
my $expected = pack 'H*', '03bbb7cc7b6b70c53b42747e0af9ceabe0dadc022e5ff4233c5b730bfe360f71';
is $hash, $expected;

done_testing;


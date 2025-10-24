#! perl

use strict;
use warnings;

use Test::More;

use Crypt::OpenSSL3;


my $ctx = Crypt::OpenSSL3::PKey::Context->new_from_name("RSA");
ok $ctx;
ok $ctx->keygen_init;
ok $ctx->set_params({ bits => 2048, primes => 2, e => 65537 });

my $pkey = $ctx->generate;
ok $pkey;

my $ctx2 = Crypt::OpenSSL3::PKey::Context->new_from_pkey($pkey);
ok $ctx2;

ok $ctx2->encapsulate_init;
ok $ctx2->set_params({ operation => "RSASVE" });
my ($wrapped, $gen) = $ctx2->encapsulate;
ok $wrapped;
ok $gen;

my $ctx3 = Crypt::OpenSSL3::PKey::Context->new_from_pkey($pkey);
ok $ctx3;
ok $ctx3->decapsulate_init;
ok $ctx3->set_params({ operation => "RSASVE" });
my $unwrapped = $ctx3->decapsulate($wrapped);
ok $unwrapped;

is $unwrapped, $gen;

done_testing;

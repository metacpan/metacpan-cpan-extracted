#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::HMAC::DRBG;
use Crypt::Bear::AES_CTR::DRBG;

my $system_seeder_name = Crypt::Bear::PRNG->system_seeder_name;
ok($system_seeder_name);

my $hmac_drbg = Crypt::Bear::HMAC::DRBG->new('sha256', '');
is $hmac_drbg->system_seed, $system_seeder_name ne 'none', 'System seeding successful';

my $first = $hmac_drbg->generate(16);
my $second = $hmac_drbg->generate(16);

isnt($first, $second);

my $aes_drbg = Crypt::Bear::AES_CTR::DRBG->new('');
$aes_drbg->system_seed;

my $third = $aes_drbg->generate(16);
my $fourth = $aes_drbg->generate(16);

isnt($third, $fourth);

done_testing;

#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::BaseFunc qw/bn_mod_sqrt/;
use Crypt::OpenSSL::Bignum;
use Data::Dumper;

my $p = Crypt::OpenSSL::Bignum->new_from_hex('05');
my $a = Crypt::OpenSSL::Bignum->new_from_hex('04');
my $s = bn_mod_sqrt($a, $p);
ok($s->to_hex eq '03');

my $b = Crypt::OpenSSL::Bignum->new_from_hex('02');
my $z = bn_mod_sqrt($b, $p);
ok($z, undef);

done_testing();

#! perl

use strict;
use warnings;

use Test::More;

use Crypt::OpenSSL3;

my @digests = Crypt::OpenSSL3::KDF->list_all_provided;
ok @digests, 'Got digests';

my $has_sha256 = grep { $_->get_name eq 'HKDF' } @digests;
ok $has_sha256, 'Has SHA-256';

my $kdf = Crypt::OpenSSL3::KDF->fetch('HKDF');
ok $kdf;

my $context = Crypt::OpenSSL3::KDF::Context->new($kdf);

my $derived = $context->derive(32, { digest => 'SHA2-256', key => 'Hello, World!' });
ok $derived;

done_testing;


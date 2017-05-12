#!perl

use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

delete $ENV{GPG_AGENT_INFO};
$ENV{GNUPGHOME} = 't/gpg';

BEGIN {
    use_ok ('Crypt::GpgME');
}

my $fpr = '758E67AA4F0A13F7897AE49A1D57D5E006E16945';

my $ctx = Crypt::GpgME->new;
isa_ok ($ctx, 'Crypt::GpgME');

my $key;

lives_ok (sub {
        $key = $ctx->get_key($fpr);
}, 'get_key');

isa_ok ($key, 'Crypt::GpgME::Key');

ok (!$key->secret, 'get_key get\'s public keys');

lives_ok (sub {
        $key = $ctx->get_key($fpr, 1);
}, 'get_key secret');

ok ($key->secret, 'get_key get\'s secret keys, if asked');

#!perl

use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;

BEGIN {
	use_ok( 'Crypt::GpgME' );
}

delete $ENV{GPG_AGENT_INFO};
$ENV{GNUPGHOME} = 't/gpg';

my $ctx = Crypt::GpgME->new;
isa_ok ($ctx, 'Crypt::GpgME');

$ctx->set_passphrase_cb(sub { 'abc' });

my $data = 'test test test';

my $signed;
lives_ok (sub {
        $signed = $ctx->sign($data, 'clear');
}, 'clearsign');

isa_ok ($signed, 'Crypt::GpgME::Data');
isa_ok ($signed, 'IO::Handle');

my $signed_text = do { local $/; <$signed> };

like ($signed_text, qr/$data/, 'signed text looks sane');

my $result;
my $verify_plain;
lives_ok (sub {
        ($result, $verify_plain) = $ctx->verify($signed);
}, 'verify');

isa_ok ($verify_plain, 'Crypt::GpgME::Data');
is (do { local $/; <$verify_plain> }, "$data\n", 'verify plaintest matches');

is (ref $result, 'HASH', 'result is a hash ref');

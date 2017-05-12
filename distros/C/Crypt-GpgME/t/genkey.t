#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

BEGIN {
	use_ok( 'Crypt::GpgME' );
}

my $tmp_dir = 't/var';

delete $ENV{GPG_AGENT_INFO};
$ENV{GNUPGHOME} = $tmp_dir;

mkdir $tmp_dir;

my $params = <<'EOP';
<GnupgKeyParms format="internal">
Key-Type: DSA
Key-Length: 1024
Subkey-Type: ELG-E
Subkey-Length: 1024
Name-Real: J. Random Hacker
Name-Comment: just another perl hacker
Name-Email: jrh@example.com
Expire-Date: 0
Passphrase: affe
</GnupgKeyParms>
EOP

my $ctx = Crypt::GpgME->new;
$ctx->set_protocol('OpenPGP');

lives_ok(sub {
    my ($result, $pub_key, $sec_key) = $ctx->genkey($params);
}, 'openpgp genkey works');

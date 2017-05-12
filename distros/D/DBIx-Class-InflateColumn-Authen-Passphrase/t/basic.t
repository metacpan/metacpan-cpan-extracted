use strict;
use warnings;
use Test::More 0.89;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestSchema;
use SQL::Translator;
use Authen::Passphrase::SaltedDigest;
use Authen::Passphrase::BlowfishCrypt;

my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:');
$schema->deploy;

my $rs = $schema->resultset('Foo');

my $digest_ppr = Authen::Passphrase::SaltedDigest->new(
    algorithm   => 'SHA-1',
    salt_random => 20,
    passphrase  => 'moo',
);

my $crypt_ppr = Authen::Passphrase::BlowfishCrypt->new(
    cost        => 8,
    salt_random => 1,
    passphrase  => 'moo',
);

my $id = $rs->create({
    passphrase_rfc2307 => $digest_ppr,
    passphrase_crypt   => $crypt_ppr,
})->id;

my $row = $rs->find({ id => $id });

like $row->get_column('passphrase_rfc2307'), qr/^\{SSHA\}/,
    'column stored as rfc2307 salted SHA digest';

like $row->get_column('passphrase_crypt'), qr/^\$2a\$/,
    'column stored as unix blowfish crypt';

for my $t (qw(rfc2307 crypt)) {
    my $ppr = $row->${\"passphrase_${t}"};
    isa_ok $ppr, 'Authen::Passphrase';

    ok !$ppr->match('affe'), 'rejects wrong passphrase';
    ok $ppr->match('moo'), 'accepts correct passphrase';
}

done_testing;

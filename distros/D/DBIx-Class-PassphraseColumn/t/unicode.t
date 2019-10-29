use strict;
use warnings;
use warnings FATAL => 'utf8';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use Test::More 0.89;

use lib 't/lib';
use TestSchema;

my $schema = TestSchema->connect('dbi:SQLite:dbname=:memory:');

my $sql = do { open my $fh, '<:raw', 't/lib/TestSchema.sql' or die $!; local $/; <$fh> };
$schema->storage->dbh->do($sql);

my $rs = $schema->resultset('Foo');

{
    my $id = $rs->create({
        passphrase_rfc2307 => 'mōőo',
        passphrase_crypt   => 'mōőo',
    })->id;

    my $row = $rs->find({ id => $id });

    like $row->get_column('passphrase_rfc2307'), qr/^\{SSHA\}/,
        'column stored as rfc2307 salted SHA digest after create';

    like $row->get_column('passphrase_crypt'), qr/^\$2a\$/,
        'column stored as unix blowfish crypt after create';

    $row->update({
        passphrase_rfc2307 => 'mōőo',
        passphrase_crypt   => 'mōőo',
    });

    like $row->get_column('passphrase_rfc2307'), qr/^\{SSHA\}/,
        'column stored as rfc2307 salted SHA digest after update';

    like $row->get_column('passphrase_crypt'), qr/^\$2a\$/,
        'column stored as unix blowfish crypt after update';

    for my $t (qw(rfc2307 crypt)) {
        ok !$row->${\"check_passphrase_${t}"}('mōőokooh'),
            'rejects incorrect passphrase using check method';
        ok $row->${\"check_passphrase_${t}"}('mōőo'),
            'accepts correct passphrase using check method';
    }
}

done_testing;

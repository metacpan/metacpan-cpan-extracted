#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Encode qw(encode_utf8);
use Test::More;
use Test::SQLite;

use lib 't/lib';
use Schema;

use_ok 'Crypt::Passphrase::Argon2';
use_ok 'DBIx::Class::EncodedColumn::Crypt::Passphrase::Argon2';

my $sqlite = Test::SQLite->new;

my $schema = Schema->connect($sqlite->dsn, '', '');
isa_ok $schema, 'Schema';

$schema->deploy;

my $result = $schema->resultset('Argon2')->create({
  id       => 1,
  argon2_1 => 'test1',
  argon2_2 => 'test1',
});
isa_ok $result, 'Schema::Result::Argon2';

ok !$result->argon2_1_check('bogus'), 'bogus encode_check failure';
ok !$result->argon2_2_check('bogus'), 'bogus encode_check failure';

ok $result->argon2_1_check('test1'), 'encode_check pass';
ok $result->argon2_2_check('test1'), 'encode_check pass';

$result->argon2_1('test2');
$result->argon2_2('test2');
ok $result->argon2_1_check('test2'), 'encode_check pass';
ok $result->argon2_2_check('test2'), 'encode_check pass';

$result->argon2_1(encode_utf8('官话'));
ok $result->argon2_1_check('官话'), 'encode_check pass';

$result->argon2_1(undef);
$result->argon2_2(undef);
is $result->argon2_1, undef, 'is set to undef';
is $result->argon2_2, undef, 'is set to undef';
ok !$result->argon2_1_check(undef), 'undef encode_check failure';
ok !$result->argon2_2_check(undef), 'undef encode_check failure';

done_testing();

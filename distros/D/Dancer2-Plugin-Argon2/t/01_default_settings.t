#!perl

use lib './lib';
use strict;
use warnings;
use Test::More tests => 3;

use Dancer2;
use Dancer2::Plugin::Argon2;

my $password = 'some-secret-password';
my $passphrase_generated;

subtest 'passphrase object' => sub {
    my $passphrase_obj = passphrase($password);
    isa_ok( $passphrase_obj, 'Dancer2::Plugin::Argon2::Passphrase' );
    eval { passphrase() };
    like $@, qr/^Please provide password argument/, 'die with empty password argument';
};

subtest 'passphrase->encoded' => sub {
    $passphrase_generated = passphrase($password)->encoded;
    like $passphrase_generated, qr/^\$argon2id\$v=19\$m=32768,t=3,p=1\$[\w\+\$\/]+\z/, 'with default settings';
};

subtest 'passphrase->matches' => sub {
    ok passphrase($password)->matches($passphrase_generated), 'correct password matched';
    ok !passphrase('bad-password')->matches($passphrase_generated), 'incorrect password doesn\'t match';
};

#!/usr/bin/env perl

use warnings;
use strict;

use FindBin qw($Bin);

use Test::More tests => 7;

use App::GroupSecret::File;

my $nonexistent = App::GroupSecret::File->new("$Bin/keyfiles/nonexistent.yml");

is_deeply $nonexistent->info, {
    version => 1,
    keys    => {},
    secret  => undef,
}, 'newly initialized file is empty';

my $empty = App::GroupSecret::File->new("$Bin/keyfiles/empty.yml");

is_deeply $empty->info, {
    version => 1,
    keys    => {},
    secret  => undef,
}, 'empty file info matches';

is $empty->secret, undef, 'empty secret is undef';
is $empty->version, 1, 'empty version is one';

SKIP: {
    skip 'requires ssh-keygen', 2;

    my $key1 = $empty->add_key("$Bin/keys/foo_rsa.pub");
    is_deeply $key1, {
        comment             => 'foo',
        filename            => 'foo_rsa.pub',
        secret_passphrase   => undef,
        type                => 'rsa',
    }, 'add_key in scalar context works';

    $empty->delete_key('89b3fb766cf9568ea81adfba1cba7d05');
    is_deeply $empty->keys, {}, 'file is empty again after delete_key';
};

my $basic = App::GroupSecret::File->new("$Bin/keyfiles/basic.yml");

is_deeply $basic->keys, {
    '89b3fb766cf9568ea81adfba1cba7d05' => {
        comment             => 'foo',
        filename            => 'foo_rsa.pub',
        secret_passphrase   => undef,
        type                => 'rsa',
    },
}, 'keys accessor works';


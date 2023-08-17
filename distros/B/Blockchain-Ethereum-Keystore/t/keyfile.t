#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::Keystore::Keyfile;

# https://ethereum.org/pt-br/developers/docs/data-structures-and-encoding/web3-secret-storage/#PBKDF2-SHA-256
subtest "v3_pbkdf2_ctr" => sub {
    my $private_key = pack "H*", "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d";
    my $password    = "testpassword";

    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;

    my $key = $keyfile->import_file("./t/resources/pbkdf2_v3.json", $password);
    is $key->private_key->export, $private_key;

    $key = $keyfile->import_key(Blockchain::Ethereum::Keystore::Key->new(private_key => $private_key), $password);
    is $key->private_key->export, $private_key;
};

# https://ethereum.org/pt-br/developers/docs/data-structures-and-encoding/web3-secret-storage/#scrypt
subtest "v3_scrypt_ctr" => sub {
    my $private_key = pack "H*", "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d";
    my $password    = "testpassword";

    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;

    my $key = $keyfile->import_file("./t/resources/scrypt_v3.json", $password);
    is $key->private_key->export, $private_key;

    $key = $keyfile->import_key(Blockchain::Ethereum::Keystore::Key->new(private_key => $private_key), $password);
    is $key->private_key->export, $private_key;
};

done_testing;

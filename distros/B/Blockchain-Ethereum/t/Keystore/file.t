#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp    qw(tempfile);
use JSON::MaybeXS qw(decode_json);
use Blockchain::Ethereum::Keystore::File;
use Blockchain::Ethereum::Key;

# Test data
my $private_key_hex   = "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d";
my $private_key_bytes = pack "H*", $private_key_hex;
my $password          = "testpassword";

subtest "from_file - v3 pbkdf2" => sub {
    my $keyfile = Blockchain::Ethereum::Keystore::File->from_file("./t/Keystore/resources/pbkdf2_v3.json", $password);

    isa_ok $keyfile,              'Blockchain::Ethereum::Keystore::File';
    isa_ok $keyfile->private_key, 'Blockchain::Ethereum::Key';
    is $keyfile->private_key->export, $private_key_bytes, 'private key matches';
    is $keyfile->password,            $password,          'password stored correctly';

    # Test against actual file data
    is $keyfile->version,    3,                                                                  'version is 3';
    is $keyfile->id,         '3198bc9c-6672-5ab3-d995-4942343ae5b6',                             'ID matches file data';
    is $keyfile->iv,         '6087dab2f9fdbbfaddc31a909735c1e6',                                 'IV matches file data';
    is $keyfile->ciphertext, '5318b4d5bcd28de64ee5559e671353e16f075ecae9f99c7a79a38af5f869aa46', 'ciphertext matches file data';
    is $keyfile->mac,        '517ead924a9d0dc3124507e3393d175ce3ff7c1e96529c6c555ce9e51205e9b2', 'MAC matches file data';

    # Test KDF parameters
    isa_ok $keyfile->kdf, 'Blockchain::Ethereum::Keystore::KDF';
    is $keyfile->kdf->algorithm, 'pbkdf2',                                                           'KDF algorithm is pbkdf2';
    is $keyfile->kdf->dklen,     32,                                                                 'KDF dklen is correct';
    is $keyfile->kdf->c,         262144,                                                             'KDF iteration count is correct';
    is $keyfile->kdf->prf,       'hmac-sha256',                                                      'KDF PRF is correct';
    is $keyfile->kdf->salt,      'ae3cd4e7013836a3df6bd7241b12db061dbe2c6785853cce422d148a624ce0bd', 'KDF salt matches file data';
};

subtest "from_file - v3 scrypt" => sub {
    my $keyfile = Blockchain::Ethereum::Keystore::File->from_file("./t/Keystore/resources/scrypt_v3.json", $password);

    isa_ok $keyfile,              'Blockchain::Ethereum::Keystore::File';
    isa_ok $keyfile->private_key, 'Blockchain::Ethereum::Key';
    is $keyfile->private_key->export, $private_key_bytes, 'private key matches';
    is $keyfile->password,            $password,          'password stored correctly';

    # Test against actual file data
    is $keyfile->version,    3,                                                                  'version is 3';
    is $keyfile->id,         '3198bc9c-6672-5ab3-d995-4942343ae5b6',                             'ID matches file data';
    is $keyfile->iv,         '83dbcc02d8ccb40e466191a123791e0e',                                 'IV matches file data';
    is $keyfile->ciphertext, 'd172bf743a674da9cdad04534d56926ef8358534d458fffccd4e6ad2fbde479c', 'ciphertext matches file data';
    is $keyfile->mac,        '2103ac29920d71da29f15d75b4a16dbe95cfd7ff8faea1056c33131d846e3097', 'MAC matches file data';

    # Test KDF parameters
    isa_ok $keyfile->kdf, 'Blockchain::Ethereum::Keystore::KDF';
    is $keyfile->kdf->algorithm, 'scrypt',                                                           'KDF algorithm is scrypt';
    is $keyfile->kdf->dklen,     32,                                                                 'KDF dklen is correct';
    is $keyfile->kdf->n,         262144,                                                             'KDF n parameter is correct';
    is $keyfile->kdf->p,         8,                                                                  'KDF p parameter is correct';
    is $keyfile->kdf->r,         1,                                                                  'KDF r parameter is correct';
    is $keyfile->kdf->salt,      'ab0c7876052600dd703518d6fc3fe8984592145b591fc8fb5c6d43190334ba19', 'KDF salt matches file data';
};

subtest "write_to_file - basic" => sub {
    my $key     = Blockchain::Ethereum::Key->new(private_key => $private_key_bytes);
    my $keyfile = Blockchain::Ethereum::Keystore::File->from_key($key);

    my ($fh, $filename) = tempfile();
    close $fh;

    eval { $keyfile->write_to_file($filename, $password) };
    ok !$@,          'write_to_file succeeds';
    ok -f $filename, 'file was created';

    # Verify we can read it back
    my $loaded = Blockchain::Ethereum::Keystore::File->from_file($filename, $password);
    is $loaded->private_key->export, $private_key_bytes, 'round-trip preserves key';

    unlink $filename;
};

subtest "error conditions - from_file" => sub {
    eval { Blockchain::Ethereum::Keystore::File->from_file("nonexistent.json", $password) };
    like $@, qr/No such file or directory/, 'from_file handles missing file';

    eval { Blockchain::Ethereum::Keystore::File->from_file("./t/Keystore/resources/scrypt_v3.json", "wrongpassword") };
    like $@, qr/Invalid password or corrupted keystore/, 'from_file validates password';
};

subtest "MAC verification" => sub {
    # Load a valid keystore
    my $keyfile      = Blockchain::Ethereum::Keystore::File->from_file("./t/Keystore/resources/scrypt_v3.json", $password);
    my $mac_original = $keyfile->mac;
    my $mac_new      = $keyfile->_generate_mac;
    like $mac_original, qr/^[0-9a-f]+$/i, 'original MAC has hex format';
    like $mac_new,      qr/^[0-9a-f]+$/i, 'new MAC has hex format';
    is $mac_new, $mac_original, 'MAC matches for valid keystore';
};

subtest "keystore format compliance" => sub {
    my $key     = Blockchain::Ethereum::Key->new(private_key => $private_key_bytes);
    my $keyfile = Blockchain::Ethereum::Keystore::File->from_key($key);

    my ($fh, $filename) = tempfile;
    close $fh;

    $keyfile->write_to_file($filename, $password);

    # Read the JSON directly to verify format
    my $json_content = do {
        open my $fh, '<', $filename or die $!;
        local $/;
        <$fh>;
    };

    my $json_data = decode_json($json_content);

    # Verify required fields
    is $json_data->{version}, 3, 'JSON has version 3';
    ok $json_data->{id},                 'JSON has id field';
    ok $json_data->{crypto},             'JSON has crypto field';
    ok $json_data->{crypto}{cipher},     'JSON has cipher field';
    ok $json_data->{crypto}{ciphertext}, 'JSON has ciphertext field';
    ok $json_data->{crypto}{mac},        'JSON has mac field';
    ok $json_data->{crypto}{kdf},        'JSON has kdf field';
    ok $json_data->{crypto}{kdfparams},  'JSON has kdfparams field';

    unlink $filename;
};

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Blockchain::Ethereum::Keystore::Key;

subtest "0x008AeEda4D805471dF9b2A5B0f38A0C3bCBA786b" => sub {
    my $private_key = pack "H*", "7a28b5ba57c53603b0b07b56bba752f7784bf506fa95edc395f5cf6c7514fe9d";
    my $key         = Blockchain::Ethereum::Keystore::Key->new(private_key => $private_key);

    is $key->address->prefixed, '0x008AeEda4D805471dF9b2A5B0f38A0C3bCBA786b';
};

subtest "0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F" => sub {
    my $private_key = pack "H*", "4646464646464646464646464646464646464646464646464646464646464646";
    my $key         = Blockchain::Ethereum::Keystore::Key->new(private_key => $private_key);

    is $key->address->prefixed, '0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F';
};

done_testing();

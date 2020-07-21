[![Release](https://img.shields.io/github/release/giterlizzi/perl-Crypt-PBE.svg)](https://github.com/giterlizzi/perl-Crypt-PBE/releases) [![Build Status](https://travis-ci.com/giterlizzi/perl-Crypt-PBE.svg)](https://travis-ci.com/giterlizzi/perl-Crypt-PBE) [![License](https://img.shields.io/github/license/giterlizzi/perl-Crypt-PBE.svg)](https://github.com/giterlizzi/perl-Crypt-PBE) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Crypt-PBE.svg)](https://github.com/giterlizzi/perl-Crypt-PBE) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Crypt-PBE.svg)](https://github.com/giterlizzi/perl-Crypt-PBE) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Crypt-PBE.svg)](https://github.com/giterlizzi/perl-Crypt-PBE/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Crypt-PBE/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Crypt-PBE)

# Crypt::PBE - Perl extension for PKCS #5 Password-Based Encryption

## Synopsis

```.pl
use Crypt::PBE qw(:jce);

my $pbe = PBEWithMD5AndDES('mypassword');

my $encrypted = $pbe->encrypt('secret'); # Base64 encrypted data

print $pbe->decrypt($encrypted);
```

## Install

To install `Crypt::PBE` distribution, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Copyright

 - Copyright 2020 © Giuseppe Di Terlizzi

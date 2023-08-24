# perl-ethereum-keystore

Ethereum keystore management utilities

# Table of contents

- [Usage](#usage)
- [Installation](#installation)
- [Support and Documentation](#support-and-documentation)
- [License and Copyright](#license-and-copyright)

# Usage

Generating a new address and writing it to a keyfile:

```perl
    my $key = Blockchain::Ethereum::Keystore::Key->new;
    # checksummed address
    print $key->address;
    my $keyfile = Blockchain::ethereum::Keystore::Keyfile->new;

    $keyfile->import_key($key);
    $keyfile->write_to_file("...");
```

Generating a new seed and derivating new keys (BIP44):

```perl
    my $seed = Blockchain::Ethereum::Keystore::Seed->new;
    my $key = $seed->derive_key(0);
    print $key->address;
```

Importing a keyfile and changing the password:

```perl
    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;
    my $password = "old_password";
    $keyfile->import_file("...", $password);
    $keyfile->change_password($password, "newpassword");
    $keyfile->write_to_file("...");
```

Signing a transaction:

```perl
    my $transaction = Blockchain::Ethereum::Transaction::EIP1559->new(
        ...
    );

    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;
    $keyfile->import_file("...");
    $keyfile->private_key->sign_transaction($transaction);
```

Exporting a keyfile private key:

```perl
    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;
    $keyfile->import_file("...");

    # private key bytes
    print $keyfile->private_key->export;
```

# Installation

## cpanminus

```
cpanm Blockchain::Ethereum::Keystore
```

## make

```
perl Makefile.PL
make
make test
make install
```

# Support and Documentation

After installing, you can find documentation for this module with the
perldoc command.

```
perldoc Blockchain::Ethereum::Keystore
```

You can also look for information at:

- [Search CPAN](https://metacpan.org/release/Blockchain-Ethereum-Keystore)

# License and Copyright

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  [The MIT License](./LICENSE)

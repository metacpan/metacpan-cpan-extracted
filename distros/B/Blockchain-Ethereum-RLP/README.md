# perl-RLP

Recursive Length Prefix (RLP) utility for encoding and decoding ethereum based transaction parameters

# Table of contents

- [Usage](#usage)
- [Installation](#installation)
- [Support and Documentation](#support-and-documentation)
- [License and Copyright](#license-and-copyright)

# Usage

```perl
my $rlp = Blockchain::Ethereum::RLP->new();

my $tx_params  = ['0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535', '0xde0b6b3a7640000', '0x', '0x1', '0x', '0x'];
my $encoded = $rlp->encode($params); #ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080

my $encoded_tx_params = 'ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080';
my $decoded = $rlp->decode(pack "H*", $encoded_tx_params); #['0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535', '0xde0b6b3a7640000', '0x', '0x1', '0x', '0x']
```

## Standalone version

```bash
$ rlp --action=encode 0x9 0x4a817c800 0x5208 0x3535353535353535353535353535353535353535 0xde0b6b3a7640000 0x 0x1 0x 0x
# ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080

$ rlp --action=decode ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080
# 0x9, 0x4a817c800, 0x5208, 0x3535353535353535353535353535353535353535, 0xde0b6b3a7640000, 0x, 0x1, 0x, 0x
```

# Installation

## cpanminus

```
cpanm Blockchain::Ethereum::RLP
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
perldoc Blockchain::Ethereum::RLP
```

You can also look for information at:

- [Search CPAN](https://metacpan.org/release/Blockchain-Ethereum-RLP)

# License and Copyright

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  [The MIT License](./LICENSE)

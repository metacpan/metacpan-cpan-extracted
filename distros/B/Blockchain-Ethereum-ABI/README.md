# perl ABI

Application Binary Interface (ABI) utility for encoding and decoding solidity smart contract arguments

# Table of contents

- [Supported types](#supports)
- [Usage](#usage)
- [Installation](#installation)
- [Support and Documentation](#support-and-documentation)
- [License and Copyright](#license-and-copyright)

# Supports

- address
- bool
- bytes(\d+)?
- (u)?int(\d+)?
- string
- tuple

Also arrays `((\[(\d+)?\])+)?` for the above mentioned types.

# Usage

```perl
my $encoder = Blockchain::Ethereum::ABI::Encoder->new();
$encoder->function('test')
    # string
    ->append(string => 'Hello, World!')
    # bytes
    ->append(bytes => unpack("H*", 'Hello, World!'))
    # tuple
    ->append('(uint256,address)' => [75000000000000, '0x0000000000000000000000000000000000000000'])
    # arrays
    ->append('bool[]', [1, 0, 1, 0])
    # multidimensional arrays
    ->append('uint256[][][2]', [[[1]], [[2]]])
    # tuples arrays and tuples inside tuples
    ->append('((int256)[2])' => [[[1], [2]]])->encode;

my $decoder = Blockchain::Ethereum::ABI::Decoder->new();
$decoder
    ->append('uint256')
    ->append('bytes[]')
    ->decode('0x...');
```

# Installation

## cpanminus

```
cpanm Blockchain::Ethereum::ABI
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
perldoc Blockchain::Ethereum::ABI
```

You can also look for information at:

- [Search CPAN](https://metacpan.org/release/Blockchain-Ethereum-ABI)

# License and Copyright

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  [The MIT License](./LICENSE)


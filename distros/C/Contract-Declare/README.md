# Contract::Declare

[![CI](https://github.com/shootnix/perl-Contract-Declare/actions/workflows/ci.yml/badge.svg)](https://github.com/shootnix/perl-Contract-Declare/actions)
[![CPAN Version](https://badge.fury.io/pl/perl-Contract-Declare.svg)](https://metacpan.org/pod/Contract::Declare)
[![License](https://img.shields.io/badge/license-Perl%20Artistic-blue.svg)](https://dev.perl.org/licenses/artistic.html)
[![Issues](https://img.shields.io/github/issues/shootnix/perl-Contract-Declare.svg)](https://github.com/shootnix/perl-Contract-Declare/issues)
[![Stars](https://img.shields.io/github/stars/shootnix/perl-Contract-Declare.svg)](https://github.com/shootnix/perl-Contract-Declare/stargazers)

---

**Contract::Declare** is a simple and lightweight system for defining typed contracts (interfaces) in Perl.

It provides a small DSL to specify method arguments and return types, with optional runtime validation.

---

## Features

- Define strict typed interfaces (contracts) for your classes
- Optional runtime checking of method arguments and return values
- Minimalistic DSL: `contract`, `interface`, `method`, `returns`
- Integrates with `Role::Tiny` for easy role-based design
- No heavy dependencies, very fast

---

## Installation

Install via CPAN:

```bash
cpanm Contract::Declare
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

---

## Quick Start

```perl
package MyInterface;

use Contract::Declare;
use Standard::Types qw(Int Str);

contract 'MyInterface' => interface {
    method add_number => (Int), returns(Int);
    method get_name   => returns(Str);
};

package MyImpl;

sub new { bless {}, shift }
sub add_number { my ($self, $x) = @_; return $x + 1 }
sub get_name   { return "example" }

# Using the contract
my $impl = MyImpl->new;
my $obj  = MyInterface->new($impl);

say $obj->add_number(41);  # prints 42
say $obj->get_name;        # prints "example"
```

---

## Environment Variables

| Variable | Description |
|:---------|:-------------|
| `CONTRACT_DECLARE_CHECK_TYPES` | Enables runtime validation of method arguments and return values if set to true |
| `CONTRACT_DECLARE_KEEP_CONTRACT` | Keeps contract definitions in memory after building if set |

Example:

```bash
export CONTRACT_DECLARE_CHECK_TYPES=1
```

---

## Contributing

Bug reports and pull requests are welcome!

Please submit issues and feature requests via [GitHub Issues](https://github.com/yourname/Contract-Declare/issues).

---

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See the [Artistic License 1.0](https://dev.perl.org/licenses/artistic.html) for details.

---

## Author

**Alexander Ponomarev** (<shootnix@gmail.com>)

Project: [GitHub Repository](https://github.com/yourname/Contract-Declare)

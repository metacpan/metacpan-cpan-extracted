[![Actions Status](https://github.com/Songmu/Acme-Songmu/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/Songmu/Acme-Songmu/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/Acme-Songmu.svg)](https://metacpan.org/release/Acme-Songmu)
# NAME

Acme::Songmu - Songmu's sample module

# SYNOPSIS

    use Acme::Songmu;
    my $songmu = Acme::Songmu->instance;
    say $songmu->name; # => 'Masayuki Matsuki'
    say $songmu->age;  # => 37
    $songmu->gmu;      # => 'ぐむー'

# DESCRIPTION

Acme::Songmu is Songmu's sample CPAN module for sandboxing.

# CONSTRUCTOR

## `my $sonmgu = Acme::Songmu->instance`

The `instance` class method returns an instance of Songmu as a singleton.

# METHODS

- `$songmu->name`
- `$songmu->gmu`

# METHODS

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>

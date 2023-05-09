[![Actions Status](https://github.com/kfly8/Acme-Onion/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Acme-Onion/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Acme-Onion.svg)](https://metacpan.org/release/Acme-Onion)
# NAME

Acme::Onion - .🧅 file extension in Perl.

# SYNOPSIS

```perl
❯ tree examples/lib
examples/lib
└── Hello.🧅

❯ cat examples/lib/Hello.🧅
package Hello;
sub onion { 'Hello 🧅' }
1;

❯ perl -Iexamples/lib -MAcme::Onion -MHello -E 'say Hello->onion';
Hello 🧅
```

# DESCRIPTION

Acme::Onion is a Perl module designed to enable the use of .🧅 file extension alongside traditional .pm files. It provides a simple, yet unique way to organize and manage your Perl code.

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>

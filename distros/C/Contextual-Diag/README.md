[![Actions Status](https://github.com/kfly8/p5-Contextual-Diag/workflows/test/badge.svg)](https://github.com/kfly8/p5-Contextual-Diag/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Contextual-Diag/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Contextual-Diag?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Contextual-Diag.svg)](https://metacpan.org/release/Contextual-Diag)
# NAME

Contextual::Diag - diagnosing perl context

# SYNOPSIS

```perl
use Contextual::Diag;

if (contextual_diag) { }
# => warn "evaluated as BOOL in SCALAR context"

my $h = { key => contextual_diag 'hello' };
# => warn "wanted LIST context"
```

# DESCRIPTION

Contextual::Diag is a tool for diagnosing perl context.
The purpose of this module is to make it easier to learn perl context.

## contextual\_diag()

```perl
contextual_diag(@_) => @_
```

By plugging in the context where you want to know, indicate what the context:

```perl
# CASE: wanted LIST context
my @t = contextual_diag qw/a b/
my @t = ('a','b', contextual_diag())

# CASE: wanted SCALAR context
my $t = contextual_diag "hello"
scalar contextual_diag qw/a b/
```

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>

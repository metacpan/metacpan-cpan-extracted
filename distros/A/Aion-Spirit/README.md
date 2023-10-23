[![Actions Status](https://github.com/darviarush/perl-aion-spirit/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion-spirit/actions)
# NAME

Aion::Spirit - functions for controlling the program execution process

# VERSION

0.0.1

# SYNOPSIS

```perl
use Aion::Spirit;

package A {
    sub x_1() { 1 }
    sub x_2() { 2 }
    sub y_1($) { 1+shift }
    sub y_2($) { 2+shift }
}

aroundsub "A", qr/_2$/, sub { shift->(@_[1..$#_]) + .03 };

A::x_1     # -> 1

# Perl cached subroutines with prototype "()" in main:: as constant. aroundsub should be applied in a BEGIN block to avoid this:
A::x_2         # -> 2
(\&A::x_2)->() # -> 2.03

# Functions with parameters not cached:
A::y_1 .5  # -> 1.5
A::y_2 .5  # -> 2.53
```

# DESCRIPTION

A Perl program consists of packages, globals, subroutines, lists, and scalars. That is, it is simply data that, unlike a C program, can be “changed on the fly.”

Thus, this module provides convenient functions for transforming all these entities, as well as maintaining their integrity.

# SUBROUTINES

## aroundsub ($pkg, $re, $around)

Wraps the functions in the package in the specified regular sequence.

The package may not be specified for the current:

File N.pm:
```perl
package N;

use Aion::Spirit qw/aroundsub/;

use constant z_2 => 10;

aroundsub qr/_2$/, sub { shift->(@_[1..$#_]) + .03 };

sub x_1() { 1 }
sub x_2() { 2 }
sub y_1($) { 1+shift }
sub y_2($) { 2+shift }

1;
```

```perl
use lib ".";
use N;

N::x_1          # -> 1
N::x_2          # -> 2.03
N::y_1 0.5      # -> 1.5
N::y_2 0.5      # -> 2.53
```

## wrapsub ($sub, $around)

Wraps a function in the specified.

```perl
sub sum(@) { my $x = 0; $x += $_ for @_; $x }

BEGIN {
    *avg = wrapsub \&sum, sub { my $x = shift; $x->(@_) / @_ };
}

avg 1,2,5  # -> (1+2+5) / 3

Sub::Util::subname \&avg   # => main::sum__AROUND
```

## ASSERT ($ok, $message)

This is assert. This is checker scalar by nullable.

```perl
my $ok = 0;
ASSERT $ok == 0, "Ok";

eval { ASSERT $ok, "Ok not equal 0!" }; $@  # ~> Ok not equal 0!

my $ten = 11;

eval { ASSERT $ten == 10, sub { "Ten maybe 10, but ten = $ten!" } }; $@  # ~> Ten maybe 10, but ten = 11!
```

## firstidx (&sub, @list)

Searches the list for the first match and returns the index of the found element.

```perl
firstidx { /3/ } 1,2,3  # -> 2
firstidx { /4/ } 1,2,3  # -> undef
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)

# LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

⚖ **GPLv3**

# COPYRIGHT

The Aion::Spirit module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

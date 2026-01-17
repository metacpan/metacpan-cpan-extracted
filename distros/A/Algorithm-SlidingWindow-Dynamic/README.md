# Algorithm::SlidingWindow::Dynamic

[![CI](https://github.com/haxmeister/perl-algorithm-slidingwindow-dynamic/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-algorithm-slidingwindow-dynamic/actions/workflows/ci.yml)
[![MetaCPAN](https://badge.fury.io/pl/Algorithm-SlidingWindow-Dynamic.svg)](https://metacpan.org/pod/Algorithm::SlidingWindow::Dynamic)

Generic, dynamically sized sliding window.

This module implements a count-based sliding window (deque) over arbitrary Perl scalars.
It supports growing and shrinking from either end and a `slide()` operation for fixed-length
rolling windows.

## Install

### From CPAN (recommended)

```bash
cpanm Algorithm::SlidingWindow::Dynamic
```

### From source (this repo)

```bash
perl Makefile.PL
make
make test
make install
```

## Synopsis

```perl
use Algorithm::SlidingWindow::Dynamic;

my $w = Algorithm::SlidingWindow::Dynamic->new;

$w->push(1, 2, 3);        # window: 1 2 3
my $a = $w->shift;        # removes 1, window: 2 3
my $b = $w->pop;          # removes 3, window: 2

$w->push(qw(a b c));      # window: 2 a b c
my $ev = $w->slide('d');  # evicts 2, window: a b c d

my @vals = $w->values;    # (a, b, c, d)
```

## Documentation

Full documentation is in the module POD:

- `lib/Algorithm/SlidingWindow/Dynamic.pm`
- MetaCPAN: https://metacpan.org/pod/Algorithm::SlidingWindow::Dynamic

## Source Code

- GitHub: https://github.com/haxmeister/perl-algorithm-slidingwindow-dynamic
- Issues: https://github.com/haxmeister/perl-algorithm-slidingwindow-dynamic/issues

## License

Same terms as Perl itself. See `LICENSE`.

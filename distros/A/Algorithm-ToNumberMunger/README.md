# Algorithm::ToNumberMunger

Compile declarative specs into closures that munge raw values into numbers.

Many numeric pipelines — anomaly detectors, feature stores, CSV loaders — want
every column to be a number, but the values they are handed are not always
numbers to begin with: an HTTP method is a string, a timestamp is a formatted
date, a high-cardinality label wants bucketing. An **input munger** turns such a
raw value into a single number.

`Algorithm::ToNumberMunger` does not read or write files. It **compiles** a
plain-data spec into a closure that maps one raw value to one number, so a
caller can build its mungers once from configuration and then apply them per row
with no re-parsing. All configuration errors are caught at build time; the
returned closure only croaks on genuinely un-mungeable *input*.

```perl
use Algorithm::ToNumberMunger;

# one munger from a spec hash
my $code = Algorithm::ToNumberMunger->build(
    { munger => 'enum', map => { GET => 0, POST => 1, PUT => 2 } },
);
my $n = $code->('POST');          # 1

# a whole table at once, then a full row in column order
my $plan = Algorithm::ToNumberMunger->compile(
    tags    => [ 'method', 'bytes', 'label' ],
    mungers => {
        method => { munger => 'enum', map => { GET => 0, POST => 1 } },
        bytes  => { munger => 'log',  offset => 1 },
        label  => { munger => 'hash', buckets => 1024 },
    },
);
my $row = $plan->apply_named( { method => 'POST', bytes => 512, label => 'x' } );
```

## Installation

All required modules are core Perl. A C compiler is optional; when one is
present, the XS fast path for the `hash` and `entropy` mungers is built,
otherwise the pure-Perl fallback is used.

### FreeBSD

```sh
pkg install perl5 p5-App-cpanminus p5-Time-Piece
cpanm Algorithm::ToNumberMunger
```

### Debian

```sh
apt-get install perl make gcc cpanminus
cpanm Algorithm::ToNumberMunger
```

### From source

```sh
perl Makefile.PL
make
make test
make install
```

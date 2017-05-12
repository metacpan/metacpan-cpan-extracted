Bloomd-Client  
=============

This is a Perl client for the [bloomd server](https://github.com/armon/bloomd). 

Travis status: ![Build Status](https://api.travis-ci.org/dams/Bloomd-Client.png?branch=master)

Installation
------------

Basic installation

This distribution is on CPAN, so you might want to use your preferred CPAN
client to install it:

```
# using cpanminus
cpanm Bloomd::Client

# using regular cpan
cpan Bloom::Client
```

If you'd like to install it from the source, see the last section of this file

Usage
-----

All the commands from bloomd
[protocol](https://github.com/armon/bloomd#protocol) are wrapped in a method
with the same name. Return values are converted to Perl types (e.g. `1`/`<empty
string>` instead of `Yes`/`No`)

```perl
use feature ':5.12';
use Bloomd::Client;
my $b = Bloomd::Client->new;
my $filter = 'test_filter';
$b->create($filter);
my $array_ref = $b->list();
my $hash_ref = $b->info($filter);
$b->set($filter, 'u1');
if ($b->check($filter, 'u1')) { say "it exists!" }
my $hashref = $b->multi( $filter, qw(u1 u2 u3) );
```

Timeout support
---------------

You can set the timeout option to the constructor. The timeout will be on
reading and on writing to the socket. It can be a float, up to microseconds.

More doc
--------

Check out [the documentation on metacpan](https://metacpan.org/module/Bloomd::Client).

Build from the source
---------------------

The `master` branch uses [DistZilla](http://dzil.org/). If you'd like to simply
build this distribution from source, use the `build/master` branch, and issue:

```shell
perl Build.PL
./Build test
./Build install
```

If you want to run the tests against a running bloomd server, you'll need to set BLOOMD_HOST and BLOOMD_PORT:

```
BLOOMD_HOST=127.0.0.1 BLOOMD_PORT=8673 ./Build test
```

Contribute
----------

It's OK to submit Pull Requests against the `build/master` branch, but it's
easier for me to merge the patch if you use the `master` branch. For that you
need to install `Dist::Zilla` ( with `cpan Dist::Zilla` or using `cpanm`).
Then:

```shell
dzil authordeps --missing | cpan
dzil listdeps --missing | cpan
dzil build
```

If you want to run the tests against a running bloomd server, you'll need to set BLOOMD_HOST and BLOOMD_PORT:

```
BLOOMD_HOST=127.0.0.1 BLOOMD_PORT=8673 dzil test
```

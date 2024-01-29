Color::Spectrum
===============
Just another HTML color generator. [![CPAN Version](https://badge.fury.io/pl/Color-Spectrum.svg)](https://metacpan.org/pod/Color::Spectrum)

Synopsis
--------
```perl
# Procedural interface:
use Color::Spectrum qw(generate);
my @color = generate(10,'#000000','#FFFFFF');

# OO interface:
use Color::Spectrum;
my $spectrum = Color::Spectrum->new();
my @color = $spectrum->generate(10,'#000000','#FFFFFF');
```

Installation
------------
To install this module, you should use CPAN. A good starting
place is [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

If you truly want to install from this github repo, then
be sure and create the manifest before you test and install:
```
perl Makefile.PL
make
make manifest
make test
make install
```

Support and Documentation
-------------------------
After installing, you can find documentation for this module with the
perldoc command.
```
perldoc Color::Spectrum
```

You can also find documentation at [metaCPAN](https://metacpan.org/pod/Color::Spectrum).

License and Copyright
---------------------
See [source POD](/lib/Color/Spectrum.pm).

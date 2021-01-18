# Astro::Montenbruck


Library of astronomical calculations, based on _"Astronomy On The Personal Computer"_ by _O.Montenbruck_ and _T.Phleger_, _Fourth Edition, Springer-Verlag, 2000_.

The main purpose of the library is to calculate positions of the Sun, the Moon, and the planets with precision that is approximately the same as that found in astronomical yearbooks. Other modules contain time-related routines, coordinates conversions, calculation of the ecliptic obliquity and nutation, etc. Over time, the range of utility functions will grow.

Partially it overlaps some code which already exists in CPAN and elsewhere. For instance, there is a [Perl wrapper for Swiss Ephemeris](http://www.astrotexte.ch/sources/SwissEph.html). Swiss Ephemeris is fast and precise C library. Unfortunately, it lacks portability and convenient license. So, it is not easy for a layman to customize it for her custom application, be it an online lunar calendar, or tool for amateur sky observations.

The present library is an attempt to find a middle-ground between precision on the one hand and compact, well organized code on the other. I tried to follow the best practices of modern Perl programming.

## Precision

As the book authors state in Introduction to the 4-th edition, _"The errors in the fundamental routines for determining the coordinates of the Sun, the Moon, and the planets amount to about 1″-3″._

## Contents

- [Astro::Montenbruck::MathUtils](lib/Astro/Montenbruck/MathUtils.pm) — Core mathematical routines.
- [Astro::Montenbruck::Time](lib/Astro/Montenbruck/Time.pm) — Time-related routines.
- [Astro::Montenbruck::Ephemeris](lib/Astro/Montenbruck/Ephemeris.pm) — Positions of celestial bodies.
- [Astro::Montenbruck::CoCo](lib/Astro/Montenbruck/CoCo.pm) — Coordinates conversions.
- [Astro::Montenbruck::NutEqu](lib/Astro/Montenbruck/NutEqu.pm) — Nutation and obliquity of ecliptic.
- [Astro::Montenbruck::RiseSet](lib/Astro/Montenbruck/RiseSet.pm) — Rise, set, transit and twilight time.
- [Astro::Montenbruck::Lunation](lib/Astro/Montenbruck/Lunation.pm) — Lunar phases
- [Astro::Montenbruck::SolEqu](lib/Astro/Montenbruck/SolEqu.pm) — Solstices and equinoxes


## Requirements

* __Perl__ >= 5.22

Tested on Linux 64-bit, macOS 10.14 and Windows 10 64-bit. There should be no problems at other platforms, as the code is pure Perl.

Perl dependencies are minimal, most of the external modules are part of the standard distribution.
[DateTime](https://metacpan.org/pod/DateTime) is not really required. It is used only in example scripts and tests, not the library itself.

## Installation

To install this module, run the following commands:

```
$ perl Build.PL
$ ./Build
$ ./Build installdeps
$ ./Build test
$ ./Build install
```

## Documentation

After installing, you can find documentation for this module with the perldoc command from the parent directory of the library:

```
$ perldoc Astro::Montenbruck
$ perldoc Astro::Montenbruck::Ephemeris
```

You may also generate local HTML documentation:

```
$ perl script/createdocs.pl
```

Documentation files will be installed to **docs/** directory.

## Scripts

[script/](script/) directory contains examples of the library usage. They will be extended over time.

* **planpos.pl** — positions of Sun, Moon and the planets
* **riseset.pl** — rises and sets of celestial objects 
* **phases.pl** — lunar phases
* **rst_almanac.pl** — rises/sets/transits events for a range of dates 
* **solequ.pl** — solstices and equinoxes

### Example

To display current planetary positions, type:

```
$ perl script/planpos.pl
```

For list of available options. type:

```
$ perl script/planpos.pl --help
```


## License And Copyright

Copyright (C) 2010-2021 Sergey Krushinsky

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (1.0). You may obtain a copy of the full license at:

https://dev.perl.org/licenses/artistic.html

Aggregation of this Package with a commercial distribution is always permitted provided that the use of this Package is embedded; that is, when no overt attempt is made to make this Package's interfaces visible to the end user of the commercial distribution. Such use shall not be construed as a distribution of this Package.

The name of the Copyright Holder may not be used to endorse or promote products derived from this software without specific prior written permission.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

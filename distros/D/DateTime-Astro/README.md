[![Build Status](https://travis-ci.org/lestrrat-p5/DateTime-Astro.svg?branch=master)](https://travis-ci.org/lestrrat-p5/DateTime-Astro)
# NAME

DateTime::Astro - Functions For Astromical Calendars

# DESCRIPTION

DateTime::Astro implements functions used in astronomical calendars, such
as calculation of lunar longitudea and solar longitude.

This module is best used in environments where a C compiler and the MPFR arbitrary precision math library is installed. It can fallback to using Math::BigInt, but that would pretty much render it useless because of its speed and loss of accuracy that may creep up while doing Perl to C struct conversions.

# DISCLAIMER

This module works, but there are several caveats you should be aware of:

## MPFR Is Required / PurePerl Version Not Functional

There /is/ a HALF BAKED Pure Perl implmentation bundled with this distribution, but at this point please consider it UNUSABLE. This sort of calculation requires the speed and efficiency of a C library anyway.

As such, you HAVE to have MPFR installed correctly in your system. Please consult your local package manager, or http://mpfr.org

Patches to make the pure perl version work better is always welcome.

## 17 solar terms are still off by ~ 5 minutes

I've tried very hard to correctly calculate the solar term dates with this
module, but I still get 17 instances in about 130 years worth of solar terms,
where the dates are off by an average of about 5 minutes -- and these usually 
fall at right about midnight, causing day-based comparisons to be off by 1.

I'm sure there's something that's causing a round off somwhere. If you're up
to it, please see xt/101\_solar\_terms.t and see if you can fix it for me!

# FUNCTIONS

## BACKEND()

Returns 'XS' or 'PP', noting the current backend.

## dt\_from\_moment($moment)

Given a moment (days since rd + fractional seconds), returns a DateTime object in UTC

## dynamical\_moment($moment)

Computes the moment value from given moemnt, taking into account the ephemeris correction.

## dynamical\_moment\_from\_dt($dt)

Computes the moment value from a DateTime object, taking into account the ephemeris correction.

## ephemeris\_correction($moment)

Computes the ephemeris correction on a given moment

## gregorian\_components\_from\_rd($rd\_days)

Computes year, month, date from RD value

## gregorian\_year\_from\_rd($rd\_days)

Computes year from RD value

## julian\_centuries($dt)

Computes the julian centuries for given DateTime object

## julian\_centuries\_from\_moment($moment)

Computes the julian centuries for given moment

## lunar\_phase($dt)

Computes the lunar phase for given DateTime object

## lunar\_phase\_from\_moment($moment)

Computes the lunar phase for given moment

## polynomial($x, ...)

Computes the polynomical expression using $x as the variable. The left most argument is the constant, and each successive argument is the coefficient for the next power of $x

## ymd\_seconds\_from\_moment($moment)

Computes the gregorian components (year, month, day) from the RD date, and the number of seconds from the fractional part.

## lunar\_longitude($dt)

Returns the Moon's longitude on the given date $dt

## lunar\_longitude\_from\_moment($moment)

Returns the Moon's longitude on the given moment $moment

## moment($dt)

Returns the date $dt expressed in moment

## nth\_new\_moon($n)

Returns the $n-th new moon, in $moment.

Currently the new moons dates are accurate to about within +/- 60 seconds of the actual new moon for modern dates. 

For older dates, the accuraccy degrades a bit to about +/- 5 minutes.

## new\_moon\_after($dt)

## new\_moon\_before($dt)

## solar\_longitude($dt)

Returns the Sun's longitude on the given date $dt

## solar\_longitude\_from\_moment($moment)

Returns the Sun's longitude on the given moment $moment

## new\_moon\_after\_from\_moment

## new\_moon\_before\_from\_moment

## solar\_longitude\_after

## solar\_longitude\_after\_from\_moment

## solar\_longitude\_before

## solar\_longitude\_before\_from\_moment

# CONSTANTS

## MEAN\_SYNODIC\_MONTH

Mean time (in moment) between new moons

## MEAN\_TROPICAL\_YEAR

Mean time (in moment) between a full year (time for the Earth to go around the sun)

# LICENSE

This library is available under Artistic License v2, and is:

    Copyright (C) 2012  Daisuke Maki C<< <daisuke@endeworks.jp> >>

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

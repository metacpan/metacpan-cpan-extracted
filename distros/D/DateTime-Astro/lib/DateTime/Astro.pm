package DateTime::Astro;
use strict;
use XSLoader;
use Exporter 'import';
use DateTime;

BEGIN {
    our @EXPORT_OK = qw(
        MEAN_TROPICAL_YEAR
        MEAN_SYNODIC_MONTH
        dt_from_moment
        ephemeris_correction
        gregorian_year_from_rd
        gregorian_components_from_rd
        julian_centuries
        julian_centuries_from_moment
        lunar_longitude
        lunar_longitude_from_moment
        lunar_phase
        lunar_phase_from_moment
        moment
        new_moon_after
        new_moon_after_from_moment
        new_moon_before
        new_moon_before_from_moment
        nth_new_moon
        polynomial
        solar_longitude
        solar_longitude_from_moment
        solar_longitude_before
        solar_longitude_before_from_moment
        solar_longitude_after
        solar_longitude_after_from_moment
    );
    our $VERSION = '1.00';

    my $backend = 'XS';

    # XXX forcibly set explicit_xs so that PP won't be loaded unless
    # explicitly called
    my $explicit_xs = 1;
    if (exists $ENV{PERL_DATETIME_ASTRO_BACKEND} && 
        $ENV{PERL_DATETIME_ASTRO_BACKEND} eq 'XS') {
        $explicit_xs = 1;
    } elsif ($ENV{PERL_DATETIME_ASTRO_BACKEND}) {
        $backend = $ENV{PERL_DATETIME_ASTRO_BACKEND};
    }
        
    my $loaded;
    my @errors;
    if ($backend ne 'PP') {
        eval {
            XSLoader::load __PACKAGE__, $VERSION;
            require DateTime::AstroXS;
            $loaded = 'XS';
        };
        if (my $e = $@) {
            push @errors, "Failed to load XS backend: $e";
        }
    }

    if (! $loaded && ! $explicit_xs) {
        eval {
            require DateTime::AstroPP;
            $loaded = 'PP';
        };
        if (my $e = $@) {
            push @errors, "Failed to load PP backend: $e";
        }
    }

    if (! $loaded ) {
        die("DateTime::Astro: Failed to load backend implementations. Can't proceed\n" . join("\n", @errors));
    }

    eval "sub BACKEND() { '$loaded' }";
}

sub moment {
    my $dt = shift;
    Carp::croak("moment called with invalid value: " . (defined $dt ? $dt : "(undef)")) unless ref $dt eq 'DateTime';
    my ($rd, $seconds) = $dt->utc_rd_values;
    return $rd + ($seconds / 86400);
}

1;

__END__

=head1 NAME

DateTime::Astro - Functions For Astromical Calendars

=head1 DESCRIPTION

DateTime::Astro implements functions used in astronomical calendars, such
as calculation of lunar longitudea and solar longitude.

This module is best used in environments where a C compiler and the MPFR arbitrary precision math library is installed. It can fallback to using Math::BigInt, but that would pretty much render it useless because of its speed and loss of accuracy that may creep up while doing Perl to C struct conversions.

=head1 DISCLAIMER

This module works, but there are several caveats you should be aware of:

=head2 MPFR Is Required / PurePerl Version Not Functional

There /is/ a HALF BAKED Pure Perl implmentation bundled with this distribution, but at this point please consider it UNUSABLE. This sort of calculation requires the speed and efficiency of a C library anyway.

As such, you HAVE to have MPFR installed correctly in your system. Please consult your local package manager, or http://mpfr.org

Patches to make the pure perl version work better is always welcome.

=head2 17 solar terms are still off by ~ 5 minutes

I've tried very hard to correctly calculate the solar term dates with this
module, but I still get 17 instances in about 130 years worth of solar terms,
where the dates are off by an average of about 5 minutes -- and these usually 
fall at right about midnight, causing day-based comparisons to be off by 1.

I'm sure there's something that's causing a round off somwhere. If you're up
to it, please see xt/101_solar_terms.t and see if you can fix it for me!

=head1 FUNCTIONS

=head2 BACKEND()

Returns 'XS' or 'PP', noting the current backend.

=head2 dt_from_moment($moment)

Given a moment (days since rd + fractional seconds), returns a DateTime object in UTC

=head2 dynamical_moment($moment)

Computes the moment value from given moemnt, taking into account the ephemeris correction.

=head2 dynamical_moment_from_dt($dt)

Computes the moment value from a DateTime object, taking into account the ephemeris correction.

=head2 ephemeris_correction($moment)

Computes the ephemeris correction on a given moment

=head2 gregorian_components_from_rd($rd_days)

Computes year, month, date from RD value

=head2 gregorian_year_from_rd($rd_days)

Computes year from RD value

=head2 julian_centuries($dt)

Computes the julian centuries for given DateTime object

=head2 julian_centuries_from_moment($moment)

Computes the julian centuries for given moment

=head2 lunar_phase($dt)

Computes the lunar phase for given DateTime object

=head2 lunar_phase_from_moment($moment)

Computes the lunar phase for given moment

=head2 polynomial($x, ...)

Computes the polynomical expression using $x as the variable. The left most argument is the constant, and each successive argument is the coefficient for the next power of $x

=head2 ymd_seconds_from_moment($moment)

Computes the gregorian components (year, month, day) from the RD date, and the number of seconds from the fractional part.

=head2 lunar_longitude($dt)

Returns the Moon's longitude on the given date $dt

=head2 lunar_longitude_from_moment($moment)

Returns the Moon's longitude on the given moment $moment

=head2 moment($dt)

Returns the date $dt expressed in moment

=head2 nth_new_moon($n)

Returns the $n-th new moon, in $moment.

Currently the new moons dates are accurate to about within +/- 60 seconds of the actual new moon for modern dates. 

For older dates, the accuraccy degrades a bit to about +/- 5 minutes.

=head2 new_moon_after($dt)

=head2 new_moon_before($dt)

=head2 solar_longitude($dt)

Returns the Sun's longitude on the given date $dt

=head2 solar_longitude_from_moment($moment)

Returns the Sun's longitude on the given moment $moment

=head2 new_moon_after_from_moment

=head2 new_moon_before_from_moment

=head2 solar_longitude_after

=head2 solar_longitude_after_from_moment

=head2 solar_longitude_before

=head2 solar_longitude_before_from_moment

=head1 CONSTANTS

=head2 MEAN_SYNODIC_MONTH

Mean time (in moment) between new moons

=head2 MEAN_TROPICAL_YEAR

Mean time (in moment) between a full year (time for the Earth to go around the sun)

=head1 LICENSE

This library is available under Artistic License v2, and is:

    Copyright (C) 2012  Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=cut
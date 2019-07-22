package Astro::App::Satpass2::ParseTime::Date::Manip::v6;

use strict;
use warnings;

use Astro::Coord::ECI::Utils 0.077 qw{ looks_like_number time_gm };

use parent qw{ Astro::App::Satpass2::ParseTime::Date::Manip };

use Astro::App::Satpass2::Utils qw{ load_package @CARP_NOT };

our $VERSION = '0.040';

my $invalid;


BEGIN {
    eval {
	load_package( 'Date::Manip' )
	    or return;
	load_package( 'Date::Manip::Date' )
	    or return;
	my $ver = Date::Manip->VERSION();
	$ver =~ s/ _ //smxg;
	$ver >= 6
	    and do {
		Date::Manip->import();
		1;
	    }
	    or $invalid = sprintf
		'%s assumes a Date::Manip version >= 6. You have %s',
		__PACKAGE__, Date::Manip->VERSION();
	$ver >= 6.49
	    and *_normalize_zone = sub {
		$_[0] =~ s/ \A (?: gmt | ut ) \z /UT/smxi;
	    };
	1;
    } or $invalid = ( $@ || 'Unable to load Date::Manip' );
    __PACKAGE__->can( '_normalize_zone' )
	or *_normalize_zone = sub{};
}

my $epoch_offset = time_gm( 0, 0, 0, 1, 0, 70 );

sub delegate {
    return __PACKAGE__;
}

sub dmd_err {
    my ( $self ) = @_;
    return $self->_get_dm_field( 'object' )->err();
}

sub dmd_zone {
    my ( $self ) = @_;
    return scalar $self->_get_dm_field( 'object' )->tz->zone();
}

sub parse_time_absolute {
    my ( $self, $string ) = @_;
    $invalid and $self->wail( $invalid );
    my $dm = $self->_get_dm_field( 'object' );
    $dm->parse( $string ) and return;
    return $dm->secs_since_1970_GMT() - $epoch_offset;
}

sub use_perltime {
    return 0;
}

sub tz {
    my ( $self, @args ) = @_;
    $invalid and $self->wail( $invalid );
    if ( @args ) {
	my $zone = $args[0];
	my $dm = $self->_get_dm_field( 'object' );
	defined $zone and '' ne $zone
	    or $zone = $self->_get_dm_field( 'default_zone' );
	_normalize_zone( $zone ); 
	$dm->config( setdate => "zone,$zone" );
    }
    return $self->SUPER::tz( @args );
}

sub _get_dm_field {
    my ( $self, $field ) = @_;
    my $info = $self->{+__PACKAGE__} ||= _make_dm_hash();
    return $info->{$field};
}

sub _make_dm_hash {

    # Workaround for bug (well, _I_ think it's a bug) introduced into
    # Date::Manip with 6.34, while fixing RT #78566. My bug report is RT
    # #80435.
    my $path = $ENV{PATH};
    local $ENV{PATH} = $path;

    my $dm = Date::Manip::Date->new();
    return {
	default_zone	=> scalar $dm->tz->zone(),
	object		=> $dm,
    };
}

1;

=head1 NAME

Astro::App::Satpass2::ParseTime::Date::Manip::v6 - Astro::App::Satpass2 wrapper for Date::Manip v6 or greater

=head1 SYNOPSIS

No user-serviceable parts inside.

=head1 DETAILS

This class wraps the L<Date::Manip::Date|Date::Manip::Date> object from
L<Date::Manip|Date::Manip> version 6.0 or higher, and uses it to parse
dates. It ignores the C<perltime> mechanism.

B<Caveat:> the L<Date::Manip|Date::Manip> configuration mechanism (used
to set the time zone) reports errors using the C<warn> built-in, rather
than by returning a bad status or throwing an exception. Yes, I could
use the C<$SIG{__WARN__}> hook to trap this, but I would rather hope
that Mr.  Beck will provide a more friendly mechanism.

=head1 METHODS

This class supports the following public methods over and above those
documented in its superclass
L<Astro::App::Satpass2::ParseTime|Astro::App::Satpass2::ParseTime>.

=head2 dmd_err

 my $error_string = $pt->dmd_err();

This method wraps the L<Date::Manip::Date|Date::Manip::Date> object's
C<err()> method, and returns whatever that method
returns.

=head2 dmd_zone

 my $zone_name = $pt->dmd_zone();

This method wraps the L<Date::Manip::TZ|Date::Manip::TZ> object's
C<zone()> method, calling it in scalar context to
get the default zone name, and returning the result.

Note that unlike the inherited C<tz()> method, this is an accessor
only, and, it is possible that C<< $pt->dmd_zone() >> will not return
the same thing that C<< $pt->tz() >> does. For example,

 $pt->tz( 'EST5EDT' );
 print '$pt->tz(): ', $pt->tz(), "\n";
 print '$pt->dmd_zone(): ', $pt->dmd_zone(), "\n";

prints

 $pt->tz(): EST5EDT
 $pt->dmd_zone(): America/New_York

This is because C<< $pt->tz() >> returns the last setting, whereas C<<
$pt->dmd_zone() >> returns the name of the time zone in the Olson
zoneinfo database, which is typically something like C<Continent/City>,
even though the time zone was set using an alias, abbreviation or
offset. See L<Date::Manip::TZ|Date::Manip::TZ> for the gory details.

Another difference is the if the time zone has never been set,
C<< $pt->tz() >> will return C<undef>, whereas
C<< $pt->dmd_zone() >> will actually return the name of the default
zone.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

__END__

# ex: set textwidth=72 :

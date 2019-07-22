package Astro::App::Satpass2::Format;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::Copier };

use Clone ();
use Astro::App::Satpass2::FormatTime;
use Astro::App::Satpass2::Utils qw{
    load_package __parse_class_and_args
    CODE_REF
    @CARP_NOT
};

our $VERSION = '0.040';

use constant DEFAULT_LOCAL_COORD => 'azel_rng';

# Note that the fact that new() works when called from
# My::Module::Test::App is unsupported and undocumented, and
# the functionality may be revoked or changed without warning.

my %static = (
    desired_equinox_dynamical => 0,
    gmt		=> 0,
    local_coord	=> DEFAULT_LOCAL_COORD,
    provider	=> 'Astro::App::Satpass2',
    value_formatter	=> 'Astro::App::Satpass2::FormatValue',
);

sub new {
    my ( $class, %args ) = @_;
    ref $class and $class = ref $class;

    my $self = { %static };
    bless $self, $class;

    $self->warner( delete $args{warner} );

    $class eq __PACKAGE__
	and 'My::Module::Test::App' ne caller
	and $self->wail( __PACKAGE__,
	    ' may not be instantiated. Use a subclass' );

    exists $args{tz} or $args{tz} = $ENV{TZ};

    $self->time_formatter( delete $args{time_formatter} );
    $self->time_formatter()->warner( $self->warner() );

    $args{date_format}
	or $self->date_format( $self->time_formatter()->DATE_FORMAT() );
    $args{time_format}
	or $self->time_format( $self->time_formatter()->TIME_FORMAT() );
    exists $args{round_time}
	or $self->round_time( $self->time_formatter()->ROUND_TIME() );

    $self->value_formatter( delete $args{value_formatter} ||
	$static{value_formatter} );
    $self->value_formatter()->warner( $self->warner() );

    $self->init( %args );

    return $self;
}

sub round_time {
    my ( $self, @arg ) = @_;
    if ( @arg ) {
	$self->time_formatter()->round_time( @arg );
	$self->{round_time} = $arg[0];
	return $self;
    } else {
	return $self->time_formatter()->round_time();
    }
}

sub attribute_names {
    my ( $self ) = @_;
    return ( $self->SUPER::attribute_names(),
	qw{ date_format desired_equinox_dynamical gmt
	    local_coord provider round_time
	    time_format time_formatter tz
	    value_formatter
	} );
}

{

    my %original_value = (
	date_format	=> sub {
	    return $_[0]->time_formatter()->DATE_FORMAT()
	},
	round_time	=> sub {
	    return $_[0]->time_formatter()->ROUND_TIME()
	},
	time_format	=> sub {
	    return $_[0]->time_formatter()->TIME_FORMAT()
	},
    );

    foreach my $key ( keys %static ) {
	$original_value{ $key } ||= sub {
	    return $static{$key};
	};
    }

    my %not_part_of_config = map { $_ => 1 } qw{ warner };

    sub config {
	my ( $self, %args ) = @_;
	my @data;

	foreach my $name ( $self->attribute_names() ) {

	    $not_part_of_config{$name}
		and next;

	    my $val = $self->$name();
	    $args{decode}
		and ref $val
		and $val = $self->decode( $name );

	    no warnings qw{ uninitialized };

	    next if $args{changes} &&
		$val eq ( $original_value{$name} ?
		    $original_value{$name}->( $self, $name ) :
		    undef );

	    push @data, [ $name, $val ];
	}

	return wantarray ? @data : \@data;
    }

}

{

    my %decoder = (
	desired_equinox_dynamical => sub {
	    my ( $self, $method, @args ) = @_;
	    my $rslt = $self->$method( @args );
	    @args and return $rslt;
	    $rslt or return $rslt;
	    return $self->{time_formatter}->format_datetime(
		$self->{time_formatter}->ISO_8601_FORMAT(),
		$rslt, 1 );
	},
	time_formatter => sub {
	    my ( $self, $method, @args ) = @_;
	    my $rslt = $self->$method( @args );
	    @args and return $rslt;
#	    return ref $rslt || $rslt;
	    return $rslt->class_name_of_record();
	},
    );
    $decoder{value_formatter} = $decoder{time_formatter};

    sub decode {
	my ( $self, $method, @args ) = @_;
	my $dcdr = $decoder{$method}
	    or return $self->$method( @args );
	my $type = ref $dcdr
	    or $self->weep( "Decoder for $method is scalar" );
	CODE_REF eq $type
	    or $self->weep(
		"Decoder for $method is $type reference" );
	return $dcdr->( $self, $method, @args );
    }
}

sub format : method {	## no critic (ProhibitBuiltInHomonyms,RequireFinalReturn)
    my ( $self ) = @_;
    # ->weep() throws an exception.
    $self->weep(
	'The format() method must be overridden' );
}

sub local_coord {
    my ( $self, @args ) = @_;
    if ( @args ) {
	defined $args[0] or $args[0] = DEFAULT_LOCAL_COORD;
	$self->{local_coord} = $args[0];
	return $self;
    } else {
	return $self->{local_coord};
    }
}

foreach my $attribute (
    [ time_formatter => 'Astro::App::Satpass2::FormatTime',
	'Astro::App::Satpass2::FormatTime', sub {
	    my ( $self, $old, $new ) = @_;
	    if ( $old->FORMAT_TYPE() ne $new->FORMAT_TYPE() ) {
		$self->date_format( $new->DATE_FORMAT() );
		$self->time_format( $new->TIME_FORMAT() );
	    }
	    return;
	},
    ],
    [ value_formatter => 'Astro::App::Satpass2::FormatValue',
	'Astro::App::Satpass2', sub {}	],
) {
    my ( $name, $class, $prefix, $pre_set ) = @{ $attribute };
    __PACKAGE__->can( $name )
	and next;
    no strict qw{ refs };
    *$name = sub {
	my ( $self, @args ) = @_;
	if ( @args ) {
	    my $fmtr = shift @args;
	    defined $fmtr and $fmtr ne ''
		or $fmtr = $class;
	    my $old = $self->{$name};
	    ref $fmtr or do {
		my ( $pkg, @fmtr_arg ) = (
		    $self->__parse_class_and_args( $fmtr ), @args );
		my $class = $self->load_package(
		    { fatal => 'wail' }, $pkg, $prefix );
		$fmtr = $class->new( @fmtr_arg );
		ref $old
		    and $old->copy( $fmtr, @fmtr_arg );
	    };
	    ref $old
		and $pre_set->( $self, $old, $fmtr );
	    $self->{$name} = $fmtr;
	    return $self;
	} else {
	    return $self->{$name};
	}
    };
}

sub tz {
    my ( $self, @args ) = @_;
    if ( @args ) {
	$self->{tz} = $args[0];
	return $self;
    } else {
	return $self->{tz};
    }
}

sub warner {
    my ( $self, @args ) = @_;
    if ( @args ) {
	my $warner = $args[0];
	if ( my $fmtr = $self->time_formatter() ) {
	    $fmtr->warner( $warner );
	}
    }
    return $self->SUPER::warner( @args );
}

__PACKAGE__->create_attribute_methods();

1;

=head1 NAME

Astro::App::Satpass2::Format - Format Astro::App::Satpass2 output

=head1 SYNOPSIS

No user-serviceable parts inside.

=head1 DETAILS

This formatter is an abstract class providing output formatting
functionality for L<Astro::App::Satpass2|Astro::App::Satpass2>. It
should not be instantiated directly.

This class is a subclass of
L<Astro::App::Satpass2::Copier|Astro::App::Satpass2::Copier>.

=head1 METHODS

This class supports the following public methods:

=head2 Instantiator

=head3 new

 $fmt = Astro::Satpass::Format::Some_Subclass_Thereof->new(...);

This method instantiates a formatter. It may not be called on this
class, but may be called on a subclass. If you wish to modify the
default attribute values you can pass the relevant name/value pairs as
arguments. For example:

 $fmt = Astro::Satpass::Format::Some_Subclass_Thereof->new(
     date_format => '%Y%m%d',
     time_format => 'T%H:%M:%S',
 );

=head2 Accessors and Mutators

=head3 date_format

 print 'Date format: ', $fmt->date_format(), "\n";
 $fmt->date_format( '%d-%b-%Y' );

The C<date_format> attribute is maintained on behalf of subclasses of
this class, which B<may> (but need not) use it to format dates. This
method B<may> be overridden by subclasses, but the override B<must> call
C<SUPER::date_format>, and return values consistent with the following
description.

This method acts as both accessor and mutator for the C<date_format>
attribute. Without arguments it is an accessor, returning the current
value of the C<date_format> attribute.

If passed an argument, that argument becomes the new value of
C<date_format>, and the object itself is returned so that calls may be
chained.

The interpretation of the argument is up to the subclass, but
it is recommended for sanity's sake that the subclasses interpret this
value as a C<POSIX::strftime> format producing a date (but not a time),
if they use this attribute at all.

The default value, if used by the subclass at all, should produce a
numeric date of the form year-month-day. For formatters that use
C<strftime()>, this will be '%Y-%m-%d'.

B<Note> that this value will be reset to its default if the
L<time_formatter|/time_formatter> attribute is modified and the new
object has a different C<FORMATTER_TYPE()> than the old one.

=head3 desired_equinox_dynamical

 print 'Desired equinox: ',
     strftime( '%d-%b-%Y %H:%M:%S dynamical',
         gmtime $fmt->desired_equinox_dynamical() ),
     "\n"; 
 $fmt->desired_equinox_dynamical(
     timegm( 0, 0, 12, 1, 0, 100 ) );	# J2000.0

The C<desired_equinox_dynamical> attribute is maintained on behalf of
subclasses of this class, which B<may> (but need not) use it to
calculate inertial coordinates. If the subclass does not make use of
this attribute it B<must> document the fact.

This method B<may> be overridden by subclasses, but the override B<must>
call C<SUPER::desired_equinox_dynamical>, and return values consistent
with the following description.

This method acts as both accessor and mutator for the
C<desired_equinox_dynamical> attribute. Without arguments it is an
accessor, returning the current value of the
C<desired_equinox_dynamical> attribute.

If passed an argument, that argument becomes the new value of
C<desired_equinox_dynamical>, and the object itself is returned so that
calls may be chained.

The interpretation of the argument is up to the subclass, but it is
recommended for sanity's sake that the subclasses interpret this value
as a dynamical time (even though it is represented as a normal Perl
time) if they use this attribute at all. If the value is true (in the
Perl sense) inertial coordinates should be precessed to the dynamical
time represented by this attribute. If the value is false (in the Perl
sense) they should not be precessed.

=head3 gmt

 print 'Time zone: ', ( $fmt->gmt() ? 'GMT' : 'local' ), "\n";
 $fmt->gmt( 1 );

The C<gmt> attribute is maintained on behalf of subclasses of this
class, which B<may> (but need not) use it to decide whether to display
dates in GMT or in the local time zone. This method B<may> be overridden
by subclasses, but the override B<must> call C<SUPER::gmt>, and return
values consistent with the following description.

This method acts as both accessor and mutator for the C<gmt>
attribute. Without arguments it is an accessor, returning the current
value of the C<gmt> attribute. This value is to be interpreted as a
Boolean under the usual Perl rules.

If passed an argument, that argument becomes the new value of
C<gmt>, and the object itself is returned so that calls may be
chained.

=head3 local_coord

 print 'Local coord: ', $fmt->local_coord(), "\n";
 $fmt->local_coord( 'azel_rng' );

The C<local_coord> attribute is maintained on behalf of subclasses of
this class, which B<may> (but need not) use it to determine what
coordinates to display. This method B<may> be overridden by subclasses,
but the override B<must> call C<SUPER::local_coord>, and return values
consistent with the following description.

This method acts as both accessor and mutator for the C<local_coord>
attribute. Without arguments it is an accessor, returning the current
value of the C<local_coord> attribute.

If passed an argument, that argument becomes the new value of
C<local_coord>, and the object itself is returned so that calls may be
chained. The interpretation of the argument is up to the subclass, but
it is recommended for sanity's sake that the subclasses support at least
the following values if they use this attribute at all:

 az_rng --------- azimuth and range;
 azel ----------- azimuth and elevation;
 azel_rng ------- azimuth, elevation and range;
 equatorial ----- right ascension and declination;
 equatorial_rng - right ascension, declination and range.

It is further recommended that C<azel_rng> be the default.

=head3 provider

 print 'Provider: ', $fmt->provider(), "\n";
 $fmt->provider( 'Astro::App::Satpass2 v' . Astro::App::Satpass2->VERSION() );

The C<provider> attribute is maintained on behalf of subclasses of this
class, which B<may> (but need not) use it to identify the provider of
the data for informational purposes. This method B<may> be overridden by
subclasses, but the override B<must> call C<SUPER::provider>, and return
values consistent with the following description.

This method acts as both accessor and mutator for the C<provider>
attribute. Without arguments it is an accessor, returning the current
value of the C<provider> attribute.

If passed an argument, that argument becomes the new value of
C<provider>, and the object itself is returned so that calls may be
chained.

=head3 round_time

 print 'Time rounded to: ', $fmt->round_time(), " seconds\n";
 $fmt->round_time( 60 );

The C<round_time> attribute is maintained on behalf of subclasses of
this class, which B<may> (but need not) use it to format times. This
method B<may> be overridden by subclasses, but the override B<must> call
C<SUPER::round_time>, and return values consistent with the following
description.

This method acts as both accessor and mutator for the C<round_time>
attribute. Without arguments it is an accessor, returning the current
value of the C<round_time> attribute.

If passed an argument, that argument becomes the new value of
C<round_time>, and the object itself is returned so that calls may be
chained.

The interpretation of the argument is up to the subclass, but
it is recommended for sanity's sake that the subclasses interpret this
value in the same way as
L<Astro::App::Satpass2::FormatTime|Astro::App::Satpass2::FormatTime>
if they use this attribute at all.

=head3 time_format

 print 'Time format: ', $fmt->time_format(), "\n";
 $fmt->time_format( '%H:%M:%S' );

The C<time_format> attribute is maintained on behalf of subclasses of
this class, which B<may> (but need not) use it to format times. This
method B<may> be overridden by subclasses, but the override B<must> call
C<SUPER::time_format>, and return values consistent with the following
description.

This method acts as both accessor and mutator for the C<time_format>
attribute. Without arguments it is an accessor, returning the current
value of the C<time_format> attribute.

If passed an argument, that argument becomes the new value of
C<time_format>, and the object itself is returned so that calls may be
chained.

The interpretation of the argument is up to the subclass, but
it is recommended for sanity's sake that the subclasses interpret this
value as a C<POSIX::strftime> format producing a time (but not a date),
if they use this attribute at all.

The default value, if used by the subclass at all, should produce a
numeric time of the form hour:minute:second. For formatters that use
C<strftime()>, this will be '%H:%M:%S'.

B<Note> that this value will be reset to its default if the
L<time_formatter|/time_formatter> attribute is modified and the new
object has a different C<FORMATTER_TYPE()> than the old one.

=head3 time_formatter

This method acts as both accessor and mutator for the object used to
format times. It will probably be a
L<Astro::App::Satpass2::FormatTime|Astro::App::Satpass2::FormatTime>
object of some sort, and will certainly conform to that interface. When
setting the value, you can specify either a class name or an object. If
a class name, the leading C<Astro::App::Satpass2::FormatTime::> can be
omitted.

B<Note> that setting this will reset the L<date_format|/date_format> and
L<time_format|/time_format> attributes to values appropriate to the
new time formatter's class, if the new formatter object has a different
C<FORMATTER_TYPE()> than the old one.

=head3 tz

 print 'Time zone: ', $fmt->tz()->name(), "\n";
 $fmt->tz( 'MST7MDT' );

The C<tz> attribute is maintained on behalf of subclasses of this class,
which B<may> (but need not) use it to format times. This method B<may>
be overridden by subclasses, but the override B<must> call C<SUPER::tz>,
and return values consistent with the following description.

This method acts as both accessor and mutator for the C<tz> attribute.
Without arguments it is an accessor, returning the current value of the
C<tz> attribute.

If passed an argument, that argument becomes the new value of C<tz>, and
the object itself is returned so that calls may be chained.

The use of the argument is up to the subclass, but it is
recommended for sanity's sake that the subclasses interpret this value
as a time zone to be used to derive the local time if they use this
attribute at all.

A complication is that subclasses may need to validate zone values. It
is to be hoped that their digestions will be rugged enough to handle the
usual conventions, since convention rather than standard seems to rule
here.

=head3 value_formatter

This method acts as both accessor and mutator for the object used to
format values. It will probably be a
L<Astro::App::Satpass2::FormatValue|Astro::App::Satpass2::FormatValue>
object of some sort, and will certainly conform to that interface. When
setting the value, you can specify either a class name or an object. If
a class name, the leading C<Astro::App::Satpass2::> can be omitted.

Author's note:

This method is B<experimental and unsupported>. Documentation is for the
benefit of the author and the curious. I wanted to screw around with
extra formatters, and the best way to do that seemed to be to subclass
C<Astro::App::Satpass2::FormatValue>, but then I needed a way to put the
subclass into use. But I am not really ready to document the necessary
interface (and therefore commit to not changing it, or at least not
doing so without going through a deprecation cycle). If you have a need
for this kind of thing, please contact me.

=head2 Formatters

There is actually only one formatter method. The subclass B<must>
provide it, because this class does not.

=head3 format

 print $fmt->format( template => $name, data => $data );

This method takes named arguments.

The only required argument is C<template>, which specifies what kind of
data are expected, and how it is to be formatted. These are described
below. The name of the C<template> argument assumes an implementation in
terms of some sort of templating system, but a subclass can implement
formatting in any way it pleases.

The C<data> argument is normally required, and must be the data expected
by the specified C<template>. However, B<if> the formatter supports it,
the C<sp> argument can be specified in lieu of C<data>. The C<sp>
argument should be an L<Astro::App::Satpass2|Astro::App::Satpass2>
object, and it only does anything if the specific formatter is capable
of handling it.

The supported template names, and the data required by each, are as
follows:

=over

=item almanac

The C<$data> argument is expected to be a reference to an array of hash
references, which are presumed to be output from the C<almanac_hash()>
method of such L<Astro::Coord::ECI|Astro::Coord::ECI> subclasses that
have such a method.

=item flare

The C<$data> argument is expected to be a reference to an array of hash
references, which are presumed to be output from the
L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium>
C<flare()> method.

=item list

The C<$data> argument is expected to be a reference to an array of
L<Astro::Coord::ECI|Astro::Coord::ECI> or
L<Astro::Coord::ECI::TLE::Set|Astro::Coord::ECI::TLE::Set> objects. The
description generated by this method should be appropriate for a
satellite.

=item location

The C<$data> argument is expected to be an
L<Astro::Coord::ECI|Astro::Coord::ECI> object. This description should
be appropriate for a ground station.

=item pass

The C<$data> argument is expected to be a reference to an array of hash
references, which are presumed to be output from the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> C<pass()> method.

=item pass_events

The C<$data> argument is expected to be a reference to an array of hash
references, which are presumed to be output from the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> C<pass()> method.

This template is expected to format a description of individual events
of satellite passes for the L<pass|Astro::App::Satpass2/pass> command
with the C<-events> option.

=item phase

The C<$data> argument is expected to be a reference to an array of
C<Astro::Coord::ECI|Astro::Coord::ECI> objects which support the
C<phase()> method and which have already had their time set to the
desired time.

=item position

This template is intended to format the position (and possibly other
data) of a set of bodies for the
L<position|Astro::App::Satpass2/position> command.

The C<$data> argument is expected to be a hash containing relevant data.
The following hash keys are required:

 {bodies} - a reference to an array of bodies to report;
 {station} - the observing station;
 {time} - the time to be reported;

Both C<{bodies}> and C<{station}> must contain
L<Astro::Coord::ECI|Astro::Coord::ECI> or
C<Astro::Coord::ECI::TLE::Set|Astro::Coord::ECI::TLE::Set> objects. The
bodies must already have had their times set to the desired time.

In addition, the following keys are recommended:

 {questionable} - true to do flare calculations for questionable
         sources;
 {twilight} - twilight, in radians (negative).

If the C<{twilight}> key is omitted, it will be set to civil twilight
(i.e. the radian equivalent of -6 degrees).

Yes, this is more complex than the others, but the function is more
ad-hoc.

=item tle

The C<$data> argument is expected to be a reference to an array of
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> objects. The output
should be compatible with the normal TLE format as documented at
L<http://celestrak.com>.

=item tle_verbose

The C<$data> argument is expected to be a reference to an array of
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> objects. The output
should be an expanded output of the data in a TLE (say, one line per
datum, labeled and with units).

=back

=head2 Other Methods

The following other methods are provided.

=head3 config

 use YAML;
 print Dump ( $pt->config( changes => 1 ) );

This method retrieves the configuration of the formatter as an array of
array references. The first element of each array reference is a method
name, and the subsequent elements are arguments to that method. Calling
the given methods with the given arguments should reproduce the
configuration of the formatter. If called in scalar context, it returns
a reference to the array.

There are two named arguments:

=over

=item changes

If this boolean argument is true (in the Perl sense), only changes from
the default configuration are reported.

=item decode

If this boolean argument is true (in the Perl sense), the
L<decode()|/decode> method is used to obtain the configuration values.

=back

Subclasses that add other ways to configure the object B<must> override
this method. The override B<must> call C<SUPER::config()>, and include
the result in the returned data.

=head2 decode

 $fmt->decode( 'desired_equinox_dynamical' );

This method wraps other methods, converting their returned values to
human-readable. The arguments are the name of the method, and its
arguments if any. The return values of methods not explicitly documented
below are not modified.

The following methods return something different when invoked via this
method:

=over

=item desired_equinox_dynamical

If called as an accessor, the returned time is converted to an ISO-8601
time in the GMT zone. If called as a mutator, you still get back the
object reference.

=item time_formatter

If called as an accessor, the class name of the object being used to
format the time is returned. If called as a mutator, you still get back
the object reference.

=back

If a subclass overrides this method, the override should either perform
the decoding itself, or delegate to C<SUPER::decode>.

=head1 SEE ALSO

L<Astro::App::Satpass2|Astro::App::Satpass2>, which is the intended user of this
functionality.

L<Astro::Coord::ECI|Astro::Coord::ECI> and associated modules, which are
the intended providers of data for this functionality.

L<Astro::App::Satpass2::Format::Dump|Astro::App::Satpass2::Format::Dump>, which is a
subclass of this module. It is intended for debugging, and simply dumps
its arguments in Data::Dumper, JSON, or YAML format depending on how it
is configured and what modules are installed

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

__END__

# ex: set textwidth=72 :

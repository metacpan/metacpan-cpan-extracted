package Astro::App::Satpass2::ParseTime;

use 5.008;

use strict;
use warnings;

use parent qw{ Astro::App::Satpass2::Copier };

use Astro::App::Satpass2::FormatTime;
use Astro::App::Satpass2::Utils qw{
    load_package
    ARRAY_REF CODE_REF SCALAR_REF
    @CARP_NOT
};
use Astro::Coord::ECI::Utils 0.059 qw{ looks_like_number };

our $VERSION = '0.040';

my %static = (
    perltime	=> 0,
);

sub new {
    my ( $class, %args ) = @_;
    ref $class and $class = ref $class;

    # Workaround for bug (well, _I_ think it's a bug) introduced into
    # Date::Manip with 6.34, while fixing RT #78566. My bug report is RT
    # #80435.
    my $path = $ENV{PATH};
    local $ENV{PATH} = $path;

    if ( __PACKAGE__ eq $class ) {

	$args{class} ||= [ qw{ Date::Manip ISO8601 } ];

	my @classes = ARRAY_REF eq ref $args{class} ? @{ $args{class} } :
	    split qr{ \s* , \s* }smx, $args{class};

	$class = _try ( @classes )
	    or return;

    } else {
	$class = _try( $class )
	    or return;
    }
    delete $args{class};

    defined $args{base}
	or $args{base} = time;

    my $self = { %static };
    bless $self, $class;
    $self->warner( delete $args{warner} );
    $self->base( delete $args{base} );
    $self->init( %args );
    return $self;
}

sub attribute_names {
    my ( $self ) = @_;
    return ( $self->SUPER::attribute_names(), qw{
	base perltime tz } );
}

sub base {
    my ( $self, @args ) = @_;
    if ( @args > 0 ) {
	$self->{base} = $self->{absolute} = $args[0];
	return $self;
    }
    return $self->{base};
}

sub class_name_of_record {
    my ( $self ) = @_;
    my $rslt = substr $self->__class_name(), 2 + length __PACKAGE__;
    foreach my $attr ( qw{ tz } ) {
	my $value = $self->$attr()
	    or next;
	$rslt .= ",$attr=$value";
    }
    return $rslt;
}

# For the use of class_name_of_record(). It exists so that
# Astro::App::Satpass2::ParseTime::Date::Manip can override it, so that
# we do not get the trailing '::v5' or '::v6';
sub __class_name {
    my ( $self ) = @_;
    return ref $self;
}

{

    my %skip = map { $_ => 1 } qw{ base warner };

    sub config {
	my ( $self, %args ) = @_;
	my @data;

	foreach my $name ( $self->attribute_names() ) {
	    $skip{$name} and next;
	    my $val = $self->$name();
	    no warnings qw{ uninitialized };
	    next if $args{changes} && $val eq $static{$name};
	    push @data, [ $name, $args{decode} ? $self->decode( $name )
		: $val ];
	}

	return wantarray ? @data : \@data;
    }

}

sub delegate {	## no critic (RequireFinalReturn)
    my ( $self ) = @_;
    $self->weep( 'The delegate() method must be overridden' );
    # Weep throws an exception, but there is no way to tell perlcritic
    # this.
}

{

    my %decoder = (
	base	=> sub {
	    my ( $self, $method, @args ) = @_;
	    my $rslt = $self->$method( @args );
	    @args
		and return $rslt;
	    $rslt
		or return $rslt;
	    $self->{_time_formatter} ||=
		Astro::App::Satpass2::FormatTime->new();
	    return $self->{_time_formatter}->format_datetime(
		$self->{_time_formatter}->ISO_8601_FORMAT(),
		$rslt, 1 );
	},
    );

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

{

    my @scale = ( 24, 60, 60, 1 );

    sub parse {
	my ( $self, $string, $default ) = @_;

	if ( SCALAR_REF eq ref $string ) {
	    my $time = ${ $string };
	    $self->base( $self->{absolute} = $time );
	    return $time;
	}

	if ( ! defined $string || '' eq $string ) {
	    defined $default
		and $self->base( $self->{absolute} = $default );
	    return $default;
	}

	if ( $string =~ m/ \A \s* [+-] /smx ) {
	    defined $self->{base} or return;
	    defined $self->{absolute}
		or $self->{absolute} = $self->base();
	    $string =~ s/ \A \s+ //smx;
	    $string =~ s/ \s+ \z //smx;
	    my $sign = substr $string, 0, 1;
	    substr( $string, 0, 1, '' );
	    my @delta = split qr{ \s* : \s* | \s+ }smx, $string;
	    @delta > 4 and return;
	    push @delta, ( 0 ) x ( 4 - @delta );
	    my $dt = 0;
	    foreach my $inx ( 0 .. 3 ) {
		looks_like_number( $delta[$inx] ) or return;
		$dt += $delta[$inx];
		$dt *= $scale[$inx];
	    }
	    '-' eq $sign and $dt = - $dt;
	    return ( $self->{absolute} = $dt + $self->{absolute} );

	} elsif ( $string =~
	    m/ \A epoch \s* ( [0-9]+ (?: [.] [0-9]* )? ) \z /smx ) {

	    my $time = $1 + 0;
	    $self->base( $self->{absolute} = $time );
	    return $time;

	} else {

	    defined( my $time = $self->parse_time_absolute( $string ) )
		or return;
	    $self->base( $self->{absolute} = $time );
	    return $time;

	}

    }

}

sub parse_time_absolute {	## no critic (RequireFinalReturn)
##  my ( $self, $string ) = @_;
    my ( $self ) = @_;		# $string unused
    $self->weep(
	'parse_time_absolute() must be overridden' );
    # Weep throws an exception, but there is no way to tell perlcritic
    # this.
}

sub reset : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    $self->{absolute} = $self->base();
    return $self;
}

sub use_perltime {
    return 0;
}

{

    # %trial is indexed by class name. The value is the class to
    # delegate to (which can be the same as the class itself), or undef
    # if the class can not be loaded, or has no delegate.

    my %trial;

    sub _try {
	my ( @args ) = @_;

	my @flatten;

	while ( @args ) {

	    my $try = shift @args;

	    $trial{$try} and return $trial{$try};

	    exists $trial{$try} and next;

	    $try =~ m/ \A \w+ (?: :: \w+ )* \z /smx or do {
		$trial{$try} = undef;
		next;
	    };

	    my $pkg = $trial{$try} = load_package(
		$try, 'Astro::App::Satpass2::ParseTime' )
		or next;

	    my $delegate = $trial{$try} = eval { $pkg->delegate() }
		or next;

	    if ( $trial{$delegate} ) {
		foreach ( @flatten ) {
		    $trial{$_} = $delegate;
		}
		return $delegate;
	    }

	    push @flatten, $try;
	    unshift @args, $delegate;
	}

	return;
    }
}

__PACKAGE__->create_attribute_methods();

1;

__END__

=head1 NAME

Astro::App::Satpass2::ParseTime - Parse time for Astro::App::Satpass2

=head1 SYNOPSIS

 my $pt = Astro::App::Satpass2::ParseTime->new();
 defined( my $epoch_time = $pt->parse( $string ) )
   or die "Unable to parse time '$string'";

=head1 NOTICE

This class and its subclasses are private to the
L<Astro::App::Satpass2|Astro::App::Satpass2> package. The author
reserves the right to add, change, or retract functionality without
notice.

=head1 DETAILS

This class provides an interface to the possible time parsers. A
subclass of this class provides (or wraps) a parser, and exposes that
parser through a C<parse_time_absolute()> method.

There are actually three time formats supported by this parser.

Relative times begin with a '+' or a '-', and represent the number of
days, hours, minutes and seconds since (or before) the
most-recently-specified absolute time. The individual components (days,
hours, minutes and seconds) are separated by either colons or white
space. Trailing components (and separators) may be omitted, and default
to 0.

Epoch times are composed of the string 'epoch ' followed by a number,
and represent that time relative to Perl's epoch. It would have been
nice to just accept a number here, but it was impossible to disambiguate
a Perl epoch from an ISO-8601 time without punctuation.

Scalar references are also interpreted as epoch times.

Absolute times are anything not corresponding to the above. These are
the only times actually passed to L</parse_time_absolute>.

This class is a subclass if
L<Astro::App::Satpass2::Copier|Astro::App::Satpass2::Copier>.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $pt = Astro::App::Satpass2::ParseTime->new();

This method instantiates the parser. The actual returned class will be
the first that can be instantiated in the list
L<Astro::App::Satpass2::ParseTime::Date::Manip|Astro::App::Satpass2::ParseTime::Date::Manip>,
L<Astro::App::Satpass2::ParseTime::ISO8601|Astro::App::Satpass2::ParseTime::ISO8601>.

You can specify optional arguments to C<new()> as name/value pairs. The
following name/value pairs are implemented:

=over

=item class

This argument specifies the short name of the class to instantiate (i.e.
the part of the name after C<'Astro::App::Satpass2::ParseTime::'>. You
can specify multiple values, either by separating them with commas or as
an array reference. If multiple values are specified, you get the first
that can actually be instantiated.

The default is C<'Date::Manip,ISO8601'> (or, equivalently,
C<[ qw{ Date::Manip ISO8601 ]>).

=item tz

This argument specifies the default time zone.

=back

=head2 base

 $pt->base( time );    # Set base time to now
 $base = $pt->base();  # Retrieve current base time

This method is both accessor and mutator for the object's base time.
This time is used (indirectly) when the parse identifies a relative
time.

When called without arguments, it behaves as an accessor, and returns
the current base time setting.

When called with at least one argument, it behaves as a mutator, sets
the base time, and returns the C<$pt> object to allow call chaining.

Subclasses B<may> override this method, but if they do so they B<must>
call C<SUPER::> with the same arguments they themselves were called
with, and return whatever C<SUPER::> returns.

=head2 config

 use YAML;
 print Dump ( $pt->config( changes => 1 );

This method retrieves the configuration of the formatter as an array of
array references. The first element of each array reference is a method
name, and the subsequent elements are arguments to that method. Calling
the given methods with the given arguments should reproduce the
configuration of the formatter.

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

=head2 delegate

 my $delegate = $class->delegate()

This static method returns the name of the class to be instantiated.
Normally a subclass will return its own class name, but if there is more
than one possible wrapper for a given parser (e.g.
L<Date::Manip|Date::Manip>, which gets handled differently based on its
version number), the wrapper should return the name of the desired
class.

This method B<must> be overridden by any subclass.

=head2 decode

 $pt->decode( 'tz' );

This method wraps other methods, converting their returned values to
human-readable. The arguments are the name of the method, and its
arguments if any. The return values of methods not explicitly documented
below are not modified.

There are currently no methods whose returns are affected by routing
them through C<decode>. This may change.

If a subclass overrides this method, the override should either perform
the decoding itself, or delegate to C<SUPER::decode>.

=head2 parse_time_absolute

 $epoch_time = $pt->parse_time_absolute( $string );

This method parses an absolute time string. It returns seconds since the
epoch, or C<undef> on error.

This method B<must> be overridden by any subclass.

=head2 perltime

 $pt->perltime( 1 );            # Turn on the perltime hack
 $perltime = $pt->perltime();	# Find out whether the hack is on

This method is both accessor and mutator for the object's perltime flag.
This is a Boolean flag which the subclass may (or may not!) use to get
the summer time straight when parsing time. If the flag is on (and the
subclass supports it) the tz setting is ignored, and an attempt to
specify a time zone in a time to be parsed will produce undefined
results.

When called without arguments, it behaves as an accessor, and returns
the current perltime flag setting.

When called with at least one argument, it behaves as a mutator, sets
the perltime flag, and returns the C<$pt> object to allow call chaining.

This specific method simply records the C<perltime> setting.

Subclasses B<may> override this method, but if they do so they B<must>
call C<SUPER::> with the same arguments they themselves were called
with, and return whatever C<SUPER::> returns.

=head2 parse

 defined( $epoch_time = $pt->parse( $string, $default ) )
   or die "'$string' can not be parsed.";

This method parses a time, returning the resultant Perl time. If
C<$string> is C<undef> or C<''>, $default is returned, or C<undef> if
C<$default> is not specified. If C<$string> fails to parse, C<undef> is
returned.

=head2 reset

 $pt->reset();

This method resets the base time for relative times to the value of the
C<base> attribute. It returns the C<$pt> object to allow for call
chaining.

=head2 use_perltime

 $classname->use_perltime()

This static method returns true if the class uses the C<perltime>
mechanism, and false otherwise.

This specific class simply returns false.

Subclasses may override this method, but if they do they B<must not>
call C<SUPER::>.

=head2 tz

 $pt->tz( 'EST5EDT' );          # Specify an explicit time zone
 $pt->tz( undef );              # Specify the default time zone
 $tz = $pt->tz();               # Find out what the time zone is

This method is both accessor and mutator for the object's time zone
setting. What can go here depends on the specific subclass in use.

When called without arguments, it behaves as an accessor, and returns
the current time zone setting.

When called with at least one argument, it behaves as a mutator, sets
the time zone, and returns the C<$pt> object to allow call chaining.

This specific method simply records the C<tz> setting.

Subclasses B<may> override this method, but if they do so they B<must>
call C<SUPER::> with the same arguments they themselves were called
with, and return whatever C<SUPER::> returns. Also, overrides B<must>
interpret an C<undef> argument as a request to set the default time
zone, not as an accessor call.

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

# ex: set textwidth=72 :

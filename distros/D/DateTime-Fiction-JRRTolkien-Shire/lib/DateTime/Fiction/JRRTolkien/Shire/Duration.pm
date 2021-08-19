package DateTime::Fiction::JRRTolkien::Shire::Duration;

use 5.008004;

use strict;
use warnings;

use Carp ();
use DateTime::Duration 0.140 ();
use DateTime::Fiction::JRRTolkien::Shire::Types ();
use Params::ValidationCompiler 0.13 ();
use Scalar::Util ();

*__t = \&DateTime::Fiction::JRRTolkien::Shire::Types::t;

use overload
    fallback	=> 1,
    '+'		=> '_add_overload',
    '-'		=> '_subtract_overload',
    '*'		=> '_multiply_overload',
    '<=>'	=> '_compare_overload',
    'cmp'	=> '_compare_overload',
    ;

our $VERSION = '0.907';

{

    my $validate = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_new',
	name_is_optional	=> 1,
	params	=> {
	    years		=> { type => __t( 'IntOrUndef' ) },
	    months		=> { type => __t( 'IntOrUndef' ) },
	    weeks		=> { type => __t( 'IntOrUndef' ) },
	},
    );

    sub new {
	my ( $class, %arg ) = @_;

	$validate->(
	    years		=> $arg{years},
	    months		=> $arg{months},
	    weeks		=> $arg{weeks},
	);

	$arg{$_} ||= 0 foreach qw{ years months weeks days };

	my $default_mode;
	( my $mode_specified = $arg{end_of_month} || $arg{holiday} )
	    or $default_mode = _compute_default_mode( \%arg );

	my $years = delete $arg{years};
	my $weeks = delete $arg{weeks};

	if ( defined $arg{holiday} ) {
	    defined $arg{end_of_month}
		and Carp::croak(
		q<You may not specify both end_of_month and holiday> );
	    $arg{end_of_month} = _map_holiday_mode( delete $arg{holiday} );
	}

	defined $arg{end_of_month}
	    or $arg{end_of_month} = $default_mode;

	return bless {
	    duration	=> DateTime::Duration->new( %arg ),
	    mode_specified	=> $mode_specified,
	    weeks		=> $weeks,
	    years		=> $years,
	}, ref $class || $class;
    }
}

sub add {
    my ( $self, @arg ) = @_;
    return $self->add_duration( _make_duration( @arg ) );
}

sub add_duration {
    my ( $self, $dur ) = @_;
    if ( _isa( $dur, __PACKAGE__ ) ) {
	$self->{weeks} += $dur->{weeks};
	$self->{duration}->add_duration( $dur->{duration} );
    } elsif ( _isa( $dur, 'DateTime::Duration' ) ) {
	$self->{duration}->add_duration( $dur );
    } else {
	Carp::croak( "Can not do arithmetic on $dur" );
    }
    return $self;
}

sub calendar_duration {
    my ( $self ) = @_;
    return $self->new(
	years	=> $self->delta_years(),
	months	=> $self->delta_months(),
	weeks	=> $self->delta_weeks(),
	days	=> $self->delta_days(),
	end_of_month	=> $self->end_of_month_mode(),
    );
}

sub clock_duration {
    my ( $self ) = @_;
    return $self->new(
	minutes	=> $self->delta_minutes(),
	seconds	=> $self->delta_seconds(),
	nanoseconds	=> $self->delta_nanoseconds(),
	end_of_month	=> $self->end_of_month_mode(),
    );
}

sub clone {
    my ( $self ) = @_;
    my %clone = %{ $self };
    $clone{duration} = $self->{duration}->clone();
    return bless \%clone, ref $self;
}

require DateTime::Fiction::JRRTolkien::Shire;

sub compare {
    my ( undef, $left, $right, $base ) = @_;

    $base ||= DateTime::Fiction::JRRTolkien::Shire->now();

    return DateTime::Fiction::JRRTolkien::Shire->compare(
	$base->clone()->add_duration( $left ),
	$base->clone()->add_duration( $right ),
    );
}

sub delta_weeks {
    my ( $self ) = @_;
    return $self->{weeks};
}

sub delta_years {
    my ( $self ) = @_;
    return $self->{years};
}

# sub delta_months; sub delta_days; sub delta_minutes;
# sub delta_seconds; sub delta_nanoseconds;
# sub end_of_month_mode; is_wrap_mode; is_limit_mode; is_preserve_mode;
# sub months; sub days; sub hours; sub minutes; sub seconds;
# sub nanoseconds;
foreach my $method ( qw{
    delta_months delta_days delta_minutes delta_seconds
    delta_nanoseconds
    end_of_month_mode is_wrap_mode is_limit_mode is_preserve_mode
    months days hours minutes seconds nanoseconds
} ) {
    no strict qw{ refs };
    *$method = sub { return $_[0]->{duration}->$method() };
}

sub is_forward_mode { return $_[0]->is_wrap_mode() ? 1 : 0 }

sub is_backward_mode { return $_[0]->is_wrap_mode() ? 0 : 1 }

sub holiday_mode { return ( qw{ backward forward } )[
	$_[0]->is_forward_mode() ] }

sub deltas {
    my ( $self ) = @_;
    return (
	$self->{duration}->deltas(),
	weeks	=> $self->{weeks},
	years	=> $self->{years},
    );
}

{
    my %on_side = map { $_ => 1 } qw{ years weeks };

    sub in_units {
	my ( $self, @units ) = @_;
	my @rslt = $self->{duration}->in_units( @units );
	foreach my $inx ( 0 .. $#units ) {
	    $on_side{$units[$inx]}
		and $rslt[$inx] = $self->{$units[$inx]};
	}
	return wantarray ? @rslt : $rslt[0];
    }
}

# Note that we always specify am end-of-month mode to the contained
# DateTime::Duration, because it does not have enough information to
# properly default, AND if an end-of-month mode was originally specified
# it is not preserved across the inversion.
sub inverse {
    my ( $self, %arg ) = @_;

    if ( $arg{holiday} ) {
	$arg{end_of_month} = _map_holiday_mode( delete $arg{holiday} );
    } elsif ( $arg{end_of_month} ) {
	# Do nothing
    } elsif ( $self->{mode_specified} ) {
	$arg{end_of_month} = $self->end_of_month_mode();
    } else {
	my %delta = $self->deltas();
	$arg{end_of_month} = _compute_default_mode( \%delta, 1 );
    }

    my %inverse = %{ $self };
    $inverse{weeks}
	and $inverse{weeks} *= -1;
    $inverse{years}
	and $inverse{years} *= -1;
    $inverse{duration} = $self->{duration}->inverse( %arg );
    return bless \%inverse, ref $self;
}

sub is_negative {
    my ( $self ) = @_;
    $self->{weeks} > 0
	and return 0;
    $self->{years} > 0
	and return 0;
    ( $self->{weeks} || $self->{years} )
	and return $self->{duration}->is_negative() ? 1 : 0;
    return $self->{duration}->is_negative();
}

sub is_positive {
    my ( $self ) = @_;
    $self->{weeks} < 0
	and return 0;
    $self->{years} < 0
	and return 0;
    ( $self->{weeks} || $self->{years} )
	and return $self->{duration}->is_positive() ? 1 : 0;
    return $self->{duration}->is_positive();
}

sub is_zero {
    my ( $self ) = @_;
    return ( $self->{duration}->is_zero() && 0 == $self->{weeks} &&
	$self->{years} == 0 ) ? 1 : 0;
}

sub multiply {
    my ( $self, $multiplier ) = @_;
    $self->{weeks} *= $multiplier;
    $self->{years} *= $multiplier;
    $self->{duration}->multiply( $multiplier );
    return $self;
}

sub subtract {
    my ( $self, @arg ) = @_;
    return $self->subtract_duration( _make_duration( @arg ) );
}

sub subtract_duration {
    my ( $self, $dur ) = @_;
    return $self->add_duration( $dur->inverse() );
}

sub weeks {
    my ( $self ) = @_;
    return abs $self->{weeks};
}

sub years {
    my ( $self ) = @_;
    return abs $self->{years};
}

sub _add_overload {
    my ( $left, $right, $reverse ) = @_;

    $reverse
	and ( $left, $right ) = ( $right, $left );

    _isa( $right, 'DateTime::Fiction::JRRTolkien::Shire' )
	and return $right->clone()->add_duration( $left );

    return $left->clone()->add_duration( $right );
}

sub _compare_overload {
    Carp::croak(
	'DateTime::Fiction::JRRTolkien::Shire::Duration does not overload comparison' );
}

# Compute the default mode. Arguments are a reference to the argument
# hash to compute from, and an optional invert flag. The basic
# computation is to return 'preserve' if $arg->{months} * 30 +
# $arg->{weeks} * 7 is negative, and 'wrap' otherwise. If the invert
# flag is true, the opposite is returned.
sub _compute_default_mode {
    my ( $arg, $invert ) = @_;
    my $inx = ( $arg->{years} * 365 + $arg->{months} * 30 +
	$arg->{weeks} * 7 ) >= 0 ? 1 : 0;
    $invert
	and $inx = 1 - $inx;
    return ( qw{ preserve wrap } )[$inx];
}

sub _isa {
    my ( $obj, $class ) = @_;
    return Scalar::Util::blessed( $obj ) && $obj->isa( $class );
}

sub _make_duration {
    my @arg = @_;
    if ( 1 == @arg && Scalar::Util::blessed( $arg[0] ) ) {
	$arg[0]->isa( __PACKAGE__ )
	    and return $arg[0];
	$arg[0]->isa( 'DateTime::Duration' )
	    and return __PACKAGE__->new( $arg[0]->deltas() );
    }
    return __PACKAGE__->new( @arg );
}

{
    my %mode = (
	forward		=> 'wrap',
	backward	=> 'preserve',
    );

    sub _map_holiday_mode {
	my ( $m ) = @_;
	my $rslt = $mode{$m}
	    or Carp::croak( "Invalid holiday mode '$m'");
	return $rslt;
    }
}

sub _multiply_overload {
    my ( $left, $right ) = @_;
    return $left->clone()->multiply( $right );
}

sub _subtract_overload {
    my ( $left, $right, $reverse ) = @_;

    $reverse
	and ( $left, $right ) = ( $right, $left );

    _isa( $right, 'DateTime::Fiction::JRRTolkien::Shire' )
	and Carp::croak(
	'Can not subtract a DateTime::Fiction::JRRTolkien::Shire from a DateTime::Fiction::JRRTolkien::Shire::Duration' );

    return $left->clone()->subtract_duration( $right );
}

1;

__END__

=head1 NAME

DateTime::Fiction::JRRTolkien::Shire::Duration - Duration objects for Shire calendar date math

=head1 SYNOPSIS

 use DateTime::Fiction::JRRTolkien::Shire;
 use DateTime::Fiction::JRRTolkien::Shire::Duration;
 
 my $dt  = DateTime::Fiction::JRRTolkien::Shire->new(
     year  => 1419,
     month => 3,
     day   => 25,
 );
 my $dur = DateTime::Fiction::JRRTolkien::Shire::Duration->new(
     years       => 1,
     months      => 2,
     weeks       => 3,
     days        => 4,
     hours       => 5,
     minutes     => 6,
     seconds     => 7,
     nanoseconds => 8,
     holiday     => 'forward',
 );
 print $dt->add( $dur )->iso8601(), "\n";

=head1 DESCRIPTION

This is a simple class for representing durations in the Shire calendar.
It is B<not> a subclass of L<DateTime::Duration|DateTime::Duration>,
though it implements the same interface, plus some extra bells and
whistles.  Objects of this class are used whenever you do date math with
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>.

Unlike L<DateTime::Duration|DateTime::Duration>, this class preserves
years and weeks rather than folding them into months and days
respectively. This is because the Shire calendar contains days that are
not part of any week or month. An example may clarify this.

You would expect adding a week to a Monday to produce the following
Monday. But adding seven days to 30 Forelithe (a Mersday) gives you 4
Afterlithe (a Hevensday) because the interval between these two dates
contains Midsummer's day, which is not part of any week. In a leap year
this would give 3 Afterlithe (a Trewsday) because the leap year day also
falls in this interval and is part of no week. The issues for months are
similar.

A related issue with this calendar is what happens when you try, for
example, to add a month to a date that is not part of any month. When
something like this happens, the date is first adjusted to a nearby date
that B<is> part of a month (or week). By default the adjustment is
forward for a positive delta and backward for a negative delta, though
you can specify the direction of adjustment when the object is
instantiated. So adding a month to 1 Lithe gives 1 Wedmath by default,
but 30 Afterlithe if the adjustment is backward.

=head1 METHODS

This class supports the following public methods over and above those
supplied by L<DateTime::Duration|DateTime::Duration>:

=head2 new

This static method takes the same arguments as the corresponding
L<DateTime::Duration|DateTime::Duration> method. As (maybe) a
convenience, it also takes a C<holiday> parameter in lieu of the
C<end_of_month> parameter.

The C<holiday> parameter must be either C<forward> or C<backward>, and
specifies how a date should be adjusted (if needed) before doing
arithmetic on it.

If you specify C<end_of_month> (a misnomer in this case since all Shire
months have 30 days), C<wrap> specifies a forward adjustment, and
anything else specifies a backward adjustment.

=head2 deltas

This method returns the deltas stored in the object. Possible keys are
C<years>, C<months>, C<weeks>, C<days>, C<minutes>, C<seconds>, and
C<nanoseconds>.

=head2 delta_weeks

This method returns the C<weeks> element of the object.

=head2 delta_years

This method returns the C<years> element of the object.

=head2 holiday_mode

This method returns one of the strings C<forward> or C<backward>,
representing how dates are to be adjusted (if necessary) before
performing arithmetic on them.

=head2 is_backward_mode

This method returns C<1> if dates are to be adjusted backward (if
necessary) before doing arithmetic on them, and C<0> otherwise.

=head2 is_forward_mode

This method returns C<1> if dates are to be adjusted forward (if
necessary) before doing arithmetic on them, and C<0> otherwise.

=head1 SEE ALSO

L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>

L<DateTime|DateTime>

L<DateTime::Duration|DateTime::Duration>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Fiction-JRRTolkien-Shire>,
L<https://github.com/trwyant/perl-DateTime-Fiction-JRRTolkien-Shire/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

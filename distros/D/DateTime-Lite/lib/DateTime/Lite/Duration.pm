##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - ~/lib/DateTime/Lite/Duration.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/03
## Modified 2026/04/10
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Lite::Duration;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'DateTime::Lite' );
    use vars qw( $VERSION $ERROR );
    use overload (
        '+'      => '_add_overload',
        '-'      => '_subtract_overload',
        '*'      => '_multiply_overload',
        '<=>'    => '_compare_overload',
        'cmp'    => '_compare_overload',
        'neg'    => 'inverse',
        bool     => sub{1},
        '""'     => \&_stringify,
        fallback => 1,
    );
    sub MAX_NANOSECONDS () { 1_000_000_000 }
    use Scalar::Util ();
    use Wanted;
    our $VERSION = 'v0.1.0';
};

# Keep in unit order from largest to smallest
my @UNITS = qw( months days minutes seconds nanoseconds );

# NOTE: Constructor
sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %p = @_;

    my $self = bless(
    {
        months      => 0,
        days        => 0,
        minutes     => 0,
        seconds     => 0,
        nanoseconds => 0,
        end_of_month => 'wrap',
    }, $class );

    foreach my $unit ( @UNITS )
    {
        $self->{ $unit } = $p{ $unit } // 0;
    }

    if( exists( $p{years} ) )
    {
        $self->{months} += $p{years} * 12;
    }
    if( exists( $p{weeks} ) )
    {
        $self->{days} += $p{weeks} * 7;
    }
    if( exists( $p{hours} ) )
    {
        $self->{minutes} += $p{hours} * 60;
    }

    if( exists( $p{end_of_month} ) )
    {
        unless( $p{end_of_month} =~ /^(?:wrap|limit|preserve)$/ )
        {
            return( $self->error( "Invalid end_of_month mode '$p{end_of_month}'. Must be 'wrap', 'limit', or 'preserve'." ) );
        }
        $self->{end_of_month} = $p{end_of_month};
    }

    $self->_normalise_nanoseconds;
    return( $self );
}

# NOTE: Accessors (absolute values, matching DateTime::Duration API)
sub nanoseconds { abs( ( $_[0]->in_units( 'nanoseconds', 'seconds' ) )[0] ) }
sub seconds     { abs( ( $_[0]->in_units( 'seconds', 'minutes' ) )[0] ) }
sub minutes     { abs( ( $_[0]->in_units( 'minutes', 'hours' ) )[0] ) }
sub hours       { abs( $_[0]->in_units( 'hours' ) ) }
sub days        { abs( ( $_[0]->in_units( 'days', 'weeks' ) )[0] ) }
sub weeks       { abs( $_[0]->in_units( 'weeks' ) ) }
sub months      { abs( ( $_[0]->in_units( 'months', 'years' ) )[0] ) }
sub years       { abs( $_[0]->in_units( 'years' ) ) }

# NOTE: Duration arithmetic
sub add
{
    my $self = shift( @_ );
    return( $self->add_duration( $self->_duration_from_args( @_ ) ) );
}

sub add_duration
{
    my $self = shift( @_ );
    my $dur  = shift( @_ );

    unless( Scalar::Util::blessed( $dur ) && $dur->isa( 'DateTime::Lite::Duration' ) )
    {
        return( $self->error( "Argument to add_duration() must be a DateTime::Lite::Duration object." ) );
    }

    foreach my $unit ( @UNITS )
    {
        $self->{ $unit } += $dur->{ $unit };
    }
    $self->_normalise_nanoseconds;
    return( $self );
}

sub calendar_duration
{
    my $self = shift( @_ );
    return( ref( $self )->new(
        months => $self->{months},
        days   => $self->{days},
        end_of_month => $self->{end_of_month},
    ) );
}

sub clock_duration
{
    my $self = shift( @_ );
    return( ref( $self )->new(
        minutes     => $self->{minutes},
        seconds     => $self->{seconds},
        nanoseconds => $self->{nanoseconds},
    ) );
}

sub clone { bless( { %{ $_[0] } }, ref( $_[0] ) ) }

# NOTE: Class method: comparison
sub compare
{
    my $class = ref( $_[0] ) ? undef : shift( @_ );
    my( $d1, $d2 ) = @_;

    foreach my $unit ( @UNITS )
    {
        my $cmp = $d1->{ $unit } <=> $d2->{ $unit };
        return( $cmp ) if( $cmp );
    }
    return(0)
}

# delta_* return the raw (signed) internal values

sub delta_days        { $_[0]->{days} }
sub delta_minutes     { $_[0]->{minutes} }
sub delta_months      { $_[0]->{months} }
sub delta_nanoseconds { $_[0]->{nanoseconds} }
sub delta_seconds     { $_[0]->{seconds} }

sub deltas
{
    my $self = shift( @_ );
    return( map { $_ => $self->{ $_ } } @UNITS );
}

sub end_of_month_mode { return( $_[0]->{end_of_month} ); }

# Error handling: same pattern as Locale::Unicode / Module::Generic
sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        require DateTime::Lite::Exception;
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        my $e = DateTime::Lite::Exception->new({
            skip_frames => 1,
            message     => $msg,
        });
        $ERROR = $e;
        $self->{error} = $e if( ref( $self ) );
        if( $self->fatal )
        {
            die( $self->{error} );
        }
        else
        {
            warn( $msg ) if( warnings::enabled() );
            rreturn( DateTime::Lite::NullObject->new ) if( want( 'OBJECT' ) );
            return;
        }
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub fatal { return( shift->_set_get_prop( 'fatal', @_ ) ); }

# NOTE: in_units / deltas
sub in_units
{
    my $self  = shift( @_ );
    my @units = @_;

    # Maps a "virtual" large unit to the stored base unit and its divisor:
    #   years  -> months  / 12
    #   weeks  -> days    / 7
    #   hours  -> minutes / 60
    my %large_unit = (
        years  => [ months  => 12 ],
        weeks  => [ days    => 7  ],
        hours  => [ minutes => 60 ],
    );

    # Working copy of the five stored buckets.
    my %remaining = map { $_ => $self->{ $_ } } @UNITS;
    my %result;

    # Large units (years/weeks/hours) must be processed before their
    # corresponding stored units (months/days/minutes), regardless of
    # the caller's ordering, otherwise the remainder calculation is wrong.
    my @ordered = (
        ( grep {  exists( $large_unit{ $_ } ) } @units ),
        ( grep { !exists( $large_unit{ $_ } ) } @units ),
    );

    foreach my $unit ( @ordered )
    {
        if( exists( $large_unit{ $unit } ) )
        {
            my( $base, $divisor ) = @{ $large_unit{ $unit } };
            use integer;
            $result{ $unit }     = $remaining{ $base } / $divisor;
            $remaining{ $base } -= $result{ $unit } * $divisor;
        }
        else
        {
            # Stored unit: return whatever remains in its bucket.
            $result{ $unit } = $remaining{ $unit } // 0;
        }
    }

    return( @units == 1 ? $result{ $units[0] } : @result{ @units } );
}

sub inverse
{
    my $self = shift( @_ );
    my %eom  = @_;

    my $new = ref( $self )->new(
        map { $_ => -1 * $self->{ $_ } } @UNITS
    );

    $new->{end_of_month} = $eom{end_of_month} // $self->{end_of_month};

    return( $new );
}

sub is_limit_mode    { $_[0]->{end_of_month} eq 'limit'    ? 1 : 0 }
sub is_negative      { !$_[0]->_has_positive && $_[0]->_has_negative }
sub is_positive      { $_[0]->_has_positive  && !$_[0]->_has_negative }
sub is_preserve_mode { $_[0]->{end_of_month} eq 'preserve' ? 1 : 0 }
sub is_wrap_mode     { $_[0]->{end_of_month} eq 'wrap'     ? 1 : 0 }

sub is_zero
{
    my $self = shift( @_ );
    foreach my $unit ( @UNITS )
    {
        return(0) if( $self->{ $unit } != 0 );
    }
    return(1)
}

sub pass_error
{
    my $self = shift( @_ );
    my $pack = ref( $self ) || $self;
    my $opts = {};
    my( $err, $class, $code );
    no strict 'refs';
    if( scalar( @_ ) )
    {
        # Either an hash defining a new error and this will be passed along to error(); or
        # an hash with a single property: { class => 'Some::ExceptionClass' }
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    $err = $opts->{error} if( !defined( $err ) && CORE::exists( $opts->{error} ) && defined( $opts->{error} ) && CORE::length( $opts->{error} ) );
    # We set $class only if the hash provided is a one-element hash and not an error-defining hash
    $class = $opts->{class} if( CORE::exists( $opts->{class} ) && defined( $opts->{class} ) && CORE::length( $opts->{class} ) );
    $code  = $opts->{code} if( CORE::exists( $opts->{code} ) && defined( $opts->{code} ) && CORE::length( $opts->{code} ) );

    # called with no argument, most likely from the same class to pass on an error 
    # set up earlier by another method; or
    # with an hash containing just one argument class => 'Some::ExceptionClass'
    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        # $error is a previous erro robject
        my $error = ref( $self ) ? $self->{error} : length( ${ $pack . '::ERROR' } ) ? ${ $pack . '::ERROR' } : undef;
        if( !defined( $error ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef" );
        }
        else
        {
            $err = ( defined( $class ) ? bless( $error => $class ) : $error );
            $err->code( $code ) if( defined( $code ) );
        }
    }
    elsif( defined( $err ) && 
           Scalar::Util::blessed( $err ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $class ) ) 
           ) )
    {
        $self->{error} = ${ $pack . '::ERROR' } = ( defined( $class ) ? bless( $err => $class ) : $err );
        $self->{error}->code( $code ) if( defined( $code ) && $self->{error}->can( 'code' ) );

        if( $self->{fatal} || ( defined( ${"${class}\::FATAL_EXCEPTIONS"} ) && ${"${class}\::FATAL_EXCEPTIONS"} ) )
        {
            die( $self->{error} );
        }
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }

    if( want( 'OBJECT' ) )
    {
        rreturn( DateTime::Lite::NullObject->new );
    }
    return;
}

sub subtract
{
    my $self = shift( @_ );
    return( $self->add_duration( $self->_duration_from_args( @_ )->inverse ) );
}

sub subtract_duration { return( $_[0]->add_duration( $_[1]->inverse ) ) }

# NOTE: Sign predicates
sub _has_negative
{
    my $self = shift( @_ );
    foreach my $unit ( @UNITS )
    {
        return(1) if( $self->{ $unit } < 0 );
    }
    return(0)
}

sub _has_positive
{
    my $self = shift( @_ );
    foreach my $unit ( @UNITS )
    {
        return(1) if( $self->{ $unit } > 0 );
    }
    return(0)
}

# NOTE: Overloaded operators
sub _add_overload
{
    my( $self, $other, $reversed ) = @_;
    ( $self, $other ) = ( $other, $self ) if( $reversed );
    return( $self->clone->add_duration( $other ) );
}

sub _compare_overload
{
    my( $d1, $d2, $flip ) = @_;
    my $result = DateTime::Lite::Duration->compare( $d1, $d2 );
    return( $flip ? -$result : $result );
}

# NOTE: Private helpers
sub _duration_from_args
{
    my $self = shift( @_ );
    return( $_[0] )
        if( @_ == 1 && Scalar::Util::blessed( $_[0] ) && $_[0]->isa( ref( $self ) ) );
    return( ref( $self )->new( @_ ) );
}

sub _multiply_overload
{
    my( $self, $factor ) = @_;
    my $new = $self->clone;
    foreach my $unit ( @UNITS )
    {
        $new->{ $unit } = int( $new->{ $unit } * $factor );
    }
    $new->_normalise_nanoseconds;
    return( $new );
}

sub _normalise_nanoseconds
{
    my $self = shift( @_ );
    my $ns   = $self->{nanoseconds};
    return if( $ns >= 0 && $ns < MAX_NANOSECONDS );

    use integer;
    if( $ns < 0 )
    {
        my $overflow = 1 + ( -$ns - 1 ) / MAX_NANOSECONDS;
        $self->{nanoseconds} += $overflow * MAX_NANOSECONDS;
        $self->{seconds}     -= $overflow;
    }
    elsif( $ns >= MAX_NANOSECONDS )
    {
        my $overflow = $ns / MAX_NANOSECONDS;
        $self->{nanoseconds} -= $overflow * MAX_NANOSECONDS;
        $self->{seconds}     += $overflow;
    }
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

sub _stringify
{
    my $self = shift( @_ );
    # P[n]Y[n]M[n]DT[n]H[n]M[n]S  ISO 8601 duration
    my $str = 'P';
    my( $y, $mo ) = $self->in_units( 'years', 'months' );
    my( $w,  $d ) = $self->in_units( 'weeks', 'days' );
    my( $h, $mi ) = $self->in_units( 'hours', 'minutes' );
    my $s  = $self->{seconds};
    $str .= "${y}Y"  if( $y );
    $str .= "${mo}M" if( $mo );
    $str .= "${w}W"  if( $w );
    $str .= "${d}D"  if( $d );
    if( $h || $mi || $s )
    {
        $str .= 'T';
        $str .= "${h}H"  if( $h );
        $str .= "${mi}M" if( $mi );
        $str .= "${s}S"  if( $s );
    }
    return( $str || 'P0D' );
}

sub _subtract_overload
{
    my( $d1, $d2, $flip ) = @_;
    ( $d1, $d2 ) = ( $d2, $d1 ) if( $flip );
    return( $d1->clone->subtract_duration( $d2 ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DateTime::Lite::Duration - Duration objects for use with DateTime::Lite

=head1 SYNOPSIS

    use DateTime::Lite::Duration;

    my $dur = DateTime::Lite::Duration->new(
        years   => 1,
        months  => 6,
        days    => 15,
        hours   => 3,
        minutes => 10,
        seconds => 30,
    ) || die( DateTime::Lite::Duration->error );

    my $dur = DateTime::Lite::Duration->new(
        years       => 1,
        months      => 6,
        weeks       => 2,
        days        => 15,
        hours       => 3,
        minutes     => 10,
        seconds     => 30,
        nanoseconds => 500_000_000,
        end_of_month => 'limit',  # 'wrap' (default), 'limit', 'preserve'
    ) || die( DateTime::Lite::Duration->error );

    # Introspection
    printf( "Years: %d, Months: %d\n", $dur->years, $dur->months );

    # Use with DateTime::Lite
    $dt->add_duration( $dur );
    $dt->subtract_duration( $dur );
    my $diff = $dt1->subtract_datetime( $dt2 );  # returns a Duration

    # Absolute-value accessors (strip larger units)
    $dur->years;         # full years
    $dur->months;        # months after stripping years
    $dur->weeks;         # full weeks
    $dur->days;          # days after stripping weeks
    $dur->hours;         # full hours
    $dur->minutes;       # minutes after stripping hours
    $dur->seconds;       # seconds after stripping minutes
    $dur->nanoseconds;   # nanoseconds after stripping seconds

    # Signed raw delta accessors
    $dur->delta_months;       # signed months (years * 12 + months)
    $dur->delta_days;         # signed days
    $dur->delta_minutes;      # signed minutes (hours * 60 + minutes)
    $dur->delta_seconds;      # signed seconds
    $dur->delta_nanoseconds;  # signed nanoseconds

    # All signed components at once
    my %d = $dur->deltas;  # keys: months days minutes seconds nanoseconds

    # Calendar / clock sub-durations
    my $cal   = $dur->calendar_duration;  # months + days only
    my $clock = $dur->clock_duration;     # minutes + seconds + nanoseconds only

    # Arithmetic on durations
    $dur->add( months => 1, days => 7 );
    $dur->subtract( hours => 2 );
    $dur->add_duration( $other_dur );
    $dur->subtract_duration( $other_dur );

    my $inverse = $dur->inverse;                          # negate all components
    my $neg     = $dur->inverse( end_of_month => 'wrap' );

    # Conversion
    # Express as a combination of requested units:
    my ( $h, $m ) = $dur->in_units( 'hours', 'minutes' );  # e.g. (3, 10)
    my $total_min = $dur->in_units('minutes');             # scalar form

    # Comparison
    my $cmp = DateTime::Lite::Duration->compare( $dur1, $dur2 );  # -1, 0, 1

    # Predicates
    $dur->is_positive;          # true if any component > 0, none < 0
    $dur->is_negative;          # true if any component < 0, none > 0
    $dur->is_zero;              # true if all components are 0
    $dur->is_wrap_mode;         # end_of_month eq 'wrap'
    $dur->is_limit_mode;        # end_of_month eq 'limit'
    $dur->is_preserve_mode;     # end_of_month eq 'preserve'
    $dur->end_of_month_mode;    # 'wrap', 'limit', or 'preserve'

    # Cloning
    my $copy = $dur->clone;

    # Constants
    DateTime::Lite::Duration::MAX_NANOSECONDS();  # 1_000_000_000

    # Error handling
    my $dur2 = DateTime::Lite::Duration->new( %bad_args ) ||
        die( DateTime::Lite::Duration->error );
    $dur->fatal(1);  # make all errors fatal (die instead of warn+return undef)
    my $err = $dur->error;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

C<DateTime::Lite::Duration> is a lightweight port of L<DateTime::Duration>, used exclusively with L<DateTime::Lite>. It stores durations in five independent "buckets": C<months>, C<days>, C<minutes>, C<seconds>, and C<nanoseconds>.

The month/day buckets are C<calendar> units, whose real length depends on the date to which the duration is applied. The minute/second/nanosecond buckets are absolute (C<clock>) units.

Unlike L<DateTime>, C<DateTime::Lite> never calls C<die()> unexpectedly.

Errors set an exception object accessible via C<< $dur->error >> and return C<undef> in scalar context, or an empty list in list context. In chaining (object context), it returns a dummy object (C<DateTime::Lite::Null>) to avoid the typical C<Can't call method '%s' on an undefined value>

=head1 CONSTRUCTOR

=head2 new( %args )

Accepted keys:

=over 4

=item C<years>, C<months>

Calendar time. C<years> is converted to months on construction (1 year = 12 months).

=item C<weeks>, C<days>

Calendar time. C<weeks> is converted to days (1 week = 7 days).

=item C<hours>, C<minutes>

Clock time. C<hours> is converted to minutes (1 hour = 60 minutes).

=item C<seconds>, C<nanoseconds>

Clock time.

=item C<end_of_month>

How to handle month-end arithmetic when adding/subtracting months. One of C<wrap> (default), C<limit>, or C<preserve>.

=back

=head1 METHODS

=head2 Accessors (absolute values)

C<years>, C<months>, C<weeks>, C<days>, C<hours>, C<minutes>, C<seconds>, C<nanoseconds> all return the absolute (unsigned) portion of the duration in the given unit, after stripping larger units. For instance C<months()> returns the months component after dividing out full years.

=head2 Signed delta accessors

C<delta_months>, C<delta_days>, C<delta_minutes>, C<delta_seconds>, C<delta_nanoseconds> return the raw signed internal values.

=head2 calendar_duration / clock_duration

Return new duration objects containing only the calendar (months, days) or clock (minutes, seconds, nanoseconds) components respectively.

=head2 clone

Returns a shallow copy.

=head2 compare( $dur1, $dur2 )

Class method. Compares two durations unit by unit. Returns -1, 0, or 1.

=head2 deltas

Returns a hash of all five raw signed values.

=head2 end_of_month_mode

Returns C<wrap>, C<limit>, or C<preserve>.

=head2 in_units( @units )

Returns the duration expressed as a combination of the given units.

For example: C<< $dur->in_units( 'hours', 'minutes' ) >> returns C<(3, 10)> for a 190-minute duration. If only one unit is requested, returns a scalar.

=head2 inverse

    $dur->inverse;
    $dur->inverse( end_of_month => $mode );

Returns a new duration with all components negated. Optionally overrides C<end_of_month>.

=head2 is_negative / is_positive / is_zero

Predicate methods.

=head2 is_wrap_mode / is_limit_mode / is_preserve_mode

Return true if the C<end_of_month> mode matches.

=head2 add

    $dur->add( months => 1, days => 15 );

Adds a duration specified as key-value pairs (same keys as L</new>) to this duration in-place. Returns C<$self>.

=head2 add_duration

    $dur->add_duration( $other_dur );

Adds another L<DateTime::Lite::Duration> object to this duration in-place. Returns C<$self>.

=head2 subtract

    $dur->subtract( days => 1 );

Subtracts a duration specified as key-value pairs from this duration in-place. Equivalent to adding the inverse. Returns C<$self>.

=head2 subtract_duration

    $dur->subtract_duration( $other_dur );

Subtracts another L<DateTime::Lite::Duration> object from this duration in-place. Returns C<$self>.

=head2 delta_months

    my $m = $dur->delta_months;  # may be negative

Returns the raw signed months component.

=head2 delta_days

    my $d = $dur->delta_days;

Returns the raw signed days component.

=head2 delta_minutes

    my $min = $dur->delta_minutes;

Returns the raw signed minutes component.

=head2 delta_seconds

    my $s = $dur->delta_seconds;

Returns the raw signed seconds component.

=head2 delta_nanoseconds

    my $ns = $dur->delta_nanoseconds;

Returns the raw signed nanoseconds component.

=head2 MAX_NANOSECONDS

    my $max = DateTime::Lite::Duration::MAX_NANOSECONDS();

Returns C<1_000_000_000> (10^9), the number of nanoseconds in one second. Used internally for nanosecond normalisation.

=head2 error

    my $dur = DateTime::Lite::Duration->new( %bad_args ) ||
        die( DateTime::Lite::Duration->error );

Instance and class method. When called with a message, creates a L<DateTime::Lite::Exception>, stores it, warns or C<die>s (depending on L</fatal>), and returns C<undef>. When called without arguments, returns the last error object.

=head2 fatal

    $dur->fatal(1);  # enable fatal mode

Gets or sets the C<fatal> flag. When true, any call to L</error> will C<die> instead of warn-and-return-undef.

=head2 pass_error

    sub my_op
    {
        my $self = shift( @_ );
        my $res = $self->_inner_op ||
            return( $self->pass_error );
        return( $res );
    }

Propagates the error from a lower-level call into this object's error slot without constructing a new exception. Used internally and in subclasses.

=head1 ERROR HANDLING

On error, methods return C<undef>

=head2 add

    $dur->add( months => 1, days => 15 );

Adds a duration specified as key-value pairs (same keys as L</new>) to this duration in-place. Returns C<$self>.

=head2 add_duration

    $dur->add_duration( $other_dur );

Adds another L<DateTime::Lite::Duration> object to this duration in-place. Returns C<$self>.

=head2 subtract

    $dur->subtract( days => 1 );

Subtracts a duration specified as key-value pairs from this duration in-place. Equivalent to adding the inverse. Returns C<$self>.

=head2 subtract_duration

    $dur->subtract_duration( $other_dur );

Subtracts another L<DateTime::Lite::Duration> object from this duration in-place. Returns C<$self>.

=head2 delta_months

    my $m = $dur->delta_months;  # may be negative

Returns the raw signed months component.

=head2 delta_days

    my $d = $dur->delta_days;

Returns the raw signed days component.

=head2 delta_minutes

    my $min = $dur->delta_minutes;

Returns the raw signed minutes component.

=head2 delta_seconds

    my $s = $dur->delta_seconds;

Returns the raw signed seconds component.

=head2 delta_nanoseconds

    my $ns = $dur->delta_nanoseconds;

Returns the raw signed nanoseconds component.

=head2 error

    my $dur = DateTime::Lite::Duration->new( %bad_args ) ||
        die( DateTime::Lite::Duration->error );

Instance and class method. When called with a message, creates a L<DateTime::Lite::Exception>, stores it, warns or C<die>s (depending on L</fatal>), and returns C<undef>. When called without arguments, returns the last error object.

=head2 fatal

    $dur->fatal(1);  # enable fatal mode

Gets or sets the C<fatal> flag. When true, any call to L</error> will C<die> instead of warn-and-return-undef.

=head2 pass_error

    sub my_op
    {
        my $self = shift( @_ );
        my $res = $self->_inner_op ||
            return( $self->pass_error );
        return( $res );
    }

Propagates the error from a lower-level call into this object's error slot without constructing a new exception. Used internally and in subclasses.

=head1 ERROR HANDLING

On error, methods return C<undef> in scalar context, or an empty list in list context. The exception is accessible via C<< $obj->error >> or C<< DateTime::Lite::Duration->error >>.

The exception object stringifies to a human-readable message including file and line number.

C<error> detects the context is chaining, or object, and thus instead of returning C<undef>, it will return a dummy instance of C<DateTime::Lite::Null> to avoid the typical perl error C<Can't call method '%s' on an undefined value>.

If the instance option L<fatal|/fatal> has been enabled, then any error triggered will be fatal.

=head1 SEE ALSO

L<DateTime::Lite>, L<DateTime::Lite::Exception>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

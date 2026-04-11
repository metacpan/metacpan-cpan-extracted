##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - ~/lib/DateTime/Lite/Infinite.pm
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
# Provides DateTime::Lite::Infinite (base), DateTime::Lite::Infinite::Future,
# and DateTime::Lite::Infinite::Past.
#
# These objects are singletons. All "get" accessors return the system's
# representation of positive or negative infinity. The mutating methods
# set(), set_time_zone(), and truncate() are no-ops that return $self.
#
# NOTE: This file intentionally defines multiple packages.
##----------------------------------------------------------------------------
package DateTime::Lite::Infinite;
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
    use parent qw( DateTime::Lite );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

# Mutating methods are no-ops on infinite objects
foreach my $m ( qw( set set_time_zone truncate ) )
{
    no strict 'refs';
    *{ 'DateTime::Lite::Infinite::' . $m } = sub{ return( $_[0] ) };
}

sub is_finite   { 0 }
sub is_infinite { 1 }

# Override the XS/PP calendar decomposition to just propagate the
# infinity value through without any arithmetic
sub _rd2ymd
{
    return( $_[2] ? ( $_[1] ) x 7 : ( $_[1] ) x 3 );
}

sub _seconds_as_components
{
    return( ( $_[1] ) x 3 );
}

# NOTE: Formatting - all return the infinity string
sub datetime    { return( $_[0]->_infinity_string ) }
sub dmy         { return( $_[0]->iso8601 ) }
sub hms         { return( $_[0]->iso8601 ) }
sub hour_12     { return( $_[0]->_infinity_string ) }
sub hour_12_0   { return( $_[0]->_infinity_string ) }
sub mdy         { return( $_[0]->iso8601 ) }
sub stringify   { return( $_[0]->_infinity_string ) }
sub ymd         { return( $_[0]->iso8601 ) }

sub _infinity_string
{
    return( $_[0]->{utc_rd_days} == DateTime::Lite::INFINITY()
        ? DateTime::Lite::INFINITY() . q{}
        : DateTime::Lite::NEG_INFINITY() . q{} );
}

sub _week_values { return( [ $_[0]->{utc_rd_days}, $_[0]->{utc_rd_days} ] ) }

# Infinite objects are not serialisable in a meaningful way
sub STORABLE_freeze { return }
sub STORABLE_thaw   { return }

1;

# NOTE: DateTime::Lite::Infinite::Future class
package DateTime::Lite::Infinite::Future;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DateTime::Lite::Infinite );
};


{
    my $Pos;

    sub new
    {
        return( $Pos ) if( defined( $Pos ) );

        require DateTime::Lite::TimeZone;
        $Pos = bless(
        {
            utc_rd_days   => DateTime::Lite::INFINITY(),
            utc_rd_secs   => DateTime::Lite::INFINITY(),
            local_rd_days => DateTime::Lite::INFINITY(),
            local_rd_secs => DateTime::Lite::INFINITY(),
            rd_nanosecs   => DateTime::Lite::INFINITY(),
            offset_modifier => 0,
            tz            => DateTime::Lite::TimeZone->new( name => 'floating' ),
            locale        => DateTime::Lite::_FakeLocale->instance,
        },
        __PACKAGE__ );

        # _calc_utc_rd and _calc_local_rd are no-ops for infinities because
        # _normalize_tai_seconds short-circuits on non-finite values (XS
        # checks dtl_isfinite; PP version checks the range and does nothing
        # for infinities). However we still call them so the local_c hash
        # is populated in a consistent way.
        eval { $Pos->_calc_utc_rd };
        eval { $Pos->_calc_local_rd };

        return( $Pos );
    }
}

1;

# NOTE: DateTime::Lite::Infinite::Past class
package DateTime::Lite::Infinite::Past;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DateTime::Lite::Infinite );
};

{
    my $Neg;

    sub new
    {
        return( $Neg ) if( defined( $Neg ) );

        require DateTime::Lite::TimeZone;
        $Neg = bless(
        {
            utc_rd_days     => DateTime::Lite::NEG_INFINITY(),
            utc_rd_secs     => DateTime::Lite::NEG_INFINITY(),
            local_rd_days   => DateTime::Lite::NEG_INFINITY(),
            local_rd_secs   => DateTime::Lite::NEG_INFINITY(),
            rd_nanosecs     => DateTime::Lite::NEG_INFINITY(),
            offset_modifier => 0,
            tz              => DateTime::Lite::TimeZone->new( name => 'floating' ),
            locale          => DateTime::Lite::_FakeLocale->instance,
        },
        __PACKAGE__ );

        eval { $Neg->_calc_utc_rd };
        eval { $Neg->_calc_local_rd };

        return( $Neg );
    }
}

1;

# A minimal locale stub used only by Infinite objects.
# It proxies format-related calls to a real en-US locale object (via
# DateTime::Locale::FromCLDR), and returns sensible no-op values for everything else
# that DateTime::Lite might call.

# NOTE: DateTime::Lite::_FakeLocale class
package DateTime::Lite::_FakeLocale;
BEGIN
{
    use strict;
    use warnings;
};

my $Instance;

sub instance
{
    return( $Instance ) if( defined( $Instance ) );

    require DateTime::Locale::FromCLDR;
    $Instance = bless(
    {
        _real => DateTime::Locale::FromCLDR->new( 'en-US' ),
    },
    __PACKAGE__ );
    return( $Instance );
}

sub id           { return( 'infinite' ) }
sub language_id  { return( 'infinite' ) }
sub name         { return( 'Fake locale for Infinite DateTime::Lite objects' ) }
sub language     { return( 'Fake locale for Infinite DateTime::Lite objects' ) }

# These return undef - they are present so DateTime::Lite's format_cldr and
# strftime do not die on missing methods.
foreach my $m ( qw(
    script_id territory_id variant_id
    script territory variant
    native_name native_language native_script native_territory native_variant
) )
{
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $m } = sub{ return( undef ) };
}

sub first_day_of_week    { return(1) }
sub prefers_24_hour_time { return(0) }

# Proxy format-related calls (day/month/quarter names, era strings, etc.)
# to the real locale object. Everything else that returns a list, such as
# month_format_wide, day_format_wide, returns an empty arrayref.
our $AUTOLOAD;

sub AUTOLOAD
{
    my $self = shift( @_ );
    my( $meth ) = $AUTOLOAD =~ /::(\w+)$/;
    return if( $meth eq 'DESTROY' );

    # Proxy date/time formatting methods to the real locale
    if( $meth =~ /format|era|am_pm|period/i
        && $meth !~ /^(?:day|month|quarter)_(?:format|stand)/ )
    {
        return( $self->{_real}->$meth( @_ ) );
    }

    # All array-returning methods (month names, day names, etc.) return []
    return( [] );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DateTime::Lite::Infinite - Infinite past and future DateTime::Lite objects

=head1 SYNOPSIS

    use DateTime::Lite::Infinite;

    my $future = DateTime::Lite::Infinite::Future->new;
    my $past   = DateTime::Lite::Infinite::Past->new;

    # Predicates
    $future->is_infinite;   # 1
    $future->is_finite;     # 0
    $past->is_infinite;     # 1
    $past->is_finite;       # 0

    # String representation
    # All accessor methods return the platform's infinity string, such as "Inf" /
    # "-Inf". Stringification is also available directly:
    print $future->stringify;  # "Inf"
    print "$past";             # "-Inf"

    # hour_12 and hour_12_0 also return the infinity string:
    $future->hour_12;    # "Inf"
    $future->hour_12_0;  # "Inf"

    # Comparison
    use DateTime::Lite;
    my $dt = DateTime::Lite->now( time_zone => 'UTC' );

    DateTime::Lite->compare( $dt, $future );   # -1  ($dt is earlier)
    DateTime::Lite->compare( $dt, $past   );   #  1  ($dt is later)
    DateTime::Lite->compare( $future, $past ); #  1

    # Overloaded operators work too:
    print "before end of time" if( $dt < $future );
    print "after beginning"    if( $dt > $past );

    # Arithmetic that yields infinite datetimes
    use DateTime::Lite;
    my $dt2 = DateTime::Lite->now( time_zone => 'UTC' );
    my $inf_dur = DateTime::Lite::Duration->new(
        seconds => DateTime::Lite::INFINITY(),
    );
    $dt2->add_duration( $inf_dur );
    # $dt2 is now a DateTime::Lite::Infinite::Future object

    # Mutators are no-ops
    # set(), set_time_zone(), and truncate() return the object unchanged.
    $future->set_time_zone('America/New_York');  # no-op
    $future->truncate( to => 'day' );            # no-op

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

C<DateTime::Lite::Infinite> provides two singleton subclasses of L<DateTime::Lite>:

=over 4

=item C<DateTime::Lite::Infinite::Future>

Represents a point infinitely far in the future.

=item C<DateTime::Lite::Infinite::Past>

Represents a point infinitely far in the past.

=back

Both objects are always in the floating timezone, which cannot be changed.

All accessor methods return the system's string representation of positive or negative infinity (such as C<Inf> / C<-Inf>). The mutating methods C<set()>, C<set_time_zone()>, and C<truncate()> are no-ops that simply return the object.

These objects are not serialisable via L<Storable>.

=head1 METHODS

=head2 hour_12

    my $h = $dt_inf->hour_12;  # 'Inf' or '-Inf'

Returns the infinity string (C<Inf> or C<-Inf> depending on the system) as the 12-hour clock representation. Infinite datetimes have no meaningful clock value.

=head2 hour_12_0

    my $h = $dt_inf->hour_12_0;

Identical to L</hour_12>. Returns the infinity string for the 0-based 12-hour clock slot.

=head2 stringify

    my $str = "$dt_inf";  # 'DateTime::Lite::Infinite::Future' prints 'Inf'

Returns the infinity string representation of the object. This is also called by the C<""> overloading operator.

=head1 SEE ALSO

L<DateTime::Lite>, L<DateTime::Lite::Duration>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

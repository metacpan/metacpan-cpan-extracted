##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - ~/lib/DateTime/Lite/PP.pm
## Version v0.1.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/03
## Modified 2026/05/03
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# Pure-Perl fallback implementations for all functions that are otherwise
# provided by the DateTime::Lite XS layer. Loaded automatically by
# DateTime::Lite when XSLoader fails, such as during development or on platforms
# without a C compiler.
#
# Each sub is injected directly into the DateTime::Lite namespace at the end
# of this file, so callers see them as methods on the main class.
##----------------------------------------------------------------------------
package DateTime::Lite::PP;
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
    our $VERSION = 'v0.1.1';
};

{
    no warnings 'once';
    $DateTime::Lite::IsPurePerl //= 1;
}

my @MonthLengths = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

my @LeapYearMonthLengths = @MonthLengths;
$LeapYearMonthLengths[1]++;

my( @EndOfLastMonthDOY, @EndOfLastMonthDOLY );
{
    my( $x, $xl ) = ( 0, 0 );
    for my $i ( 0 .. 11 )
    {
        push( @EndOfLastMonthDOY,  $x );
        push( @EndOfLastMonthDOLY, $xl );
        $x  += $MonthLengths[$i];
        $xl += $LeapYearMonthLengths[$i];
    }
}

# NOTE: Leap second data - mirrors leap_seconds.h (same source as the XS path).
# This makes PP.pm fully self-contained without requiring DateTime::LeapSecond.
my %_EXTRA_SECONDS = (
    720075 => +1,  720259 => +1,  720624 => +1,  720989 => +1,
    721354 => +1,  721720 => +1,  722085 => +1,  722450 => +1,
    722815 => +1,  723362 => +1,  723727 => +1,  724092 => +1,
    724823 => +1,  725737 => +1,  726468 => +1,  726833 => +1,
    727380 => +1,  727745 => +1,  728110 => +1,  728659 => +1,
    729206 => +1,  729755 => +1,  732312 => +1,  733408 => +1,
    734685 => +1,  735780 => +1,  736330 => +1,
);

# NOTE: _accumulated_leap_seconds
sub _accumulated_leap_seconds
{
    shift( @_ );    # class/self
    return( _leap_seconds_for( $_[0] ) );
}

# NOTE: _compare_rd( self, d1, s1, ns1, d2, s2, ns2 )
sub _compare_rd
{
    my( undef, $d1, $s1, $ns1, $d2, $s2, $ns2 ) = @_;
    return( $d1 != $d2  ? ( $d1  <=> $d2  )
          : $s1 != $s2  ? ( $s1  <=> $s2  )
          : $ns1 != $ns2 ? ( $ns1 <=> $ns2 )
          : 0 );
}

# NOTE: _day_length
sub _day_length
{
    shift( @_ );
    return( _day_length_for( $_[0] ) );
}

sub _day_length_for
{
    my $utc_rd = $_[0];
    return( 86400 + ( $_EXTRA_SECONDS{ $utc_rd } // 0 ) );
}

# NOTE: _day_has_leap_second
sub _day_has_leap_second
{
    my( undef, $utc_rd ) = @_;
    return( exists( $_EXTRA_SECONDS{ $utc_rd } ) ? 1 : 0 );
}

# NOTE: _epoch_to_rd( self, epoch )
sub _epoch_to_rd
{
    my( undef, $epoch ) = @_;
    use integer;
    my $d = $epoch / 86400;
    my $s = $epoch - $d * 86400;
    if( $s < 0 )
    {
        $d--;
        $s += 86400;
    }
    $d += 719163;   # UNIX_EPOCH_RD_DAYS
    return( $d, $s );
}

# NOTE: _is_leap_year
sub _is_leap_year
{
    my( undef, $y ) = @_;
    # Guard against infinities
    return(0) if( $y == DateTime::Lite::INFINITY() ||
                  $y == DateTime::Lite::NEG_INFINITY() );
    return(0) if( $y % 4 );
    return(1) if( $y % 100 );
    return(0) if( $y % 400 );
    return(1);
}

sub _leap_seconds_for
{
    my $utc_rd = $_[0];
    return(
        $utc_rd >= 736330 ? 27 :
        $utc_rd >= 735780 ? 26 :
        $utc_rd >= 734685 ? 25 :
        $utc_rd >= 733408 ? 24 :
        $utc_rd >= 732312 ? 23 :
        $utc_rd >= 729755 ? 22 :
        $utc_rd >= 729206 ? 21 :
        $utc_rd >= 728659 ? 20 :
        $utc_rd >= 728110 ? 19 :
        $utc_rd >= 727745 ? 18 :
        $utc_rd >= 727380 ? 17 :
        $utc_rd >= 726833 ? 16 :
        $utc_rd >= 726468 ? 15 :
        $utc_rd >= 725737 ? 14 :
        $utc_rd >= 724823 ? 13 :
        $utc_rd >= 724092 ? 12 :
        $utc_rd >= 723727 ? 11 :
        $utc_rd >= 723362 ? 10 :
        $utc_rd >= 722815 ?  9 :
        $utc_rd >= 722450 ?  8 :
        $utc_rd >= 722085 ?  7 :
        $utc_rd >= 721720 ?  6 :
        $utc_rd >= 721354 ?  5 :
        $utc_rd >= 720989 ?  4 :
        $utc_rd >= 720624 ?  3 :
        $utc_rd >= 720259 ?  2 :
        $utc_rd >= 720075 ?  1 :
        0
    );
}

# _normalize_nanoseconds( self, \$secs, \$nanosecs )
#
# Note: the XS version modifies SVs in-place. Here we operate on the actual scalars
# held in the object hash and accept them as lvalue aliases via @_ aliasing.
sub _normalize_nanoseconds
{
    # $_[1] = secs (aliased), $_[2] = nanosecs (aliased)
    # Do NOT shift self - operate via @_ aliases
    my $ns = $_[2];
    return if( $ns >= 0 && $ns < 1_000_000_000 );

    use integer;
    if( $ns < 0 )
    {
        my $overflow = 1 + ( -$ns - 1 ) / 1_000_000_000;
        $_[2] += $overflow * 1_000_000_000;
        $_[1] -= $overflow;
    }
    elsif( $ns >= 1_000_000_000 )
    {
        my $overflow = $ns / 1_000_000_000;
        $_[2] -= $overflow * 1_000_000_000;
        $_[1] += $overflow;
    }
}

# NOTE: _normalize_leap_seconds( self, \$days, \$secs )
sub _normalize_leap_seconds
{
    # $_[1] = days (aliased), $_[2] = secs (aliased)
    # Short-circuit for non-finite values (Inf/-Inf from Infinite objects)
    return unless( defined( $_[2] ) && ( $_[2] - $_[2] ) == 0 );
    while( $_[2] < 0 )
    {
        my $dl = _day_length_for( $_[1] - 1 );
        $_[2] += $dl;
        $_[1]--;
    }

    my $dl = _day_length_for( $_[1] );
    while( $_[2] > $dl - 1 )
    {
        $_[2] -= $dl;
        $_[1]++;
        $dl = _day_length_for( $_[1] );
    }
}

# NOTE: _normalize_tai_seconds( self, \$days, \$secs )
sub _normalize_tai_seconds
{
    # $_[1] = days (aliased), $_[2] = secs (aliased)
    # Short-circuit for non-finite values (Inf/-Inf from Infinite objects)
    return unless( defined( $_[2] ) && ( $_[2] - $_[2] ) == 0 );
    return if( $_[2] >= 0 && $_[2] < 86400 );

    use integer;
    if( $_[2] < 0 )
    {
        my $adj = ( $_[2] - 86399 ) / 86400;
        $_[1] += $adj;
        $_[2] -= $adj * 86400;
    }
    else
    {
        my $adj = $_[2] / 86400;
        $_[1] += $adj;
        $_[2] -= $adj * 86400;
    }
}

# NOTE: _rd2ymd( self, $rd_days [, $extra] )
sub _rd2ymd
{
    my $class = shift( @_ );
    use integer;

    my $d  = shift( @_ );
    my $rd = $d;

    my $yadj = 0;
    my( $c, $y, $m );

    if( ( $d += 306 ) <= 0 )
    {
        $yadj = -( -$d / 146097 + 1 );
        $d   -= $yadj * 146097;
    }

    $c  = ( $d * 4 - 1 ) / 146097;
    $d -= $c * 146097 / 4;
    $y  = ( $d * 4 - 1 ) / 1461;
    $d -= $y * 1461 / 4;
    $m  = ( $d * 12 + 1093 ) / 367;
    $d -= ( $m * 367 - 1094 ) / 12;
    $y += $c * 100 + $yadj * 400;

    if( $m > 12 )
    {
        ++$y;
        $m -= 12;
    }

    if( $_[0] )
    {
        my $dow;
        if( $rd < -6 )
        {
            $dow = ( $rd + 6 ) % 7;
            $dow += $dow ? 8 : 1;
        }
        else
        {
            $dow = ( ( $rd + 6 ) % 7 ) + 1;
        }

        my $is_leap = _is_leap_year( undef, $y );
        my $doy     = ( $is_leap ? $EndOfLastMonthDOLY[$m - 1] : $EndOfLastMonthDOY[$m - 1] ) + $d;

        my $quarter;
        {
            no integer;
            $quarter = int( ( 1 / 3.1 ) * $m ) + 1;
        }

        my $qm  = ( 3 * $quarter ) - 2;
        my $doq = $doy - ( $is_leap ? $EndOfLastMonthDOLY[$qm - 1] : $EndOfLastMonthDOY[$qm - 1] );

        return( $y, $m, $d, $dow, $doy, $quarter, $doq );
    }

    return( $y, $m, $d );
}

# NOTE: _rd_to_epoch( self, $rd_days, $rd_secs )
sub _rd_to_epoch
{
    my( undef, $rd_days, $rd_secs ) = @_;
    return( ( $rd_days - 719163 ) * 86400 + $rd_secs );
}

# NOTE: _seconds_as_components( self, $secs [, $utc_secs [, $modifier]] )
sub _seconds_as_components
{
    shift( @_ );
    my $secs     = shift( @_ );
    my $utc_secs = shift( @_ ) // 0;
    my $modifier = shift( @_ ) // 0;

    use integer;

    $secs -= $modifier;

    my $hour   = $secs / 3600;
    $secs     -= $hour * 3600;
    my $minute = $secs / 60;
    my $second = $secs - ( $minute * 60 );

    if( $utc_secs && $utc_secs >= 86400 )
    {
        die( "Invalid UTC RD seconds value: $utc_secs" ) if( $utc_secs > 86401 );
        $second += $utc_secs - 86400 + 60;
        $minute  = 59;
        $hour--;
        $hour = 23 if( $hour < 0 );
    }

    return( $hour, $minute, $second );
}

# NOTE: _time_as_seconds( self, $h, $m, $s )
sub _time_as_seconds
{
    shift( @_ );
    my( $h, $m, $s ) = @_;
    $h //= 0;
    $m //= 0;
    $s //= 0;
    return( $h * 3600 + $m * 60 + $s );
}

# NOTE: _ymd2rd( self, $y, $m, $d )
sub _ymd2rd
{
    shift( @_ );
    use integer;
    my( $y, $m, $d ) = @_;
    my $adj;

    if( $m <= 2 )
    {
        $y -= ( $adj = ( 14 - $m ) / 12 );
        $m += 12 * $adj;
    }
    elsif( $m > 14 )
    {
        $y += ( $adj = ( $m - 3 ) / 12 );
        $m -= 12 * $adj;
    }

    if( $y < 0 )
    {
        $d -= 146097 * ( $adj = ( 399 - $y ) / 400 );
        $y += 400 * $adj;
    }

    $d  += ( $m * 367 - 1094 ) / 12
         + $y % 100 * 1461 / 4
         + ( $y / 100 * 36524 + $y / 400 )
         - 306;
    return( $d );
}

# NOTE: Inject all subs into DateTime::Lite's namespace
my @subs = qw(
    _accumulated_leap_seconds
    _compare_rd
    _day_has_leap_second
    _day_length
    _epoch_to_rd
    _is_leap_year
    _normalize_leap_seconds
    _normalize_nanoseconds
    _normalize_tai_seconds
    _rd2ymd
    _rd_to_epoch
    _seconds_as_components
    _time_as_seconds
    _ymd2rd
);

foreach my $sub ( @subs )
{
    no strict 'refs';
    my $target = 'DateTime::Lite::' . $sub;
    # Install the PP fallback if either:
    # - We are running in pure-Perl mode ($IsPurePerl = 1). This guarantees the
    #   fallback is in place even if XS loading partially populated the DateTime::Lite::
    #   namespace with empty XSUB stubs before failing (observed on MSWin32 with
    #   Strawberry Perl 5.14 to 5.20).
    # - The XS version has not populated the glob (normal path).
    if( $DateTime::Lite::IsPurePerl || !defined( &{ $target } ) )
    {
        *{ $target } = __PACKAGE__->can( $sub );
    }
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DateTime::Lite::PP - Pure-Perl fallback for the DateTime::Lite XS layer

=head1 DESCRIPTION

This module is loaded automatically by L<DateTime::Lite> when the XS shared object cannot be loaded, such as when the distribution was installed without a C compiler, or when the environment variable C<PERL_DATETIME_LITE_PP> is set to a true value.

All functions defined here are injected directly into the C<DateTime::Lite> namespace so that callers see them transparently as methods.

You should not normally load or call this module directly.

=head1 VERSION

    v0.1.1

=head1 SEE ALSO

L<DateTime::Lite>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# -*- perl -*-
##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/DateTime.pm
## Version v0.1.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/05/30
## Modified 2023/10/21
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::DateTime;
BEGIN
{
	use strict;
    use warnings;
	use parent qw( Module::Generic );
	use vars qw( $VERSION );
	use APR::Date;
	use DateTime;
	use Devel::Confess;
	our $VERSION = 'v0.1.1';
};

use strict;
use warnings;

sub format_datetime
{
    my( $self, $dt ) = @_;
    $dt = DateTime->now unless( defined( $dt ) );
    $dt = $dt->clone->set_time_zone( 'GMT' );
    return( $dt->strftime( '%a, %d %b %Y %H:%M:%S GMT' ) );
}

# Using APR::Date::parse_http instead?
# <https://perl.apache.org/docs/2.0/api/APR/Date.html#toc_C_parse_http_>
sub parse_date
{
	my $self = shift( @_ );
    my $date = shift( @_ ) || return( $self->error( "No date to parse was provided." ) );
    
    my $dt = $self->parse_datetime( $date ) || return( $self->pass_error );
    
    if( wantarray() )
    {
        my $yr = $dt->year;
        my $mon = $dt->month;
        my $day = $dt->day;
        my $hr = $dt->hour;
        my $min = $dt->minute;
        my $sec = $dt->second;
        my $tz = $dt->time_zone;
        return( $yr, $mon, $day, $hr, $min, $sec, $tz );
    }
    return( $dt->iso8601 );
}

sub parse_datetime
{
	my $self = shift( @_ );
    my $date = shift( @_ ) || return( $self->error( "No date to parse was provided." ) );
    
    # More lax parsing below
    # kill leading space
    $date =~ s/^[[:blank:]]+|[[:blank:]]+$//gs;
    my $time = APR::Date::parse_rfc( $date );
    # We use APR::Date::parse_rfc rather than APR::Date::parse_http, because it is more lenient
    # APR::Date::parse_rfc returns 0 upon failure
    my $dt;
    if( !$time )
    {
        $dt = $self->_parse_timestamp( $date );
        return( $self->pass_error ) if( !defined( $dt ) );
        return( $dt );
    }
    else
    {
        # try-catch
        local $@;
        eval
        {
            $dt = DateTime->from_epoch( epoch => $time );
        };
        if( $@ )
        {
            return( $self->error( "Error instantiating a DateTime object with the epoch value equivalent of the date provided $date: $@" ) );
        }
        return( $dt );
    }
}

sub str2datetime { return( shift->parse_datetime( @_ ) ); }

sub str2time
{
	my $self = shift( @_ );
	my $dt = $self->str2datetime( @_ );
	return if( !defined( $dt ) );
	return( $dt->epoch );
}

sub time2datetime
{
	my $self = shift( @_ );
    my $time = shift( @_ );
    $time = time() unless( defined( $time ) );
    my $dt = DateTime->from_epoch( epoch => $time );
	$dt->set_formatter( $self );
	return( $dt );
}

sub time2str
{
	my $self = shift( @_ );
	my $dt = $self->time2datetime( @_ );
	$dt->set_formatter( $self );
	my $str = "$dt";
	return( $str );
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Apache2::API::DateTime - HTTP DateTime Manipulation and Formatting

=head1 SYNOPSIS

	use Apache2::API::DateTime;
	my $d = Apache2::API::DateTime->new( debug => 3 );
	my $dt = DateTime->now;
	$dt->set_formatter( $d );
	print( "$dt\n" );
	## will produce
	Sun, 15 Dec 2019 15:32:12 GMT
	
	my( @parts ) = $d->parse_date( $date_string );
	
	my $datetime_object = $d->str2datetime( $date_string );
	$datetime_object->set_formatter( $d );
	my $timestamp_in_seconds = $d->str2time( $date_string );
	my $datetime_object = $d->time2datetime( $timestamp_in_seconds );
	my $datetime_string = $d->time2str( $timestamp_in_seconds );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This module contains methods to create and manipulate datetime representation from and to L<DateTime> object or unix timestamps.

When using it as a formatter to a L<DateTime> object, this will make sure it is properly formatted for its use in HTTP headers and cookies.

=head1 METHODS

=head2 new

This initiates the package and take the following parameters:

=over 4

=item * C<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 format_datetime

Provided a L<DateTime> object, this returns a HTTP compliant string representation, such as:

	Sun, 15 Dec 2019 15:32:12 GMT

that can be used in HTTP headers and cookies' expires property as per rfc6265.

=head2 parse_date

Given a datetime string, this returns, in list context, a list of day, month, year, hour, minute, second and time zone or an iso 8601 datetime string in scalar context.

This is used by the method L</str2datetime>

=head2 parse_datetime

Provided with a date string, and this will parse it and return a L<DateTime> object, or sets an L<error|Module::Generic/error> and return C<undef> or an empty list depending on the context.

=head2 str2datetime

Given a string that looks like a date, this will parse it and return a L<DateTime> object.

=head2 str2time

Given a string that looks like a date, this returns its representation as a unix timestamp in second since epoch.

In the background, it calls L</str2datetime> for parsing.

=head2 time2datetime

Given a unix timestamp in seconds since epoch, this returns a L<DateTime> object.

=head2 time2str

Given a unix timestamp in seconds since epoch, this returns a string representation of the timestamp suitable for HTTP headers and cookies. The format is like C<Sat, 14 Dec 2019 22:12:30 GMT>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DateTime>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

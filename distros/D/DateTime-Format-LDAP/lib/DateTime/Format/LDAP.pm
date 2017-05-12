package DateTime::Format::LDAP;
$DateTime::Format::LDAP::VERSION = '0.002';
use 5.8.0;
use strict;
use warnings;

use DateTime;

use Params::Validate qw( validate_with SCALAR );

sub new
{
    my $class = shift;
    my $self;
    %$self = @_;

    return bless $self, $class;
}

# key is string length
my %valid_formats =
    ( 14 =>
      { params => [ qw( year month day hour minute second ) ],
        regex  => qr/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
      },
      12 =>
      { params => [ qw( year month day hour minute ) ],
        regex  => qr/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
      },
      10 =>
      { params => [ qw( year month day hour ) ],
        regex  => qr/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)$/,
      },
    );

sub parse_datetime
{
    my ( $self, $date ) = @_;

    $self = {} unless ref $self;
    my $asn1 = defined $self->{asn1} ? $self->{asn1} : 0;

    # save for error messages
    my $original = $date;

    my %p;
    if ( $date =~ s/Z$// )
    {
        $p{time_zone} = 'UTC';
    }
    elsif ( $date =~ s/([+-]([01]\d|2[0-3])[0-5]\d)$// )
    {
        $p{time_zone} = $1;
    }
    elsif ( $asn1 )
    {
        $p{time_zone} = 'floating';
    }
    else
    {
        die "Invalid LDAP datetime string ($original)\n";
    }

    my $fraction;
    if ( $date =~ s/[.,](\d+)// ) {
        $fraction = "0.$1";
    }

    my $format = $valid_formats{ length $date }
        or die "Invalid LDAP datetime string ($original)\n";

    @p{ @{ $format->{params} } } = $date =~ /$format->{regex}/;

    # If <minute> is omitted, then <fraction> represents a fraction of an
    # hour; otherwise, if <second> and <leap-second> are omitted, then
    # <fraction> represents a fraction of a minute; otherwise, <fraction>
    # represents a fraction of a second.
    if (defined $fraction )
    {
        if ( exists $p{second} )
        {
            $p{nanosecond} = int($fraction * 1000**3 + 0.5);
        }
        elsif ( exists $p{minute} )
        {
            $p{second} = int($fraction * 60);
            $fraction = $fraction * 60 - $p{second};
            if ( $fraction )
            {
                $p{nanosecond} = int($fraction * 1000**3 + 0.5);
            }
        }
        else
        {
            $p{minute} = int($fraction * 60);
            $fraction = $fraction * 60 - $p{minute};
            if ( $fraction )
            {
                $p{second} = int($fraction * 60);
                $fraction = $fraction * 60 - $p{second};
                if ( $fraction )
                {
                    $p{nanosecond} = int($fraction * 1000**3 + 0.5);
                }
            }
        }
    }
    return DateTime->new(%p);
}

sub format_datetime
{
    my ( $self, $dt ) = @_;

    $self = {} unless ref $self;
    my $asn1 = defined $self->{asn1} ? $self->{asn1} : 0;
    my $offset = defined $self->{offset} ? $self->{offset} : 0;

    my $tz = $dt->time_zone;

    die 'LDAP datetime cannot be floating' if $tz->is_floating and !$asn1;

    unless ( $offset )
    {
        unless ( $tz->is_utc || $tz->is_floating )
        {
            $dt = $dt->clone->set_time_zone('UTC');
            $tz = $dt->time_zone;
        }
    }

    my $base =
        sprintf( '%04d%02d%02d%02d%02d%02d',
                 $dt->year, $dt->month, $dt->day,
                 $dt->hour, $dt->minute, $dt->second );

    $base .= substr sprintf( '%.9g', $dt->nanosecond / 1000**3 ), 1 if $dt->nanosecond;

    return $base if $tz->is_floating;

    return $base . 'Z' if $tz->is_utc;

    return $base . $tz->offset_as_string($dt->offset);
}

1;

__END__

=head1 NAME

DateTime::Format::LDAP - Parse and format LDAP datetime strings (Generalized Time)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use DateTime::Format::LDAP;

  my $dt = DateTime::Format::LDAP->parse_datetime( '20030117032900Z' );

  # 20030117032900Z
  DateTime::Format::LDAP->format_datetime($dt);

=head1 DESCRIPTION

This module understands the LDAP datetime formats, as defined in L<RFC 4517:
Generalized Time|http://tools.ietf.org/html/rfc4517#section-3.3.13>.  It can
be used to parse these formats in order to create the appropriate objects.
As this is a subset of GeneralizedTime from X.680 ASN.1 (namely, it does not
allow local/floating) time, there is an option to allow this as well.

=head1 METHODS

This class offers the following methods.

=over 4

=item * new(%options)

Options are boolean C<offset> if you want offset time zones (C<-0500>)
instead of UTC (C<Z>) for C<format_datetime>, and C<asn1> if you want to be
able to parse local/floating times. These can be combined:

    my $dtf_ldap = DateTime::Format::LDAP->new(offset => 1, asn1 => 1);

Default is false for both.

=item * parse_datetime($string)

Given an LDAP datetime string, this method will return a new
C<DateTime> object.

If given an improperly formatted string, this method may die.

=item * format_datetime($datetime)

Given a C<DateTime> object, this methods returns an LDAP datetime
string.

The LDAP spec requires that datetimes be formatted either as UTC (with a
C<Z> suffix) or with an offset (C<-0500>), stating that the C<Z> form SHOULD
be used.  This method will by default format using a C<Z> suffix. 
Optionally, you can also pass a C<HASH> to have it use an offset instead:
C<< {offset => 1} >>.  If the C<DateTime> object is a floating time, this
method will die.

For example, this code:

    my $dt = DateTime->new( year => 1900, hour => 15, time_zone => '-0100' );

    print $ldap->format_datetime($dt);

will print the string "19000101160000Z". To use an offset:

    print $ldap->format_datetime($dt, {offset => 1});

will print the string "19000101150000-0100".

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

=head1 AUTHORS

Ashley Willis <ashley+perl@gitable.org>

This module used C<DateTime::Format::ICal> by Dave Rolsky and Flavio
Soibelmann Glock as a starting point.

=head1 COPYRIGHT

Copyright (c) 2014 Ashley Willis.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

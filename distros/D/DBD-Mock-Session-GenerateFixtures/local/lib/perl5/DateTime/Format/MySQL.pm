package DateTime::Format::MySQL;

use strict;

use vars qw ($VERSION);

$VERSION = '0.08';

use DateTime;
use DateTime::Format::Builder
    ( parsers =>
      { parse_date =>
        { params => [ qw( year month day ) ],
          regex  => qr/^(\d{1,4})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})$/,
        },

        parse_datetime =>
        [ { params => [ qw( year month day hour minute second ) ],
            regex  => qr/^(\d{1,4})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})[\sT](\d{1,2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})$/,
            extra  => { time_zone => 'floating' },
          },
          { params => [ qw( year month day hour minute second microsecond ) ],
            regex  => qr/^(\d{1,4})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})[\sT](\d{1,2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})\.(\d{1,6})/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_convert_micro_to_nanosecs,
          },
        ],

        parse_timestamp =>
        [ { params => [ qw( year month day hour minute second microsecond ) ],
            regex  => qr/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)\.(\d{1,6})$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_convert_micro_to_nanosecs,
          },
          { params => [ qw( year month day hour minute second microsecond ) ],
            regex  => qr/^(\d{1,4})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})[\sT](\d{1,2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})\.(\d{1,6})/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_convert_micro_to_nanosecs,
          },
          { length => 14,
            params => [ qw( year month day hour minute second ) ],
            regex  => qr/^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
            extra  => { time_zone => 'floating' },
          },
          {
            params => [ qw( year month day hour minute second ) ],
            regex  => qr/^(\d{1,4})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})[\sT](\d{1,2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})$/,
            extra  => { time_zone => 'floating'},
          },
          { length => 12,
            params => [ qw( year month day hour minute second ) ],
            regex  => qr/^(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_2_digit_year,
          },
          { length => 10,
            params => [ qw( year month day hour minute ) ],
            regex  => qr/^(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_2_digit_year,
          },
          { length => 8,
            params => [ qw( year month day ) ],
            regex  => qr/^(\d\d\d\d)(\d\d)(\d\d)$/,
            extra  => { time_zone => 'floating' },
          },
          { length => 6,
            params => [ qw( year month day ) ],
            regex  => qr/^(\d\d)(\d\d)(\d\d)$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_2_digit_year,
          },
          { length => 4,
            params => [ qw( year month ) ],
            regex  => qr/^(\d\d)(\d\d)$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_2_digit_year,
          },
          { length => 2,
            params => [ qw( year ) ],
            regex  => qr/^(\d\d)$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_2_digit_year,
          },
        ],
      },
    );

sub _fix_2_digit_year
{
    my %p = @_;

    $p{parsed}{year} += $p{parsed}{year} <= 69 ? 2000 : 1900;
}

sub format_date
{
    my ( $self, $dt ) = @_;

    return $dt->ymd('-');
}

sub format_time
{
    my ( $self, $dt ) = @_;

    return $dt->microsecond ? join('.', $dt->hms(':'), sprintf("%06d", $dt->microsecond)) : $dt->hms(':');
}

sub format_datetime
{
    my ( $self, $dt ) = @_;

    return $self->format_date($dt) . ' ' . $self->format_time($dt);
}

# DateTime constructor only has nanosecond. MySQL provides micro
sub _convert_micro_to_nanosecs
{
  my %p = @_;
  my $micro_secs = delete $p{parsed}{microsecond};

  # right pad with zeros
  $micro_secs .= '0' x (6 - length($micro_secs));
  $p{parsed}{nanosecond} = $micro_secs * 1000; 
  return 1; # parse successful
}



1;

__END__

=head1 NAME

DateTime::Format::MySQL - Parse and format MySQL dates and times

=head1 SYNOPSIS

  use DateTime::Format::MySQL;

  my $dt = DateTime::Format::MySQL->parse_datetime( '2003-01-16 23:12:01' );

  # 2003-01-16 23:12:01
  DateTime::Format::MySQL->format_datetime($dt);

=head1 DESCRIPTION

This module understands the formats used by MySQL for its DATE,
DATETIME, TIME, and TIMESTAMP data types.  It can be used to parse
these formats in order to create DateTime objects, and it can take a
DateTime object and produce a string representing it in the MySQL
format.

=head1 METHODS

This class offers the following methods.  All of the parsing methods
set the returned DateTime object's time zone to the floating time
zone, because MySQL does not provide time zone information.

=over 4

=item * parse_datetime($string)

=item * parse_date($string)

=item * parse_timestamp($string)

Given a value of the appropriate type, this method will return a new
C<DateTime> object.  The time zone for this object will always be the
floating time zone, because by MySQL stores the local datetime, not
UTC.

If given an improperly formatted string, this method may die.

=item * format_date($datetime)

=item * format_time($datetime)

=item * format_datetime($datetime)

Given a C<DateTime> object, this methods returns an appropriately
formatted string.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2003-2014 David Rolsky.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

package DateTime::Format::DB2;

use strict;

use vars qw ($VERSION);

$VERSION = '0.06';

use DateTime;
use DateTime::Format::Builder
    ( parsers =>
# 12/13/2005
      { parse_date =>
        { params => [ qw( year month day ) ],
          regex  => qr!^(\d\d\d\d)-(\d\d)-(\d\d)$!,
        },
# 12:17:46
        parse_time =>
        { params => [ qw( hour minute second ) ],
          regex  => qr!^(\d\d):(\d\d):(\d\d)$!,
          extra  => { time_zone => 'floating' },
        },
# 2005-12-13-12.19.07.276270
        parse_timestamp =>
        [ { params => [ qw( year month day hour minute second nanosecond) ],
            regex  => qr/^(\d\d\d\d)-(\d\d)-(\d\d)-(\d\d)\.(\d\d)\.(\d\d)(\.\d+)?$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_nano
          },
        { params => [ qw( year month day hour minute second nanosecond) ],
            regex  => qr/^(\d\d\d\d)-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d)(\.\d+)?$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_nano
          },
        ],
        parse_datetime =>
        [ { params => [ qw( year month day hour minute second nanosecond) ],
            regex  => qr/^(\d\d\d\d)-(\d\d)-(\d\d)-(\d\d)\.(\d\d)\.(\d\d)(\.\d+)?$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_nano
          },
        { params => [ qw( year month day hour minute second nanosecond) ],
            regex  => qr/^(\d\d\d\d)-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d)(\.\d+)?$/,
            extra  => { time_zone => 'floating' },
            postprocess => \&_fix_nano
          },
        ],
      },
    );

sub _fix_nano
{
    my %p = @_;

    $p{parsed}{nanosecond} = int($p{parsed}{nanosecond} * 10**9);

    return 1;
}

sub format_date
{
    my ( $self, $dt ) = @_;

    return $dt->ymd('-');
}

sub format_time
{
    my ( $self, $dt ) = @_;

    return $dt->hms(':');
}

sub format_timestamp
{
    my ( $self, $dt ) = @_;

    return $self->format_date($dt) . '-' . $dt->hms('.');
}

*format_datetime = *format_timestamp;

1;

__END__

=head1 NAME

DateTime::Format::DB2 - Parse and format DB2 dates and times

=head1 SYNOPSIS

  use DateTime::Format::DB2;

  my $dt = DateTime::Format::DB2->parse_timestamp( '2003-01-16-23.12.01.300000' );

  # 2003-01-16-23.12.01.300000
  DateTime::Format::DB2->format_timestamp($dt);

=head1 DESCRIPTION

This module understands the formats used by DB2 for its DATE,
TIME, and TIMESTAMP data types.  It can be used to parse
these formats in order to create DateTime objects, and it can take a
DateTime object and produce a string representing it in the DB2
format.

=head1 METHODS

This class offers the following methods.  All of the parsing methods
set the returned DateTime object's time zone to the floating time
zone, because DB2 does not provide time zone information.

=over 4

=item * parse_time($string)

=item * parse_date($string)

=item * parse_timestamp($string)

Given a value of the appropriate type, this method will return a new
C<DateTime> object.  The time zone for this object will always be the
floating time zone, because by DB2 stores the local datetime, not
UTC.

If given an improperly formatted string, this method may die.

=item * format_date($datetime)

=item * format_time($datetime)

=item * format_timestamp($datetime)

Given a C<DateTime> object, this methods returns an appropriately
formatted string.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

=head1 AUTHOR

Jess Robinson <castaway@desert-island.demon.co.uk>

This module was shamelessly cloned from Dave Rolsky's L<DateTime::Format::MySQL> module.

=head1 COPYRIGHT

Copyright (c) 2005 Jess Robinson.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

package DateTime::Format::Oracle;

use strict;

use Carp;
use DateTime;
use DateTime::Format::Builder;
use Convert::NLS_DATE_FORMAT;

our $VERSION = '0.06';
our $nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
our $nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS';
our $nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS TZHTZM';

=head1 NAME

DateTime::Format::Oracle - Parse and format Oracle dates and timestamps

=head1 SYNOPSIS

  use DateTime::Format::Oracle;

  $ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI:SS';
  my $dt = DateTime::Format::Oracle->parse_datetime('2003-01-16 23:12:01');
  my $string = DateTime::Format::Oracle->format_datetime($dt);

=head1 DESCRIPTION

This module may be used to convert Oracle date and timestamp values
into C<DateTime> objects.  It also can take a C<DateTime> object and
produce a date string matching the C<NLS_DATE_FORMAT>.

Oracle has flexible date formatting via its C<NLS_DATE_FORMAT> session
variable.  Date values will be returned from Oracle according to the
current value of that variable.  Date values going into Oracle must also
match the current setting of C<NLS_DATE_FORMAT>.

Timestamp values will match either the C<NLS_TIMESTAMP_FORMAT> or
C<NLS_TIMESTAMP_TZ_FORMAT> session variables.

This module keeps track of these Oracle session variable values by
examining environment variables of the same name.  Each time one of
Oracle's formatting session variables is updated, the C<%ENV> hash
must also be updated.

=head1 METHODS

This class offers the following methods.

=over 4

=item * nls_date_format

This method is used to determine the current value of Oracle's
C<NLS_DATE_FORMAT>.  It currently just reads the value from

  $ENV{'NLS_DATE_FORMAT'}

or if that is not set, from the package variable C<$nls_date_format>,
which has a default value of C<YYYY-MM-DD HH24:MI:SS>.  This is
a good default to have, but is not Oracle's default.  Dates will fail
to parse if Oracle's NLS_DATE_FORMAT and the value from this method
are not the same.

If you want to use the default from this module, you can do something
like this after you connect to Oracle:

  $dbh->do(
      "alter session set nls_date_format = '" .
      DateTime::Format::Oracle->nls_date_format .
      "'"
  );

=cut

sub nls_date_format { $ENV{NLS_DATE_FORMAT} || $nls_date_format }

=item * nls_timestamp_format

This method is used to determine the current value of Oracle's
C<NLS_TIMESTAMP_FORMAT>.  It currently just reads the value from

  $ENV{'NLS_TIMESTAMP_FORMAT'}

or if that is not set, from the package variable C<$nls_timestamp_format>,
which has a default value of C<YYYY-MM-DD HH24:MI:SS>.  This is
a good default to have, but is not Oracle's default.  Dates will fail
to parse if Oracle's NLS_TIMESTAMP_FORMAT and the value from this method
are not the same.

If you want to use the default from this module, you can do something
like this after you connect to Oracle:

  $dbh->do(
      "alter session set nls_timestamp_format = '" .
      DateTime::Format::Oracle->nls_timestamp_format .
      "'"
  );

=cut

sub nls_timestamp_format { $ENV{NLS_TIMESTAMP_FORMAT} || $nls_timestamp_format }

=item * nls_timestamp_tz_format

This method is used to determine the current value of Oracle's
C<NLS_TIMESTAMP_TZ_FORMAT>.  It currently just reads the value from

  $ENV{'NLS_TIMESTAMP_TZ_FORMAT'}

or if that is not set, from the package variable C<$nls_timestamp_tz_format>,
which has a default value of C<YYYY-MM-DD HH24:MI:SS TZHTZM>.  This is
a good default to have, but is not Oracle's default.  Dates will fail
to parse if Oracle's NLS_TIMESTAMP_TZ_FORMAT and the value from this method
are not the same.

If you want to use the default from this module, you can do something
like this after you connect to Oracle:

  $dbh->do(
      "alter session set nls_timestamp_tz_format = '" .
      DateTime::Format::Oracle->nls_timestamp_tz_format .
      "'"
  );

=cut

sub nls_timestamp_tz_format { $ENV{NLS_TIMESTAMP_TZ_FORMAT} || $nls_timestamp_tz_format }

=item * parse_datetime

Given a string containing a date and/or time representation
matching C<NLS_DATE_FORMAT>, this method will return a new
C<DateTime> object.

If given an improperly formatted string, this method may die.

=cut

sub parse_datetime { $_[0]->current_date_parser->(@_); }

=item * parse_date

Alias to C<parse_datetime>.  Oracle's date datatype also holds
time information.

=cut

*parse_date = \&parse_datetime;

=item * parse_timestamp

Given a string containing a date and/or time representation
matching C<NLS_TIMESTAMP_FORMAT>, this method will return a new
C<DateTime> object.

If given an improperly formatted string, this method may die.

=cut

sub parse_timestamp { $_[0]->current_timestamp_parser->(@_); }

=item * parse_timestamptz
=item * parse_timestamp_with_time_zone

Given a string containing a date and/or time representation
matching C<NLS_TIMESTAMP_TZ_FORMAT>, this method will return a new
C<DateTime> object.

If given an improperly formatted string, this method may die.

=cut

sub parse_timestamptz { $_[0]->current_timestamptz_parser->(@_); }
*parse_timestamp_with_time_zone = \&parse_timestamptz;

=item * current_date_parser

The current C<DateTime::Format::Builder> generated parsing method
used by C<parse_datetime> and C<parse_date>.

=cut

*current_date_parser = _parser_generator('current_date_format');

=item * current_timestamp_parser

The current C<DateTime::Format::Builder> generated parsing method
used by C<parse_timestamp>.

=cut

*current_timestamp_parser = _parser_generator('current_timestamp_format');

=item * current_timestamptz_parser

The current C<DateTime::Format::Builder> generated parsing method
used by C<parse_timestamptz>.

=cut

*current_timestamptz_parser = _parser_generator('current_timestamptz_format');

sub _parser_generator {
    # takes a method name for getting the current POSIX format
    # returns a parser generator code ref
    my $previous_format = '';
    my $previous_parser = '';
    my $method = shift;
    sub {
        my ( $self ) = @_;
        unless ($previous_format eq (my $current_format = $self->$method())) {
            $previous_format = $current_format;
            $previous_parser = $self->_create_parser_method($current_format);
        }
        return $previous_parser;
    }
}

sub _create_parser_method {
    # takes a strptime format, returns a parser method code ref
    my ( $self, $date_format ) = @_;
    my %parse_date = ( strptime => { pattern => $date_format } );
    my $parser = DateTime::Format::Builder->create_parser(\%parse_date);
    return DateTime::Format::Builder->create_method($parser);
}

=item * format_datetime

Given a C<DateTime> object, this method returns a string matching
the current value of C<NLS_DATE_FORMAT>.

It is important to keep the value of C<$ENV{'NLS_DATE_FORMAT'}> the
same as the value of the Oracle session variable C<NLS_DATE_FORMAT>.

To determine the current value of Oracle's C<NLS_DATE_FORMAT>:

  select NLS_DATE_FORMAT from NLS_SESSION_PARAMETERS

To reset Oracle's C<NLS_DATE_FORMAT>:

  alter session set NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'

It is generally a good idea to set C<NLS_DATE_FORMAT> to an
unambiguos value, with four-digit year, and hour, minute, and second.

=cut

sub format_datetime {
    my ($self, $dt) = @_;
    return $dt->strftime($self->current_date_format);
}

=item * format_date

Alias to C<format_datetime>.

=cut

*format_date = \&format_datetime;

=item * format_timestamp

Given a C<DateTime> object, this method returns a string matching
the current value of C<NLS_TIMESTAMP_FORMAT>.

It is important to keep the value of C<$ENV{'NLS_TIMESTAMP_FORMAT'}> the
same as the value of the Oracle session variable C<NLS_TIMESTAMP_FORMAT>.

To determine the current value of Oracle's C<NLS_TIMESTAMP_FORMAT>:

  select NLS_TIMESTAMP_FORMAT from NLS_SESSION_PARAMETERS

To reset Oracle's C<NLS_TIMESTAMP_FORMAT>:

  alter session set NLS_TIMESTAMP_FORMAT='YYYY-MM-DD HH24:MI:SS'

It is generally a good idea to set C<NLS_TIMESTAMP_FORMAT> to an
unambiguos value, with four-digit year, and hour, minute, and second.

=cut

sub format_timestamp {
    my ($self, $dt) = @_;
    return $dt->strftime($self->current_timestamp_format);
}

=item * format_timestamptz
=item * format_timestamp_with_time_zone

Given a C<DateTime> object, this method returns a string matching
the current value of C<NLS_TIMESTAMP_TZ_FORMAT>.

It is important to keep the value of C<$ENV{'NLS_TIMESTAMP_TZ_FORMAT'}> the
same as the value of the Oracle session variable C<NLS_TIMESTAMP_TZ_FORMAT>.

To determine the current value of Oracle's C<NLS_TIMESTAMP_TZ_FORMAT>:

  select NLS_TIMESTAMP_TZ_FORMAT from NLS_SESSION_PARAMETERS

To reset Oracle's C<NLS_TIMESTAMP_TZ_FORMAT>:

  alter session set NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD HH24:MI:SS TZHTZM'

It is generally a good idea to set C<NLS_TIMESTAMP_TZ_FORMAT> to an
unambiguos value, with four-digit year, and hour, minute, and second.

=cut

sub format_timestamptz {
    my ($self, $dt) = @_;
    return $dt->strftime($self->current_timestamptz_format);
}

*format_timestamp_with_time_zone = \&format_timestamptz;

=item * current_date_format

The current generated method used by C<format_datetime>,
C<format_date>, and C<current_date_parser> to keep track of
the C<strptime> translation of C<NLS_DATE_FORMAT>.

=cut

*current_date_format = _format_generator('nls_date_format');

=item * current_timestamp_format

The current generated method used by C<format_timestamp>,
C<format_timestamp_with_time_zone>, and C<current_timestamp_parser> to keep track of
the C<strptime> translation of C<NLS_TIMESTAMP_FORMAT>.

=cut

*current_timestamp_format = _format_generator('nls_timestamp_format');

=item * current_timestamptz_format

The current generated method used by C<format_timestamptz>,
C<format_timestamp_with_time_zone>, and C<current_timestamp_parser> to keep track of
the C<strptime> translation of C<NLS_TIMESTAMP_FORMAT>.

=cut

*current_timestamptz_format = _format_generator('nls_timestamp_tz_format');

sub _format_generator {
    # takes a method name for getting the current Oracle format
    # returns a format generator code ref
    my $previous_nls_format = '';
    my $previous_format = '';
    my $method = shift;
    sub {
        my ( $self ) = @_;
        unless ($previous_nls_format eq (my $current_nls_format = $self->$method())) {
            $previous_nls_format = $current_nls_format;
            $previous_format = $self->oracle_to_posix($current_nls_format);
        }
        return $previous_format;
    }
}

=item * oracle_to_posix

Given an C<NLS_DATE_FORMAT>, C<NLS_TIMESTAMP_FORMAT>, or
C<NLS_TIMESTAMP_TZ_FORMAT> value, this method returns a
C<DateTime>-compatible C<strptime> format value.

Translation is currently handled by C<Convert::NLS_DATE_FORMAT>.

=cut

sub oracle_to_posix {
    my ( $self, $nls_format ) = @_;
    Convert::NLS_DATE_FORMAT::oracle2posix($nls_format);
}

=back

=cut

1;

__END__

=head1 LIMITATIONS

Oracle is more flexible with the case of names, such as the month,
whereas C<DateTime> generally returns names in C<ucfirst> format.

  MONTH -> FEBRUARY
  Month -> February
  month -> february

All translate to:

  %B    -> February

=head2 TIME ZONES

Oracle returns all dates and timestamps in a time zone similar to
the C<DateTime> floating time zone, except for 'timestamp with time zone'
columns.

=head2 INTERVAL ELEMENTS

I have not implemented C<parse_duration>, C<format_duration>,
C<parse_interval>, nor C<format_interval>, and have no plans to do so.

If you need these features, unit tests, method implementations, and
pointers to documentation are all welcome.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

=head1 TODO

Possibly read an environment variable to determine a time zone to
use instead of 'floating'.

Test and document creating an instance via C<new>.

=head1 AUTHOR

Nathan Gray, E<lt>kolibrie@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

I might have put this module off for another couple years
without the lure of Jifty, Catalyst, and DBIx::Class pulling
at me.

Thanks to Dan Horne for his RFC draft of this module.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006, 2008, 2011 Nathan Gray.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

Convert::NLS_DATE_FORMAT

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

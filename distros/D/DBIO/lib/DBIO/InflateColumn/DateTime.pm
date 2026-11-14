package DBIO::InflateColumn::DateTime;
# ABSTRACT: Auto-create DateTime objects from date and datetime columns.

use strict;
use warnings;

our $VERSION = '0.900005';

use base qw/DBIO::Base/;
use DBIO::Carp;
use Try::Tiny;
use DBIO::Util qw(mask_bound_values);
use namespace::clean;


__PACKAGE__->load_components(qw/InflateColumn/);


sub register_column {
  my ($self, $column, $info, @rest) = @_;

  $self->next::method($column, $info, @rest);

  my $requested_type;
  for (qw/datetime timestamp date/) {
    my $key = "inflate_${_}";
    if (exists $info->{$key}) {

      # this bailout is intentional
      return unless $info->{$key};

      $requested_type = $_;
      last;
    }
  }

  return if (!$requested_type and !$info->{data_type});

  my $data_type = lc( $info->{data_type} || '' );

  # _ic_dt_method will follow whatever the registration requests
  # thus = instead of ||=
  $info->{_ic_dt_fallback} = 'datetime';
  delete $info->{_ic_dt_time};
  if ($data_type eq 'timestamp with time zone' || $data_type eq 'timestamptz') {
    $info->{_ic_dt_method} = 'timestamp_with_time_zone';
  }
  elsif ($data_type eq 'timestamp without time zone') {
    $info->{_ic_dt_method} = 'timestamp_without_time_zone';
  }
  elsif ($data_type eq 'smalldatetime') {
    $info->{_ic_dt_method} = 'smalldatetime';
  }
  elsif ($data_type =~ /^ (?: date | datetime | timestamp ) $/x) {
    $info->{_ic_dt_method} = $data_type;
  }
  elsif ($requested_type) {
    # a type of its own gets its own channel; the rest follows the request
    (my $channel = $data_type) =~ s/\s*\(.*?\)//g;
    $channel =~ s/^\s+|\s+$//g;
    $channel =~ s/\s+/_/g;
    $channel =~ s/\W//g;
    $info->{_ic_dt_method} = length $channel ? $channel : $requested_type;
    $info->{_ic_dt_fallback} = $requested_type eq 'date' ? 'date' : 'datetime';

    # a time of day has channels of its own and never falls back to datetime
    if ($channel =~ /^ (?: time | time_without_time_zone ) $/x) {
      $info->{_ic_dt_time} = 'time';
    }
    elsif ($channel =~ /^ (?: time_with_time_zone | timetz ) $/x) {
      $info->{_ic_dt_time} = 'timetz';
    }
  }
  else {
    return;
  }

  if ($info->{extra}) {
    for my $slot (qw/timezone locale floating_tz_ok/) {
      if ( defined $info->{extra}{$slot} ) {
        carp "Putting $slot into extra => { $slot => '...' } has been deprecated, ".
             "please put it directly into the '$column' column definition.";
        $info->{$slot} = $info->{extra}{$slot} unless defined $info->{$slot};
      }
    }
  }

  # shallow copy to avoid unfounded(?) Devel::Cycle complaints
  my $infcopy = {%$info};

  $self->inflate_column(
    $column =>
      {
        inflate => sub {
          my ($value, $obj) = @_;

          # propagate for error reporting
          $infcopy->{__dbic_colname} = $column;

          my $dt = $obj->_inflate_to_datetime( $value, $infcopy );

          return (defined $dt)
            ? $obj->_post_inflate_datetime( $dt, $infcopy )
            : undef
          ;
        },
        deflate => sub {
          my ($value, $obj) = @_;

          $value = $obj->_pre_deflate_datetime( $value, $infcopy );
          $obj->_deflate_from_datetime( $value, $infcopy );
        },
      }
  );
}

# the method of the column's own channel when the parser has it, else the
# method of the fallback channel
sub _flate_method {
  my( $self, $parser, $info, $method_fmt ) = @_;

  my $preferred_method = sprintf($method_fmt, $info->{ _ic_dt_method });
  return $preferred_method if $parser->can($preferred_method);
  return sprintf($method_fmt, $info->{ _ic_dt_fallback } || 'datetime');
}

# the method a time of day goes through: its own channel, then the plain time
# channel (the one that carries an offset for a type with a zone); undef when
# the core reads or writes itself
sub _time_method {
  my( $self, $parser, $info, $method_fmt ) = @_;

  for my $channel ($info->{_ic_dt_method}, $info->{_ic_dt_time}) {
    my $method = sprintf($method_fmt, $channel);
    return $method if $parser->can($method);
  }
  return undef;
}

sub _flate_or_fallback
{
  my( $self, $value, $info, $method_fmt ) = @_;

  my $parser = $self->_datetime_parser;
  my $reading = $method_fmt =~ /^parse/;
  my $method = $info->{_ic_dt_time}
    ? $self->_time_method($parser, $info, $method_fmt)
    : $self->_flate_method($parser, $info, $method_fmt);

  return try {
    defined $method ? $parser->$method($value)
      : $reading ? $self->_parse_time_core($value, $info)
      : $self->_format_time_core($value, $info);
  }
  catch {
    $self->throw_exception (
      "Error while inflating column '$info->{__dbic_colname}' of class "
      . (ref($self) || $self) . ': ' . mask_bound_values("$_", [$value])
    )
      unless $info->{datetime_undef_if_invalid};
    undef;  # rv
  };
}

sub _inflate_to_datetime {
  my( $self, $value, $info ) = @_;
  return $self->_flate_or_fallback( $value, $info, 'parse_%s' );
}

sub _deflate_from_datetime {
  my( $self, $value, $info ) = @_;
  return $self->_flate_or_fallback( $value, $info, 'format_%s' );
}

sub _datetime_parser {
  shift->result_source->storage->datetime_parser (@_);
}

# does the column go through the date channel in this direction, as a calendar
# day: a date that carries a time of day (Oracle DATE) keeps it
sub _is_date_channel {
  my( $self, $info, $method_fmt ) = @_;

  return 0 if $self->result_source->storage->datetime_date_carries_time;
  return 1 if $info->{_ic_dt_method} eq 'date';
  return $self->_flate_method($self->_datetime_parser, $info, $method_fmt)
    eq sprintf($method_fmt, 'date');
}

# HH:MM:SS with an optional fraction, for a type with a zone Z, +HH or +HH:MM
# as well; the date is the day of the Unix epoch
sub _parse_time_core {
  my( $self, $value, $info ) = @_;

  require DateTime;

  my $zone = $info->{_ic_dt_time} eq 'timetz';
  my $re = $zone
    ? qr/^\s*(\d\d):(\d\d):(\d\d)(?:\.(\d+))?\s*(?:(Z)|([+-])(\d\d)(?::?(\d\d))?)?\s*\z/i
    : qr/^\s*(\d\d):(\d\d):(\d\d)(?:\.(\d+))?\s*\z/;

  my @m = defined $value ? $value =~ $re : ()
    or die "Unreadable time of day '" . (defined $value ? $value : 'NULL') . "'\n";
  my ($h, $mi, $s, $frac, $z, $sign, $oh, $om) = @m;

  my %zone = (time_zone => 'floating');
  if ($zone and defined $z) {
    $zone{time_zone} = 'UTC';
  }
  elsif ($zone and defined $sign) {
    $zone{time_zone} = sprintf('%s%02d%02d', $sign, $oh, $om || 0);
  }

  my $ns = defined $frac ? substr($frac . '0' x 9, 0, 9) : 0;

  return DateTime->new(
    year => 1970, month => 1, day => 1,
    hour => $h, minute => $mi, second => $s, nanosecond => $ns + 0,
    %zone,
  );
}

# the time in the value's own zone, the offset with it for a type with a zone
sub _format_time_core {
  my( $self, $dt, $info ) = @_;

  my $out = sprintf('%02d:%02d:%02d', $dt->hour, $dt->minute, $dt->second);

  if (my $ns = $dt->nanosecond) {
    (my $frac = sprintf('%09d', $ns)) =~ s/0+\z//;
    $out .= ".$frac";
  }

  # a floating value has no offset to write; the server applies its own rule
  if ($info->{_ic_dt_time} eq 'timetz' and not $dt->time_zone->is_floating) {
    my $off = $dt->offset;
    my $sign = $off < 0 ? '-' : '+';
    $off = abs $off;
    $out .= sprintf('%s%02d:%02d', $sign, int($off / 3600), int(($off % 3600) / 60));
  }

  return $out;
}

sub _post_inflate_datetime {
  my( $self, $dt, $info ) = @_;

  # a time of day stands on the day of the Unix epoch and is not converted;
  # without a zone it is floating, with one it keeps the offset it was read
  # with (a named zone could give 1970-01-01 another offset)
  if (my $kind = $info->{_ic_dt_time}) {
    if ($kind eq 'time') {
      $dt->set_time_zone('floating');
    }
    elsif ($dt->time_zone->is_olson) {
      $dt->set_time_zone( DateTime::TimeZone->offset_as_string($dt->offset) );
    }
    $dt->set( year => 1970, month => 1, day => 1 );
    $dt->set_locale($info->{locale}) if defined $info->{locale};
    return $dt;
  }

  # a date has no time of day and no zone: it is the calendar day the parser
  # read, floating at noon, so a conversion by less than 12 hours either way
  # keeps the day
  if ($self->_is_date_channel($info, 'parse_%s')) {
    $dt->set_time_zone('floating');
    $dt->set( hour => 12, minute => 0, second => 0, nanosecond => 0 );
  }

  $dt->set_time_zone($info->{timezone}) if defined $info->{timezone};
  $dt->set_locale($info->{locale}) if defined $info->{locale};

  return $dt;
}

sub _pre_deflate_datetime {
  my( $self, $dt, $info ) = @_;

  # a day stays the day it is in the value's own zone, a time of day the time
  # it is: no conversion, and the caller's object stays as it is
  if ($info->{_ic_dt_time} or $self->_is_date_channel($info, 'format_%s')) {
    $dt = $dt->clone;
    $dt->set_locale($info->{locale}) if defined $info->{locale};
    return $dt;
  }

  if (defined $info->{timezone}) {
    carp "You're using a floating timezone, please see the documentation of"
      . " DBIO::InflateColumn::DateTime for an explanation"
      if ref( $dt->time_zone ) eq 'DateTime::TimeZone::Floating'
          and not $info->{floating_tz_ok}
          and not $ENV{DBIO_FLOATING_TZ_OK};

    $dt = $dt->clone->set_time_zone($info->{timezone});
  }

  $dt = $dt->clone->set_locale($info->{locale}) if defined $info->{locale};

  return $dt;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::InflateColumn::DateTime - Auto-create DateTime objects from date and datetime columns.

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

Load this component and then declare one or more
columns to be of the datetime, timestamp or date datatype.

  package Event;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/InflateColumn::DateTime/);
  __PACKAGE__->add_columns(
    starts_when => { data_type => 'datetime' },
    create_date => { data_type => 'date' }
  );

Then you can treat the specified column as a L<DateTime> object.

  print "This event starts the month of ".
    $event->starts_when->month_name();

If you want to set a specific timezone and locale for that field, use:

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'datetime', timezone => "America/Chicago", locale => "de_DE" }
  );

If you want to inflate no matter what data_type your column is,
use inflate_datetime or inflate_date:

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'varchar', inflate_datetime => 1 }
  );

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'varchar', inflate_date => 1 }
  );

It's also possible to explicitly skip inflation:

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'datetime', inflate_datetime => 0 }
  );

NOTE: Don't rely on C<InflateColumn::DateTime> to parse date strings for you.
The column is set directly for any non-references and C<InflateColumn::DateTime>
is completely bypassed.  Instead, use an input parser to create a DateTime
object. For instance, if your user input comes as a 'YYYY-MM-DD' string, you can
use C<DateTime::Format::ISO8601> thusly:

  use DateTime::Format::ISO8601;
  my $dt = DateTime::Format::ISO8601->parse_datetime('YYYY-MM-DD');

See F<t/inflate_column_datetime.t> for a runnable example covering
inflation, deflation, and the C<inflate_datetime>/C<inflate_date> opt-in
and opt-out flags shown above.

=head1 DESCRIPTION

This module figures out the type of DateTime::Format::* class to
inflate/deflate with based on the type of DBIO::Storage::DBI::*
that you are using.  If you switch from one database to a different
one your code should continue to work without modification (though note
that this feature is new as of 0.07, so it may not be perfect yet - bug
reports to the list very much welcome).

If the data_type of a field is C<date>, C<datetime> or C<timestamp> (or
a derivative of these datatypes, e.g. C<timestamp with timezone>), this
module will automatically call the appropriate parse/format method for
deflation/inflation as defined in the storage class. For instance, for
a C<datetime> field the methods C<parse_datetime> and C<format_datetime>
would be called on deflation/inflation. If the storage class does not
provide a specialized inflator/deflator, C<[parse|format]_datetime> will
be used as a fallback. See L<DateTime/Formatters And Stringification>
for more information on date formatting.

=head2 One channel per column type

Every column type has a channel of its own: the methods
C<parse_E<lt>typeE<gt>> and C<format_E<lt>typeE<gt>> of the storage's
datetime parser. The type name is the C<data_type> in lower case, without
precision, with each run of spaces written as C<_>: C<datetime2(7)> is the
channel C<datetime2>, C<time with time zone> is C<time_with_time_zone>.

A column whose C<data_type> is not among C<date>, C<datetime>, C<timestamp>,
C<smalldatetime>, C<timestamp with time zone>, C<timestamptz> and
C<timestamp without time zone> inflates only when it asks for it with
C<inflate_datetime>, C<inflate_timestamp> or C<inflate_date>; such a type
without a flag is left alone. The column then goes to its own channel when the
parser has the method, each direction on its own. When the parser lacks it,
the requested kind decides: C<inflate_date> uses C<parse_date> and
C<format_date>, any other request C<parse_datetime> and C<format_datetime>.
So a C<varchar> column with C<< inflate_date => 1 >> is read through
C<parse_date>. The listed types fall back to C<parse_datetime> and
C<format_datetime>. A time of day never falls back to them, see
L</A time of day stands on 1970-01-01>.

A driver offers a type of its own by giving its datetime format class the two
methods, see L<DBIO::Storage::DateTimeFormat/Offering a type of its own>.

=head2 A date stands at noon

A date has no time of day. A column read through the C<date> channel (a
C<date> column, or C<< inflate_date => 1 >> where the parser provides no
channel for the column type) inflates to a floating L<DateTime> at 12:00:00, not at
midnight: the calendar day the parser read, whatever time and time zone it
returned with it. Noon is the time of day at which
a conversion to another time zone by less than 12 hours either way leaves the
calendar day as it was; the C<timezone> of the column is applied after that.
A day stays a day when written, too: a value written through the C<date>
channel is not converted to the C<timezone> of the column; the calendar day it
has in its own time zone is written. 2026-10-25 00:30 in Europe/Berlin in a
C<date> column with C<< timezone => 'UTC' >> is written as 2026-10-25. The
L<DateTime> object passed in is left as it is.

A database whose C<date> type carries a time of day, as Oracle's C<DATE> does,
says so through L<DBIO::Storage::DBI/datetime_date_carries_time>. Its C<date>
columns keep the time they were read and written with and follow the
C<timezone> of the column like a C<datetime>.

=head2 A time of day stands on 1970-01-01

A column of type C<time>, C<time without time zone>, C<time with time zone> or
C<timetz> stays a string unless it asks for inflation with C<inflate_datetime>
or C<inflate_timestamp>. Asked for, it goes through the channel of its type
(C<time>, C<time_without_time_zone>, C<time_with_time_zone>, C<timetz>), then
through C<parse_time>/C<format_time> of the storage's datetime parser (a type
with a time zone only through methods that carry the offset, such as
C<parse_timetz>/C<format_timetz>), each direction on its own. Where the parser
has no such method the core reads and writes itself: C<HH:MM:SS> with an
optional fraction, for a type with a time zone followed by C<Z>, C<+HH> or
C<+HH:MM>; it writes the fraction only when it is not zero, without trailing
zeros, and the offset as C<+HH:MM>. A time of day does not use
C<parse_datetime> or C<format_datetime>.

The inflated L<DateTime> stands on 1970-01-01, the day of the Unix epoch that
L<DateTime::Format::Pg> and JDBC give a time of day too, whatever date the
parser returned; the date never reaches the database. Without a time zone the
value is floating, with one it keeps the offset it was read with, as a fixed
offset. The C<timezone> of the column does not convert a time of day, neither
when read nor when written; the C<locale> applies. A value is written with the
time it has in its own time zone, and the L<DateTime> object passed in is left
as it is. A floating value in a column with a time zone is written without an
offset, and the database applies its own rule.

L<DateTime> and L<DateTime::Format::Strptime> are only C<recommends> of the
core distribution, not requirements: a bare DBIO install does not carry them.
Install L<DateTime> to use this component at all. A driver whose datetime
format class parses by strptime patterns
(L<DBIO::Storage::DateTimeFormat>) needs L<DateTime::Format::Strptime> as
well, and throws at the first parse or format when it is missing; the driver
distribution should declare it itself.

For more help with using components, see L<DBIO::Manual::Component/USING>.

=head1 METHODS

=head2 register_column

Chains with the L<DBIO::Row/register_column> method, and sets
up datetime columns appropriately.  This would not normally be
directly called by end users.

In the case of an invalid date, L<DateTime> will throw an exception.  To
bypass these exceptions and just have the inflation return undef, use
the C<datetime_undef_if_invalid> option in the column info:

    "broken_date",
    {
        data_type => "datetime",
        default_value => '0000-00-00',
        is_nullable => 1,
        datetime_undef_if_invalid => 1
    }

=head1 COLUMN INFO

=over 4

=item C<< data_type => 'datetime' | 'timestamp' | 'date' >>

Triggers automatic L<DateTime> inflation/deflation. Variants like
C<timestamp with time zone>, C<timestamptz>, C<timestamp without time zone>
and C<smalldatetime> are recognised and routed to the appropriate
parse/format method on the storage class, with C<parse_datetime> and
C<format_datetime> as fallback.

=item C<< inflate_datetime => 1 >> / C<< inflate_timestamp => 1 >> / C<< inflate_date => 1 >>

Forces inflation regardless of C<data_type>. The column goes to the channel of
its own type (see L</One channel per column type>); where the parser has none,
C<inflate_date> falls back to C<parse_date>/C<format_date>, the others to
C<parse_datetime>/C<format_datetime>; a time of day follows
L</A time of day stands on 1970-01-01>. Useful when storing dates
in C<varchar> columns. Set to C<0> to opt out for a column whose
C<data_type> would otherwise trigger inflation.

=item C<< timezone => $tz >>, C<< locale => $loc >>

Set on the inflated L<DateTime> object. When a value is written, a copy of it
is converted to the C<timezone>; the L<DateTime> object passed in keeps its
zone. A date and a time of day are not converted, see L</A date stands at noon>
and L</A time of day stands on 1970-01-01>.

=item C<< floating_tz_ok => 1 >>

Suppress the warning when assigning a floating-timezone L<DateTime> to
a column with a fixed C<timezone>.

=item C<< datetime_undef_if_invalid => 1 >>

Return C<undef> on parse failure instead of throwing.

=back

=head1 USAGE NOTES

If you have a datetime column with an associated C<timezone>, and subsequently
create/update this column with a DateTime object in the L<DateTime::TimeZone::Floating>
timezone, you will get a warning (as there is a very good chance this will not have the
result you expect). For example:

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'datetime', timezone => "America/Chicago" }
  );

  my $event = $schema->resultset('EventTZ')->create({
    starts_at => DateTime->new(year=>2007, month=>12, day=>31, ),
  });

The warning can be avoided in several ways:

=over

=item Fix your broken code

When calling C<set_time_zone> on a Floating DateTime object, the timezone is simply
set to the requested value, and B<no time conversion takes place>. It is always a good idea
to be supply explicit times to the database:

  my $event = $schema->resultset('EventTZ')->create({
    starts_at => DateTime->new(year=>2007, month=>12, day=>31, time_zone => "America/Chicago" ),
  });

=item Suppress the check on per-column basis

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'datetime', timezone => "America/Chicago", floating_tz_ok => 1 }
  );

=item Suppress the check globally

Set the environment variable DBIO_FLOATING_TZ_OK to some true value.

=back

Putting extra attributes like timezone, locale or floating_tz_ok into extra => {} has been
B<DEPRECATED>. Instead put it directly into the columns definition like in the examples
above. If you still use the old way you'll see a warning - please fix your code then!

=head1 SEE ALSO

=over 4

=item More information about the add_columns method, and column metadata,
      can be found in the documentation for L<DBIO::ResultSource>.

=item Further discussion of problems inherent to the Floating timezone:
      L<Floating DateTimes|DateTime/Floating DateTimes>
      and L<< $dt->set_time_zone|DateTime/"Set" Methods >>

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

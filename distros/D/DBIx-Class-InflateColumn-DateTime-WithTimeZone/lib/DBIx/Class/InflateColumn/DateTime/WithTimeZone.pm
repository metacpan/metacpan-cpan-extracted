package DBIx::Class::InflateColumn::DateTime::WithTimeZone;

use strict;
use warnings;
use base 'DBIx::Class::InflateColumn::DateTime';

our $VERSION = '0.03';

use DateTime::TimeZone;

sub register_column {
    my ( $self, $column, $info, @rest ) = @_;

    my $msg = "Column $column:";

    # NOTE: must update $info before calling parent, b/c parent copies $info
    if ( my $tz_source = $info->{timezone_source} ) {

        # force InflateColumn::DateTime to convert to UTC before storing
        $info->{timezone} ||= 'UTC';
        if ( $info->{timezone} ne 'UTC' ) {
            $self->throw_exception( "$msg saving non-UTC datetimes in database is not supported" );
        }
    }

    $self->next::method( $column, $info, @rest );

    if ( my $tz_source = $info->{timezone_source} ) {
        my $ic_dt_method = $info->{_ic_dt_method};
        if ( !$ic_dt_method || !$ic_dt_method =~ /(?: datetime | timestamp )/x ) {
            $self->throw_exception( "$msg timezone_source requires datetime data_type");
        }

        if ( !$self->has_column($tz_source) ) {
            $self->throw_exception( "$msg could not find column $tz_source for timezone_source" );
        }

        my $tz_info = $self->column_info($tz_source);

        if ( $info->{is_nullable} && !$tz_info->{is_nullable} ) {
            $self->throw_exception( "$msg: is nullable, so $tz_source must also be nullable" );
        }
    }
}

my %tz_cache;

sub _get_cached_tz {
    my ( $self, $tz ) = @_;
    return $tz_cache{$tz} ||= DateTime::TimeZone->new( name => $tz );
}

sub _post_inflate_datetime {
    my ( $self, $dt, $info ) = @_;

    $dt = $self->next::method( $dt, $info );

    if ( my $tz_src = $info->{timezone_source} ) {
        if ( !$self->has_column_loaded($tz_src) ) {
            my $colname = $info->{__dbic_colname};
            $self->throw_exception(
               "$colname needs time zone from $tz_src, but $tz_src is not loaded: check query?" );
        }
        my $tz = $self->get_column($tz_src);
        if ($tz) {
            $dt->set_time_zone( $self->_get_cached_tz($tz) );
        }
        else {
            warn sprintf '%s had null timezone (%s): using UTC',
              $info->{__dbic_colname}, $tz_src;
        }
    }

    return $dt;
}

sub _pre_deflate_datetime {
    my ( $self, $dt, $info ) = @_;

    if ( my $tz_src = $info->{timezone_source} ) {
        $self->set_column( $tz_src, $dt->time_zone->name );
    }

    if ( !$ENV{DBIC_IC_DT_WTZ_MODIFY_TZ} ) {
        $dt = $dt->clone;
    }

    $dt = $self->next::method( $dt, $info );

    return $dt;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::InflateColumn::DateTime::WithTimeZone - Store time zones with DateTimes in database

=head1 SYNOPSIS

Set up table with separate column to store time zone, and set that column as
the timezone_source column for the datetime column.

  package Event;
  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components(qw/InflateColumn::DateTime::WithTimeZone/);

  __PACKAGE_->add_columns(
      event_time => { data_type => 'timestamp', timezone_source => 'event_tz' },
      event_tz   => { data_type => 'varchar', size => 38 },
  );

Store any DateTime into the database

  $dt = DateTime->new( year => 2015, month => 6, day => 8, hour => 9, minute => 10
      time_zone => 'America/Chicago' );

  $row = $schema->resultset('Event')->create( { event_time => $dt } );

In the database, event_time is now set to the UTC time corresponding to the
original time (2015-06-08T14:10:00), and event_tz is set to 'America/Chicago'.

When retrieved from the database, event_time will be returned as an identical
DateTime object, with the same time zone as the original DateTime

  $row = $schema->resultset('Event')->first;

  $event_time = $row->event_time;

  say $event_time . '';                # 2015-06-08T09:10:00

  say $event_time->time_zone->name;    # America/Chicago

=head1 DESCRIPTION

This component preserves the time zone of DateTime objects when
storing and retrieving through DBIx::Class.

It uses InflateColumn::DateTime to do the basic inflation and
deflation. The time zone is saved into an additional database
column, and automatically applied to the DateTime after
inflation.

=head2 UTC-only

The datetime is always converted to UTC before storage in the
database. This ensures that the real time is preserved, no
matter how the clock time is affected by the time zone.

This avoids the problems caused by Daylight Saving Time.
If the datetime were stored in any time zone that has Daylight
Saving Time, then any datetime that occurs during the
transition out of Daylight Saving Time (when the clock goes
back one hour) will be ambiguous. DateTime handles this by
always using the latest real time for the given clock time
(see L<DateTime#Ambiguous-Local-Times>). In this case,
any DateTime from the earlier pass through the overlapped times
will be converted to the later time when it is read, effectively
adding the DST offset to the time.

=head1 USAGE NOTES

=head2 Interaction with InflateColumn::DateTime

=over

=item Side effects on DateTime object

Currently, if the timezone attribute is set on InflateColumn::DateTime, then
the time zone on a DateTime object used to set the column may have its time
zone changed to that of the timezone attribute. The time zone change only
happens if the DateTime object is deflated for storage.
See L<https://rt.cpan.org/Public/Bug/Display.html?id=105154>.

By default, this component overrides this IC::DT behavior. The DateTime
object used to set the column will not have its time zone changed.

If you need this side effect, set the DBIC_IC_DT_WTZ_MODIFY_TZ environment
variable, and the IC::DT behavior will be followed: any DateTime used to
set the column value will have its time zone set to UTC if it has been
deflated for storage in the database.

=item timezone

The timezone attribute is defaulted to UTC. If a non-UTC timezone
is specified, an exception will be thrown, since non-UTC time zones
can not guarantee that the retrieved DateTime matches the saved
DateTime.

=item locale

The locale attribute is not affected by this component, so it
should work as documented in InflateColumn::DateTime.

=back

=head2 Interaction with TimeStamp

All columns using the TimeStamp plugin will default to using the UTC
time zone for all time stamps. To use a different time zone, override
the get_timestamp method and set the desired time zone there.

=head2 Nullable columns

If the datetime column is nullable, the timezone_source column must also
be nullable. If it is not, a exception will be thrown when the schema is
loaded.

=head2 Missing timezone column

If a datetime column with a timezone_source is included in a ResultSet,
the corresponding timezone_source column must also be included.

If the timezone_source column is missing, a runtime exception will be
thrown when the datetime column is accessed.

=head2 Timezone column size

The time zone column must be long enough to store the longest
zoneinfo name. Currently, that's 38 characters, but I can't find
any guarantee that will not change.

This component does not yet validate the timezone column data type
or size. This may result in database exceptions if the time zone
length is greater than the timezone_source column length.

=head2 Implementation Details

This component uses internal methods and data from
L<DBIx::Class::InflateColumn::DateTime>:

=head3 _ic_dt_method

Uses the $info->{_ic_dt_method} value set by InflateColumn::DateTime
to determine the column datatype, rather than duplicating the
detection code.

=head3 __dbic_colname

Uses the $info->{__dbic_colname} value set by InflateColumn::DateTime
to provide the column name in error messages.

=head3 register_columns

Wraps register_columns to validate the column attributes

=head3 _post_inflate_datetime

Sets time zone from the timezone_source column DateTime inflation

=head3 _pre_deflate_datetime

Sets timezone_source column to time zone name before DateTime deflation

=head1 TODO

=over

=item *

Expand the tests to validate against databases other than SQLite

=item *

Investigate and document interaction with locale

=item *

Add validation of the data_type and size of the timezone_source column

=item *

Investigate using SQL backend features (e.g., C<AT TIME ZONE>)

=back

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::Class::InflateColumn::DateTime>, L<DBIx::Class::InflateColumn>, L<DateTime>

=cut

package DBIx::QuickORM::Type::DateTime;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use DateTime();
use DateTime::Format::ISO8601();
use DateTime::Format::MySQL();
use DateTime::Format::Pg();
use Hash::Util::FieldHash qw/fieldhash/;
use Scalar::Util qw/blessed/;

use DBIx::QuickORM::Type::DateTime::Lazy();

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Type::DateTime - Date and timestamp fields as DateTime objects.

=head1 DESCRIPTION

Inflates date, timestamp (or datetime), and timestamp with time zone fields
into L<DateTime> objects, each wrapped in a
L<DBIx::QuickORM::Type::DateTime::Lazy> that builds the DateTime only when it
is used. Call DateTime methods on its C<datetime> (a copy to change) or
C<datetime_ref> (read only).

Dates and timestamps without a zone are floating wall clocks, kept as
stored. They inflate to floating DateTimes, unless the stored text carries an
offset (SQLite text such as C<2024-02-03T04:05:06Z>, read by
L<DateTime::Format::ISO8601>), which keeps that zone. A DateTime is written
as its own wall clock, whatever its zone: nothing converts them. A wall clock
the ORM's zone skips (a daylight saving gap) still works.X<banned-words-ok>

A timestamp with time zone keeps its offset both ways. PostgreSQL and DuckDB
store the instant, so it comes back in another offset, as the same instant. A
floating DateTime written to one is taken to be in the ORM's C<time_zone>.

On MySQL and MariaDB, C<TIMESTAMP> is the timestamp with time zone: the
server stores the instant and reads and writes it in the session zone, the
ORM's C<time_zone>. A DateTime is converted to that zone when written, and a
value comes back in it. C<DATETIME> is the one without a zone.

A MySQL or MariaDB C<TIMESTAMP> in the hour a daylight saving zone repeats
(clocks set back) is ambiguous: the session zone cannot say which of the two
instants it is, so it may read back an hour off. For exact instants keep the
ORM's C<time_zone> at its default, C<UTC>, and convert for display with
C<< $value->datetime->set_time_zone($zone) >>.

L<DateTime::Format::MySQL> 0.08 silently ignores an offset after fractional
seconds: C<'2024-02-03 15:05:06.12-07:00'> reads as 15:05:06.12 with no zone.
Pass such a value (a primary key given as text, say) as a DateTime, or without
the fraction. This is reported upstream.

C<time> and C<interval> fields are left alone: a MySQL C<TIME> is a duration,
not a time of day.

Only a DateTime (a lazy value counts) is deflated. A plain string is sent as
given, so it must already be in a form the database accepts.

Values are parsed and formatted by the Format classes the dialect names (see
C<datetime_format> in L<DBIx::QuickORM::Dialect>): L<DateTime::Format::Pg> on
PostgreSQL and DuckDB, L<DateTime::Format::MySQL> on MySQL and MariaDB.

Text the dialect's parser cannot read goes to L<DateTime::Format::ISO8601>,
then to the ORM's C<datetime_parsers> in order. The first DateTime wins. Text
none of them reads croaks when the DateTime is built.

On SQLite, values are parsed by L<DateTime::Format::Pg> and written by this
type as C<YYYY-MM-DD HH:MM:SS.fraction+HH:MM>. The fraction appears only when
there is one, and the offset only for a timestamp with time zone. SQLite's
date functions need the colon in the offset. SQLite stores whatever is sent,
and its C<CURRENT_TIMESTAMP> is in UTC whatever the ORM's zone.

=head1 SYNOPSIS

    use DateTime;

    my $ann = $orm->insert(
        users => {
            name    => 'Ann',
            created => DateTime->new(
                year  => 2024,
                month => 2,
                day   => 3,
            ),
        },
    );

    my $when = $ann->field('created');             # date and timestamp fields are typed by default
    my $year = $when->datetime_ref->year;          # 2024
    my $next = $when->datetime->add(days => 1);    # a copy, so $when is unchanged
    $ann->update({created => $next});

=head1 PUBLIC METHODS

=over 4

=item @types = $type->base_types

C<date>, C<datetime>, C<timestamp>, C<timestamptz>, C<timestamp without time
zone>, and C<timestamp with time zone>.

=item $bool = $type->is_inflated($value)

True for a DateTime, including a lazy value. A lazy value is not parsed to
answer.

=item $bool = $type->inflated_is_immutable_for_cache

True: nothing changes a lazy value, and its C<datetime> is a copy.

=back

=cut

sub base_types                      { ('date', 'datetime', 'timestamp', 'timestamptz', 'timestamp without time zone', 'timestamp with time zone') }
sub is_inflated                     { blessed($_[1]) && ($_[1]->isa('DateTime') || $_[1]->isa('DBIx::QuickORM::Type::DateTime::Lazy')) ? 1 : 0 }
sub inflated_is_immutable_for_cache { 1 }

=pod

=over 4

=item $lazy = $type->inflate($raw, \%field, $conn)

A L<DBIx::QuickORM::Type::DateTime::Lazy> over the raw string.

=back

=cut

sub inflate {
    my $class = shift;
    my ($raw, $field, $conn) = @_;

    my ($parser, undef, $kind) = $class->_facts($field, $conn);
    my $extra = $conn->datetime_parsers;
    my $zone  = $class->_zone($kind, $conn);

    return DBIx::QuickORM::Type::DateTime::Lazy->new(
        sub { $class->_parse($parser, $extra, $kind, $raw, $zone, $field) },
        $kind,
    );
}

=pod

=over 4

=item $raw = $type->deflate($datetime, \%field, $conn)

The DateTime formatted for the field. A date keeps only its date.

Croaks for anything but a DateTime.

=back

=cut

sub deflate {
    my $class = shift;
    my ($value, $field, $conn) = @_;
    $value = $class->_unwrap($value);
    croak "Expected a DateTime object" . $class->_for_field($field) . ", got '$value'" unless blessed($value) && $value->isa('DateTime');
    my (undef, $formatter, $kind) = $class->_facts($field, $conn);
    return $class->_format($formatter, $kind, $value, $class->_zone($kind, $conn));
}

=pod

=over 4

=item $key = $type->canonical_key_value($value, \%field, $conn)

The key form of a value given as database text or as a DateTime (a lazy
value counts). Database text is parsed as C<inflate> parses it.

=over 4

=item *

A timestamp with time zone gives its UTC instant: C<YYYY-MM-DDTHH:MM:SS.nnnnnnnnnZ>.

=item *

A timestamp without one gives its wall clock as it is, the same without the
C<Z>.

=item *

A date gives C<YYYY-MM-DD>.

=back

A date or timestamp given as a DateTime with a zone gives its own wall clock,
as C<deflate> writes it.

The fraction always has nine digits, the nanoseconds a DateTime holds.

A DateTime finer than the column stores is not the key of the stored, rounded
value. Nor is one whose fraction has a leading zero on DuckDB: DBD::DuckDB
prints 500 microseconds as C<.500>, which reads back as another instant.

=back

=cut

sub canonical_key_value {
    my $class = shift;
    my ($value, $field, $conn) = @_;

    my ($parser, undef, $kind) = $class->_facts($field, $conn);
    my $zone = $class->_zone($kind, $conn);

    my $dt = $class->_unwrap($value);
    $dt = $class->_parse($parser, $conn->datetime_parsers, $kind, $value, $zone, $field) unless $class->is_inflated($dt);
    if (defined $zone) {
        $dt = $dt->clone;
        $dt->set_time_zone($zone) if $dt->time_zone->is_floating;
        $dt->set_time_zone('UTC');
    }
    return $dt->ymd if $kind eq 'date';
    return $dt->ymd . 'T' . $dt->hms . sprintf('.%09d', $dt->nanosecond) . (defined($zone) ? 'Z' : '');
}

=head1 PRIVATE METHODS

=over 4

=item $value = $type->_unwrap($value)

A lazy value's DateTime (its C<datetime_ref>), or any other value as given.

=back

=cut

sub _unwrap {
    my $class = shift;
    my ($value) = @_;
    return blessed($value) && $value->isa('DBIx::QuickORM::Type::DateTime::Lazy') ? $value->datetime_ref : $value;
}

=pod

=over 4

=item ($parser, $formatter, $kind) = $type->_facts(\%field, $conn)

The dialect's C<datetime_format> parser and formatter, and the field's
C<_kind>. Worked out on the first use for a field and dialect, then cached
per field record.

=back

=cut

# Keyed by field record: [$dialect, $parser, $formatter, $kind].
fieldhash my %FACTS;

sub _facts {
    my $class = shift;
    my ($field, $conn) = @_;

    my $dialect = $conn->dialect;
    my $facts   = $FACTS{$field};
    return @{$facts}[1 .. 3] if $facts && $facts->[0] == $dialect;

    my ($parser, $formatter, $instants) = $dialect->datetime_format;
    $FACTS{$field} = [$dialect, $parser, $formatter, $class->_kind($field, $instants)];
    return @{$FACTS{$field}}[1 .. 3];
}

=pod

=over 4

=item $kind = $type->_kind(\%field, \%instants)


C<date>, C<timestamptz>, or C<timestamp>. A base type in C<%instants> (the
dialect's, from C<datetime_format>) is a C<timestamptz>.

=back

=cut

sub _kind {
    my $class = shift;
    my ($field, $instants) = @_;
    my $type = $field->{type} // '';
    return 'date'        if $type eq 'date';
    return 'timestamptz' if $type eq 'timestamptz' || $type =~ m/with time zone$/ || ($instants && $instants->{$type});
    return 'timestamp';
}

=pod

=over 4

=item $zone = $type->_zone($kind, $conn)

The zone a value of this kind is put in when it has none: the ORM's
C<time_zone> for a timestamp with time zone. Undef for a date or timestamp,
which stay floating, their wall clock as given.

=back

=cut

sub _zone {
    my $class = shift;
    my ($kind, $conn) = @_;
    return $kind eq 'timestamptz' ? $conn->time_zone : undef;
}

=pod

=over 4

=item $dt = $type->_parse($parser, \@parsers, $kind, $raw, $zone, \%field)

The DateTime for a raw value. One without a zone of its own is put in
C<$zone>, keeping its wall clock. An undef C<$zone> leaves it floating.

Tries the dialect's C<$parser>, then L<DateTime::Format::ISO8601>, then each
of C<@parsers> (the ORM's C<datetime_parsers>). A parser fails by returning
undef or dying. The first DateTime wins, and the caller's C<$@> is left
alone. Croaks when one returns anything else, and when none reads the text,
naming the field when C<%field> has its C<table> and C<name>.

C<parse_datetime> stands in for any method the dialect's parser lacks
(L<DateTime::Format::MySQL> has no C<parse_timestamptz>).

=back

=cut

sub _parse {
    my $class = shift;
    my ($parser, $extra, $kind, $raw, $zone, $field) = @_;

    local $@;
    my $method = $parser->can("parse_$kind") ? "parse_$kind" : 'parse_datetime';
    my @tries  = (
        sub { $parser->$method($_[0]) },
        sub { DateTime::Format::ISO8601->parse_datetime($_[0]) },
        map {
            my $p = $_;
            ref($p) eq 'CODE' ? $p : sub { $p->parse_datetime($_[0]) }
        } @$extra,
    );

    for my $try (@tries) {
        # Failing is how a parser says the text is not its format. The next one gets it.
        my $dt = eval { $try->($raw) } // next;
        croak "A datetime parser returned '$dt' for '$raw'" . $class->_for_field($field) . ", not a DateTime" unless blessed($dt) && $dt->isa('DateTime');
        $dt->set_time_zone($zone) if defined($zone) && $dt->time_zone->is_floating;
        return $dt;
    }

    croak "Cannot parse '$raw' as a $kind" . $class->_for_field($field) . ": add a parser that reads it to the ORM's datetime_parsers, or leave the field untyped with types => {\$table => {\$field => undef}}";
}

=pod

=over 4

=item $raw = $type->_format($formatter, $kind, $dt, $zone)

The database form of a DateTime, its wall clock as it is. A floating one is
put in C<$zone> first, when C<$zone> is defined.

C<format_datetime> stands in for a method the formatter lacks. It writes no
offset, so a C<timestamptz> is then converted to C<$zone>, the session's zone
(L<DateTime::Format::MySQL> has no C<format_timestamptz>). An undef
C<$formatter> means C<_format_own>.

=back

=cut

sub _format {
    my $class = shift;
    my ($formatter, $kind, $dt, $zone) = @_;

    $dt = $dt->clone;
    $dt->set_time_zone($zone) if defined($zone) && $dt->time_zone->is_floating;
    return $class->_format_own($kind, $dt) unless $formatter;

    my $method = "format_$kind";
    return $formatter->$method($dt) if $formatter->can($method);
    $dt->set_time_zone($zone)       if $kind eq 'timestamptz';
    return $formatter->format_datetime($dt);
}

=pod

=over 4

=item $raw = $type->_format_own($kind, $dt)

This type's own form of a DateTime already in its zone, used for SQLite.

=back

=cut

sub _format_own {
    my $class = shift;
    my ($kind, $dt) = @_;
    return $dt->ymd if $kind eq 'date';

    my $out = $dt->ymd . ' ' . $dt->hms;
    $out .= sprintf('.%09d', $dt->nanosecond) =~ s/0+$//r          if $dt->nanosecond;
    $out .= DateTime::TimeZone->offset_as_string($dt->offset, ':') if $kind eq 'timestamptz';
    return $out;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut

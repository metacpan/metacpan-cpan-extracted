package DateTimeX::Lite::TimeZone;
use strict;
use warnings;

use Carp ();
use DateTimeX::Lite::TimeZone::Catalog;
use DateTimeX::Lite::TimeZone::Floating;
use DateTimeX::Lite::TimeZone::Local;
use DateTimeX::Lite::TimeZone::OffsetOnly;
use DateTimeX::Lite::TimeZone::UTC;
use DateTimeX::Lite::OlsonDB;
use File::ShareDir qw(dist_file);

our %CachedTimeZones;

# the offsets for each span element
use constant UTC_START   => 0;
use constant UTC_END     => 1;
use constant LOCAL_START => 2;
use constant LOCAL_END   => 3;
use constant OFFSET      => 4;
use constant IS_DST      => 5;
use constant SHORT_NAME  => 6;

my %SpecialName = map { $_ => 1 } qw( EST MST HST CET EET MET WET EST5EDT CST6CDT MST7MDT PST8PDT );

sub load {
    my ($class, %p) = @_;

    my $name = $p{name};
    my $conf;
    my $zone;
    if (defined $name) {
        my $links = \%DateTimeX::Lite::TimeZone::Catalog::LINKS;
        if ( exists $links->{ $name } ) {
            $name = $links->{ $name };
        } elsif ( exists $links->{ uc $name } ) {
            $name = $links->{ uc $name };
        }
    }

    if (defined $name) {
        return $CachedTimeZones{$name} if $CachedTimeZones{$name};
        unless ( $name =~ m,/, || $SpecialName{ $name }) {
            if ( $name eq 'floating' ) {
                return $CachedTimeZones{$name} = DateTimeX::Lite::TimeZone::Floating->new;
            }
            if ( $name eq 'local' ) {
                return $CachedTimeZones{$name} = DateTimeX::Lite::TimeZone::Local->TimeZone();
            }
    
            if ( $name eq 'UTC' || $name eq 'Z' ) {
                return $CachedTimeZones{$name} = DateTimeX::Lite::TimeZone::UTC->new;
            }

            return $CachedTimeZones{$name} = DateTimeX::Lite::TimeZone::OffsetOnly->new( offset => $name );
        }
        $conf = _load_time_zone($name);
    }

    if (! $conf) {
        my $x = $ENV{DATETIMEX_LITE_DEBUG} ? \&Carp::confess : \&Carp::croak ;
        $x->( "The timezone '" . ($p{name} || 'undef') . "' could not be loaded, or is an invalid name.\n" );
    }

    $zone = $class->new(%$conf);

    if ( $zone->is_olson() ) {
        my $object_version =
            $zone->can('olson_version')
            ? $zone->olson_version()
            : 'unknown';
        my $catalog_version = DateTimeX::Lite::TimeZone::Catalog->OlsonVersion();

        if ( $object_version ne $catalog_version )
        {
            warn "Loaded $name, which is from an older version ($object_version) of the Olson database than this installation of DateTimeX::Lite::TimeZone ($catalog_version).\n";
        }
    }

    $CachedTimeZones{$name} = $zone;
    return $zone;
}

sub new { my $class = shift; bless { @_ }, $class }

sub _load_time_zone {
    my $name = shift;
    my $file = "$name.dat";
    $file =~ s/-/_/g;

    # Quietly fail here, so we can let the proceeding section croak for us
    eval {
        $file = dist_file( 'DateTimeX-Lite', "DateTimeX/Lite/TimeZone/$file");
    };
    return $file ? do $file : ();
}

sub rules { $_[0]->{rules} }
sub max_year { $_[0]->{max_year} }
sub last_offset { $_[0]->{last_offset} }
sub last_observance { $_[0]->{last_observance} }

sub is_olson { $_[0]->{is_olson} }

sub is_dst_for_datetime
{
    my $self = shift;

    my $span = $self->_span_for_datetime( 'utc', $_[0] );

    return $span->[IS_DST];
}

sub offset_for_datetime
{
    my $self = shift;

    my $span = $self->_span_for_datetime( 'utc', $_[0] );

    return $span->[OFFSET];
}

sub offset_for_local_datetime
{
    my $self = shift;

    my $span = $self->_span_for_datetime( 'local', $_[0] );

    return $span->[OFFSET];
}

sub short_name_for_datetime
{
    my $self = shift;

    my $span = $self->_span_for_datetime( 'utc', $_[0] );

    return $span->[SHORT_NAME];
}

sub _span_for_datetime
{
    my $self = shift;
    my $type = shift;
    my $dt   = shift;

    my $method = $type . '_rd_as_seconds';

    my $end = $type eq 'utc' ? UTC_END : LOCAL_END;

    my $span;
    my $seconds = $dt->$method();
    if ( $seconds < $self->max_span->[$end] )
    {
        $span = $self->_spans_binary_search( $type, $seconds );
    }
    else
    {
        my $until_year = $dt->utc_year + 1;
        $span = $self->_generate_spans_until_match( $until_year, $seconds, $type );
    }

    # This means someone gave a local time that doesn't exist
    # (like during a transition into savings time)
    unless ( defined $span )
    {
        my $err = 'Invalid local time for date';
        $err .= ' ' . $dt->iso8601 if $type eq 'utc';
        $err .= " in time zone: " . $self->name;
        $err .= "\n";

        die $err;
    }

    return $span;
}

sub _spans_binary_search
{
    my $self = shift;
    my ( $type, $seconds ) = @_;

    my ( $start, $end ) = _keys_for_type($type);

    my $min = 0;
    my $max = scalar @{ $self->{spans} } + 1;
    my $i = int( $max / 2 );
    # special case for when there are only 2 spans
    $i++ if $max % 2 && $max != 3;

    $i = 0 if @{ $self->{spans} } == 1;

    while (1)
    {
        my $current = $self->{spans}[$i];
        if ( $seconds < $current->[$start] )
        {
            $max = $i;
            my $c = int( ( $i - $min ) / 2 );
            $c ||= 1;

            $i -= $c;

            return if $i < $min;
        }
        elsif ( $seconds >= $current->[$end] )
        {
            $min = $i;
            my $c = int( ( $max - $i ) / 2 );
            $c ||= 1;

            $i += $c;

            return if $i >= $max;
        }
        else
        {
            # Special case for overlapping ranges because of DST and
            # other weirdness (like Alaska's change when bought from
            # Russia by the US).  Always prefer latest span.
            if ( $current->[IS_DST] && $type eq 'local' )
            {
                my $next = $self->{spans}[$i + 1];
                # Sometimes we will get here and the span we're
                # looking at is the last that's been generated so far.
                # We need to try to generate one more or else we run
                # out.
                $next ||= $self->_generate_next_span;

                die "No next span in $self->{max_year}" unless defined $next;

                if ( ( ! $next->[IS_DST] )
                     && $next->[$start] <= $seconds
                     && $seconds        <= $next->[$end]
                   )
                {
                    return $next;
                }
            }

            return $current;
        }
    }
}

sub _generate_next_span
{
    my $self = shift;

    my $last_idx = $#{ $self->{spans} };

    my $max_span = $self->max_span;

    # Kind of a hack, but AFAIK there are no zones where it takes
    # _more_ than a year for a _future_ time zone change to occur, so
    # by looking two years out we can ensure that we will find at
    # least one more span.  Of course, I will no doubt be proved wrong
    # and this will cause errors.
    $self->_generate_spans_until_match
        ( $self->{max_year} + 2, $max_span->[UTC_END] + ( 366 * 86400 ), 'utc' );

    return $self->{spans}[ $last_idx + 1 ];
}

sub _generate_spans_until_match
{
    my $self = shift;
    my $generate_until_year = shift;
    my $seconds = shift;
    my $type = shift;

    my @changes;
    my @rules = @{ $self->rules };
    foreach my $year ( $self->max_year .. $generate_until_year )
    {
        for ( my $x = 0; $x < @rules; $x++ )
        {
            my $last_offset_from_std;

            if ( @rules == 2 )
            {
                $last_offset_from_std =
                    $x ? $rules[0]->offset_from_std : $rules[1]->offset_from_std;
            }
            elsif ( @rules == 1 )
            {
                $last_offset_from_std = $rules[0]->offset_from_std;
            }
            else
            {
                my $count = scalar @rules;
                die "Cannot generate future changes for zone with $count infinite rules\n";
            }

            my $rule = $rules[$x];

            my $next =
                $rule->utc_start_datetime_for_year
                    ( $year, $self->last_offset, $last_offset_from_std );

            # don't bother with changes we've seen already
            next if $next->utc_rd_as_seconds < $self->max_span->[UTC_END];

            my $last_observance = $self->last_observance;
            push @changes,
                DateTimeX::Lite::OlsonDB::Change->new
                    ( type => 'rule',
                      utc_start_datetime   => $next,
                      local_start_datetime =>
                      $next +
                      DateTimeX::Lite::Duration->new
                          ( seconds => $last_observance->total_offset +
                                       $rule->offset_from_std ),
                      short_name =>
                      sprintf( $last_observance->format, $rule->letter ),
                      observance => $last_observance,
                      rule       => $rule,
                    );
        }
    }

    $self->{max_year} = $generate_until_year;

    my @sorted = sort { $a->utc_start_datetime <=> $b->utc_start_datetime } @changes;

    my ( $start, $end ) = _keys_for_type($type);

    my $match;
    for ( my $x = 1; $x < @sorted; $x++ )
    {
        my $last_total_offset =
            $x == 1 ? $self->max_span->[OFFSET] : $sorted[ $x - 2 ]->total_offset;

        my $span =
            DateTimeX::Lite::OlsonDB::Change::two_changes_as_span
                ( @sorted[ $x - 1, $x ], $last_total_offset );

        $span = _span_as_array($span);

        push @{ $self->{spans} }, $span;

        $match = $span
            if $seconds >= $span->[$start] && $seconds < $span->[$end];
    }

    return $match;
}

sub max_span { $_[0]->{spans}[-1] }

sub _keys_for_type
{
    $_[0] eq 'utc' ? ( UTC_START, UTC_END ) : ( LOCAL_START, LOCAL_END );
}

sub _span_as_array
{
    [ @{ $_[0] }{ qw( utc_start utc_end local_start local_end offset is_dst short_name ) } ];
}

sub is_floating { 0 }

sub is_utc { 0 }

sub has_dst_changes { $_[0]->{has_dst_changes} }

sub name      { $_[0]->{name} }
sub category  { (split /\//, $_[0]->{name}, 2)[0] }

sub is_valid_name
{
    my $tz;
    {
        local $@;
        $tz = eval { $_[0]->load( name => $_[1] ) };
    }

    return $tz && $tz->isa('DateTimeX::Lite::TimeZone') ? 1 : 0
}

#
# Functions
#
sub offset_as_seconds {
    {
        local $@;
        shift if eval { $_[0]->isa('DateTimeX::Lite::TimeZone') };
    }
    DateTimeX::Lite::Util::offset_as_seconds(@_);
}

sub offset_as_string {
    {
        local $@;
        shift if eval { $_[0]->isa('DateTimeX::Lite::TimeZone') };
    }
    DateTimeX::Lite::Util::offset_as_string(@_);
}

# These methods all operate on data contained in the DateTime/TimeZone/Catalog.pm file.

sub all_names {
    return wantarray ? @DateTimeX::Lite::TimeZone::Catalog::ALL : [@DateTimeX::Lite::TimeZone::Catalog::ALL];
}

sub categories {
    return wantarray
        ? @DateTimeX::Lite::TimeZone::Catalog::CATEGORY_NAMES
        : [@DateTimeX::Lite::TimeZone::Catalog::CATEGORY_NAMES];
}

sub links
{
    return
        wantarray ? %DateTimeX::Lite::TimeZone::Catalog::LINKS : {%DateTimeX::Lite::TimeZone::Catalog::LINKS};
}

sub names_in_category
{
    shift if $_[0]->isa('DateTimeX::Lite::TimeZone');
    return unless exists $DateTimeX::Lite::TimeZone::Catalog::CATEGORIES{ $_[0] };

    return
        wantarray
        ? @{ $DateTimeX::Lite::TimeZone::Catalog::CATEGORIES{ $_[0] } }
        : [ $DateTimeX::Lite::TimeZone::Catalog::CATEGORIES{ $_[0] } ];
}

sub countries
{
    wantarray
        ? ( sort keys %DateTimeX::Lite::TimeZone::Catalog::ZONES_BY_COUNTRY )
        : [ sort keys %DateTimeX::Lite::TimeZone::Catalog::ZONES_BY_COUNTRY ];
}

sub names_in_country
{
    shift if $_[0]->isa('DateTimeX::Lite::TimeZone');

    return unless exists $DateTimeX::Lite::TimeZone::Catalog::ZONES_BY_COUNTRY{ lc $_[0] };

    return
        wantarray
        ? @{ $DateTimeX::Lite::TimeZone::Catalog::ZONES_BY_COUNTRY{ lc $_[0] } }
        : $DateTimeX::Lite::TimeZone::Catalog::ZONES_BY_COUNTRY{ lc $_[0] };
}

1;

__END__

=head1 NAME

DateTimeX::Lite::TimeZone - Time zone object base class and factory

=head1 SYNOPSIS

  use DateTimeX::Lite;
  use DateTimeX::Lite::TimeZone;

  my $tz = DateTimeX::Lite::TimeZone->new( name => 'America/Chicago' );

  my $dt = DateTime->now();
  my $offset = $tz->offset_for_datetime($dt);

=head1 DESCRIPTION

This class is the base class for all time zone objects.  A time zone
is represented internally as a set of observances, each of which
describes the offset from GMT for a given time period.

Note that without the C<DateTime.pm> module, this module does not do
much.  It's primary interface is through a C<DateTime> object, and
most users will not need to directly use C<DateTimeX::Lite::TimeZone>
methods.

=head1 USAGE

This class has the following methods:

=head2 DateTimeX::Lite::TimeZone->new( name => $tz_name )

Given a valid time zone name, this method returns a new time zone
blessed into the appropriate subclass.  Subclasses are named for the
given time zone, so that the time zone "America/Chicago" is the
DateTimeX::Lite::TimeZone::America::Chicago class.

If the name given is a "link" name in the Olson database, the object
created may have a different name.  For example, there is a link from
the old "EST5EDT" name to "America/New_York".

When loading a time zone from the Olson database, the constructor
checks the version of the loaded class to make sure it matches the
version of the current DateTimeX::Lite::TimeZone installation. If they do not
match it will issue a warning. This is useful because time zone names
may fall out of use, but you may have an old module file installed for
that time zone.

There are also several special values that can be given as names.

If the "name" parameter is "floating", then a
C<DateTimeX::Lite::TimeZone::Floating> object is returned.  A floating time
zone does have I<any> offset, and is always the same time.  This is
useful for calendaring applications, which may need to specify that a
given event happens at the same I<local> time, regardless of where it
occurs.  See RFC 2445 for more details.

If the "name" parameter is "UTC", then a C<DateTimeX::Lite::TimeZone::UTC>
object is returned.

If the "name" is an offset string, it is converted to a number, and a
C<DateTimeX::Lite::TimeZone::OffsetOnly> object is returned.

=head3 The "local" time zone

If the "name" parameter is "local", then the module attempts to
determine the local time zone for the system.

The method for finding the local zone varies by operating system. See
the appropriate module for details of how we check for the local time
zone.

=over 4

=item * L<DateTimeX::Lite::TimeZone::Local::Unix>

=item * L<DateTimeX::Lite::TimeZone::Local::Win32>

=item * L<DateTimeX::Lite::TimeZone::Local::VMS>

=back

If a local time zone is not found, then an exception will be thrown.

=head2 $tz->offset_for_datetime( $dt )

Given a C<DateTime> object, this method returns the offset in seconds
for the given datetime.  This takes into account historical time zone
information, as well as Daylight Saving Time.  The offset is
determined by looking at the object's UTC Rata Die days and seconds.

=head2 $tz->offset_for_local_datetime( $dt )

Given a C<DateTime> object, this method returns the offset in seconds
for the given datetime.  Unlike the previous method, this method uses
the local time's Rata Die days and seconds.  This should only be done
when the corresponding UTC time is not yet known, because local times
can be ambiguous due to Daylight Saving Time rules.

=head2 $tz->name

Returns the name of the time zone.  If this value is passed to the
C<new()> method, it is guaranteed to create the same object.

=head2 $tz->short_name_for_datetime( $dt )

Given a C<DateTime> object, this method returns the "short name" for
the current observance and rule this datetime is in.  These are names
like "EST", "GMT", etc.

It is B<strongly> recommended that you do not rely on these names for
anything other than display.  These names are not official, and many
of them are simply the invention of the Olson database maintainers.
Moreover, these names are not unique.  For example, there is an "EST"
at both -0500 and +1000/+1100.

=head2 $tz->is_floating

Returns a boolean indicating whether or not this object represents a
floating time zone, as defined by RFC 2445.

=head2 $tz->is_utc

Indicates whether or not this object represents the UTC (GMT) time
zone.

=head2 $tz->has_dst_changes

Indicates whether or not this zone has I<ever> had a change to and
from DST, either in the past or future.

=head2 $tz->is_olson

Returns true if the time zone is a named time zone from the Olson
database.

=head2 $tz->category

Returns the part of the time zone name before the first slash.  For
example, the "America/Chicago" time zone would return "America".

=head2 DateTimeX::Lite::TimeZone->is_valid_name($name)

Given a string, this method returns a boolean value indicating whether
or not the string is a valid time zone name.  If you are using
C<DateTimeX::Lite::TimeZone::Alias>, any aliases you've created will be valid.

=head2 DateTimeX::Lite::TimeZone->all_names

This returns a pre-sorted list of all the time zone names.  This list
does not include link names.  In scalar context, it returns an array
reference, while in list context it returns an array.

=head2 DateTimeX::Lite::TimeZone->categories

This returns a list of all time zone categories.  In scalar context,
it returns an array reference, while in list context it returns an
array.

=head2 DateTimeX::Lite::TimeZone->links

This returns a hash of all time zone links, where the keys are the
old, deprecated names, and the values are the new names.  In scalar
context, it returns a hash reference, while in list context it returns
a hash.

=head2 DateTimeX::Lite::TimeZone->names_in_category( $category )

Given a valid category, this method returns a list of the names in
that category, without the category portion.  So the list for the
"America" category would include the strings "Chicago",
"Kentucky/Monticello", and "New_York". In scalar context, it returns
an array reference, while in list context it returns an array.

The list is returned in order of population by zone, which should mean
that this order will be the best to use for most UIs.

=head2 DateTimeX::Lite::TimeZone->countries()

Returns a sorted list of all the valid country codes (in lower-case)
which can be passed to C<names_in_country()>. In scalar context, it
returns an array reference, while in list context it returns an array.

If you need to convert country codes to names or vice versa you can
use C<Locale::Country> to do so.

=head2 DateTimeX::Lite::TimeZone->names_in_country( $country_code )

Given a two-letter ISO3066 country code, this method returns a list of
time zones used in that country. The country code may be of any
case. In scalar context, it returns an array reference, while in list
context it returns an array.

=head2 DateTimeX::Lite::TimeZone->offset_as_seconds( $offset )

Given an offset as a string, this returns the number of seconds
represented by the offset as a positive or negative number.  Returns
C<undef> if $offset is not in the range C<-99:59:59> to C<+99:59:59>.

The offset is expected to match either
C</^([\+\-])?(\d\d?):(\d\d)(?::(\d\d))?$/> or
C</^([\+\-])?(\d\d)(\d\d)(\d\d)?$/>.  If it doesn't match either of
these, C<undef> will be returned.

This means that if you want to specify hours as a single digit, then
each element of the offset must be separated by a colon (:).

=head2 DateTimeX::Lite::TimeZone->offset_as_string( $offset )

Given an offset as a number, this returns the offset as a string.
Returns C<undef> if $offset is not in the range C<-359999> to C<359999>.

=head2 Storable Hooks

This module provides freeze and thaw hooks for C<Storable> so that the
huge data structures for Olson time zones are not actually stored in
the serialized structure.

If you subclass C<DateTimeX::Lite::TimeZone>, you will inherit its hooks,
which may not work for your module, so please test the interaction of
your module with Storable.

=head1 AUTHOR

=over 4

=item Original DateTime.pm:

Copyright (c) 2003-2008 David Rolsky C<< <autarch@urth.org> >>. All rights reserved.  
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=item DateTimeX::Lite tweaks

Daisuke Maki C<< <daisuke@endeworks.jp> >>
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=back

=cut
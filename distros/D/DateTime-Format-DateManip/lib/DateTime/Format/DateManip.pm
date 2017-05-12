package DateTime::Format::DateManip;

use strict;

use vars qw ($VERSION);

$VERSION = '0.04';

use Carp;

use DateTime;
use DateTime::Duration;

use Date::Manip;


# All formats are in the ASCII range so we can safely turn off UTF8 support
use bytes;

# This takes a Date::Manip string and converts it to a DateTime object
# Note that the Date::Manip string just needs to be something that 
# Date::Manip::ParseDate() can format.
# undef is returned if the string can not be converted.
sub parse_datetime {
    my ($class, $dm_date) = @_;
    croak "Missing DateManip parseable string" unless defined $dm_date;

    # Get the timezone name and the date information and zome offset from
    # the Date::Manip string.
    my ($dm_tz, @bits) = UnixDate($dm_date, qw( %Z %Y %m %d %H %M %S %z ));
    return undef unless @bits;
    my @args = merge_lists([qw( year month day hour minute second time_zone )],
			   \@bits);

    # Construct the DateTime object and use the offset timezone    
    my $dt = DateTime->new(@args);

    # See if there is a better timezone to use
    my $dt_tz = $class->get_dt_timezone($dm_tz);

    # Apply the final time zone
    if (defined $dt_tz) {
	$dt->set_time_zone($dt_tz);
    }

    return $dt;
}

# Takes a DateTime object and returns the corresponding Date::Manip string (in 
# the format returned by ParseDate)
sub format_datetime {
    my ($class, $dt) = @_;
    croak "Missing DateTime object" unless defined $dt;

    # Note that we just use the TZ offset since Date::Manip doesn't
    # store time zone information with the dates but sets it system wide
    return ParseDate( $dt->strftime("%Y%m%dT%H%M%S %z") );
}

# Takes a Date::Manip Delta string and returns the corresponding
# DateTime::Duration object or undef
sub parse_duration {
    my ($class, $dm_delta) = @_;
    croak "Missing DateManip parseable delta string" unless defined $dm_delta;

    my @bits = Delta_Format($dm_delta, 0, qw( %yv %Mv %wv %dv %hv %mv %sv ));
    return undef unless @bits;
    my @args = merge_lists([qw( years months weeks days hours minutes seconds )],
			   \@bits);
    
    # We have to do this in two phases since Date::Manip handles the sign
    # for years and months separately from the sign for the rest.
    # DateTime::Duration assumes that the sign is the same across all
    # items so we make the inital duration with years and months and add
    # the second duration (which may be negative) to finish the duration
    my $dt_dur = DateTime::Duration->new(@args[0..3]); # Year and month
    $dt_dur->add(@args[4..13]);                        # The rest

    return $dt_dur;
}

# Takes a DateTime::Duration object and returns the corresponding
# Date::Manip Delta string (in the format returned by ParseDateDelta)
sub format_duration {
    my ($class, $dt_dur) = @_;
    croak "Missing DateTime::Duration object" unless defined $dt_dur;

    # Not all elements are defined (if they can be derived from smaller elements)
    my %bits = $dt_dur->deltas();
    my $str = join(":",
	       0, # Years
	       $bits{months},
	       0, # Weeks
	       $bits{days},
	       0, # Hours
	       $bits{minutes},
	       $bits{seconds},
	       );
    my $dm_dur = ParseDateDelta($str);
    
    return $dm_dur;
}


BEGIN {
    # Date::Manip to DateTime timezone mapping (where possible)
    my %TZ_MAP =
	(
	 # Abbreviations (see http://www.worldtimezone.com/wtz-names/timezonenames.html)
	 # [1] - YST matches worldtimezone.com but not Canada/Yukon
	 # [2] - AT  matches worldtimezone.com but not Atlantic/Azores
	 # [3] - City chosen at random from similar matches
	 idlw   => "-1200",                # International Date Line West (-1200)
	 nt     => "-1100",                # Nome (-1100) (obs. -1967)
	 hst    => "US/Hawaii",            # Hawaii Standard (-1000)
	 cat    => "-1000",                # Central Alaska (-1000) (obs. -1967)
	 ahst   => "-1000",                # Alaska-Hawaii Standard (-1000) (obs. 1967-1983)
	 akst   => "US/Alaska",            # Alaska Standard (-0900)
	 yst    => "-0900",                # Yukon Standard (-0900) [1]
	 hdt    => "-0900",                # Hawaii Daylight (-0900) (until 1947?)
	 akdt   => "US/Alaska",            # Alaska Daylight (-0800)
	 ydt    => "-0800",                # Yukon Daylight (-0900) [1]
	 pst    => "US/Pacific",           # Pacific Standard (-0800)
	 pdt    => "US/Pacific",           # Pacific Daylight (-0700)
	 mst    => "US/Mountain",          # Mountain Standard (-0700)
	 mdt    => "US/Mountain",          # Mountain Daylight (-0600)
	 cst    => "US/Central",           # Central Standard (-0600)
	 cdt    => "US/Central",           # Central Daylight (-0500)
	 est    => "US/Eastern",           # Eastern Standard (-0500)
	 sat    => "-0400",                # Chile (-0400)
	 edt    => "US/Eastern",           # Eastern Daylight (-0400)
	 ast    => "Canada/Atlantic",      # Atlantic Standard (-0400)
	 #nst   => "Canada/Newfoundland",  # Newfoundland Standard (-0300)     nst=North Sumatra    +0630
	 nft    => "Canada/Newfoundland",  # Newfoundland (-0330)
	 #gst   => "-0300",  # Greenland Standard (-0300)        gst=Guam Standard    +1000
	 #bst   => "Brazil/East",          # Brazil Standard (-0300)           bst=British Summer   +0100
	 adt    => "Canada/Atlantic",      # Atlantic Daylight (-0300)
	 ndt    => "Canada/Newfoundland",  # Newfoundland Daylight (-0230)
	 at     => "-0200",                # Azores (-0200) [2]
	 wat    => "Africa/Bangui",        # West Africa (-0100) [3]
	 gmt    => "Europe/London",        # Greenwich Mean (+0000)
	 ut     => "Etc/Universal",        # Universal (+0000)
	 utc    => "UTC",                  # Universal (Coordinated) (+0000)
	 wet    => "Europe/Lisbon",        # Western European (+0000) [3]
	 west   => "Europe/Lisbon",        # Alias for Western European (+0000) [3]
	 cet    => "Europe/Madrid",        # Central European (+0100)
	 fwt    => "Europe/Paris",         # French Winter (+0100)
	 met    => "Europe/Brussels",      # Middle European (+0100)
	 mez    => "Europe/Berlin",        # Middle European (+0100)
	 mewt   => "Europe/Brussels",      # Middle European Winter (+0100)
	 swt    => "Europe/Stockholm",     # Swedish Winter (+0100)
	 bst    => "Europe/London",        # British Summer (+0100)             bst=Brazil standard  -0300
	 gb     => "Europe/London",        # GMT with daylight savings (+0100)
	 eet    => "Europe/Bucharest",     # Eastern Europe, USSR Zone 1 (+0200)
	 cest   => "Europe/Madrid",        # Central European Summer (+0200)
	 fst    => "Europe/Paris",         # French Summer (+0200)
#     ist    => "Asia/Jerusalem",       # Israel standard (+0200) (duplicate of Indian)
	 mest   => "Europe/Brussels",      # Middle European Summer (+0200)
	 mesz   => "Europe/Berlin",        # Middle European Summer (+0200)
	 metdst => "Europe/Brussels",      # An alias for mest used by HP-UX (+0200)
	 sast   => "Africa/Johannesburg",  # South African Standard (+0200)
	 sst    => "Europe/Stockholm",     # Swedish Summer (+0200)             sst=South Sumatra    +0700
	 bt     => "+0300",                # Baghdad, USSR Zone 2 (+0300)
	 eest   => "Europe/Bucharest",     # Eastern Europe Summer (+0300)
	 eetedt => "Europe/Bucharest",     # Eastern Europe, USSR Zone 1 (+0300)
#     idt    => "Asia/Jerusalem",       # Israel Daylight (+0300) [Jerusalem doesn't honor DST)
	 msk    => "Europe/Moscow",        # Moscow (+0300)
	 it     => "Asia/Tehran",          # Iran (+0330)
	 zp4    => "+0400",                # USSR Zone 3 (+0400)
	 msd    => "Europe/Moscow",        # Moscow Daylight (+0400)
	 zp5    => "+0500",                # USSR Zone 4 (+0500)
	 ist    => "Asia/Calcutta",        # Indian Standard (+0530)
	 zp6    => "+0600",                # USSR Zone 5 (+0600)
	 nst    => "+0630",                # North Sumatra (+0630)             nst=Newfoundland Std -0330
	 #sst   => "+0700",  # South Sumatra, USSR Zone 6 sst=Swedish Summer   +0200
	 hkt    => "Asia/Hong_Kong",       # Hong Kong (+0800)
	 sgt    => "Asia/Singapore",       # Singapore  (+0800)
	 cct    => "Asia/Shanghai",        # China Coast, USSR Zone 7 (+0800)
	 awst   => "Australia/West",       # West Australian Standard (+0800)
	 wst    => "Australia/West",       # West Australian Standard (+0800)
	 pht    => "Asia/Manila",          # Asia Manila (+0800)
	 kst    => "Asia/Seoul",           # Republic of Korea (+0900)
	 jst    => "Asia/Tokyo",           # Japan Standard, USSR Zone 8 (+0900)
	 rok    => "ROK",                  # Republic of Korea (+0900)
	 cast   => "Australia/South",      # Central Australian Standard (+0930)
	 east   => "Australia/Victoria",   # Eastern Australian Standard (+1000)
	 gst    => "Pacific/Guam",         # Guam Standard, USSR Zone 9 gst=Greenland Std    -0300
	 cadt   => "Australia/South",      # Central Australian Daylight (+1030)
	 eadt   => "Australia/Victoria",   # Eastern Australian Daylight (+1100)
	 idle   => "+1200",                # International Date Line East
	 nzst   => "Pacific/Auckland",     # New Zealand Standard
	 nzt    => "Pacific/Auckland",     # New Zealand
	 nzdt   => "Pacific/Auckland",     # New Zealand Daylight
	 
	 # US Military Zones
	 z      => "+0000",
	 a      => "+0100",
	 b      => "+0200",
	 c      => "+0300",
	 d      => "+0400",
	 e      => "+0500",
	 f      => "+0600",
	 g      => "+0700",
	 h      => "+0800",
	 i      => "+0900",
	 k      => "+1000",
	 l      => "+1100",
	 m      => "+1200",
	 n      => "-0100",
	 o      => "-0200",
	 p      => "-0300",
	 q      => "-0400",
	 r      => "-0500",
	 s      => "-0600",
	 t      => "-0700",
	 u      => "-0800",
	 v      => "-0900",
	 w      => "-1000",
	 x      => "-1100",
	 y      => "-1200",
	 );

# Return the DateTime timezone corresponding to the given Date::Manip timezone or 
# return undef if there is no match.
sub get_dt_timezone {
    my ($class, $dm_tz) = @_;

    # Work out the time zone that Date::Manip was using and try to reproduce it 
    # in DateTime   
    my $dt_tz = $dm_tz;
    if ($dm_tz =~ m{/}) {
	# Don't change it since it is in the complete form already
	# (e.g. America/New_York)
    }
    elsif ($dm_tz =~ m/^[-+]\d+$/) {
	# It is an offset, leave it alone (e.g. -0500)
    }
    else {
	# Look it up
	my $lc_tz = lc $dm_tz;
	$dt_tz = $TZ_MAP{$lc_tz};
    }

    return $dt_tz;
}
}

# Take a list of keys and a list of values and insersperse them and
# return the result
sub merge_lists {
    my ($keys, $values) = @_;
    die "Length mismatch" unless @$keys == @$values;
    
    # Add the argument names to the values
    my @result;
    for (my $i = 0; $i < @$keys; $i++) {
	push @result, $keys->[$i] => $values->[$i];
    }
    
    return @result;
}

1;


__END__

=head1 NAME

DateTime::Format::DateManip - Perl DateTime extension to convert
Date::Manip dates and durations to DateTimes and vice versa.

=head1 SYNOPSIS

  use Date::Manip;
  use DateTime::Format::DateManip;

  # Date::Manip to DateTime
  my $dm = ParseDate("January 1st, 2001");
  my $dt = DateTime::Format::DateManip->parse_datetime($dm);

  $dt->add( weeks => 1 );  

  # And back again
  my $dm2 = DateTime::Format::DateManip->format_datetime($dt);

  # Same thing with a duration
  my $dm_delta  = ParseDateDelta("3 years 2 days -4 hours +3mn -2 second");
  my $dt_dur    = DateTime::Format::DateManip->parse_duration($dm_delta);
  my $dm_delta2 = DateTime::Format::DateManip->format_duration($dt_dur);

  # Note that we can parse any string that is in the appropriate format
  # there is no need to call ParseDate or ParseDateDelta first:
  my $dt2     = DateTime::Format::DateManip->parse_datetime("In 2 hours");
  my $dt_dur2 = DateTime::Format::DateManip->parse_duration("3 years");

=head1 DESCRIPTION

DateTime::Format::DateManip is a class that knows how to convert
between C<Date::Manip> dates and durations and C<DateTime> and
C<DateTime::Duration> objects.  Recurrences are note yet supported.

=head1 USAGE

=head2 Time Zones

C<Date::Manip> can have a time zone set globally and it keeps the
dates it produces in the local time.  In all cases we rely on the GMT
offset to set up the C<DateTime> object.  However, we try to work out
what the matching timezone is using the C<DateTime> nomenclature and
create the object in the correct time zone so the date is correct if
dajustments to the date object pushes it over a DST change.  Note that
we call C<set_time_zone> to make the change, so the absolute time is
not affected by the time zone change.

However, not all C<Date::Manip> time zones have reasonable mappings
(for example NT and CAT both appear to be obsolete).  It is unlikely
that a user will have their time zone set to one of these items.  If
we are unable to work out the mapping we simply use the GMT offset and
do not set a timezone.

When converting to a C<Date::Manip> we only need to tell
C<Date::Manip> the GMT offset and it will automatically convert to the
local time zone that is in effect.


=head2 Class Methods

=over 4

=item * parse_datetime( $date_manip_string )

This method takes the input string and returns the corresponding
C<DateTime> object.  If C<Date::Manip::ParseDate> was unable to parse
the input string then undef will be returned.  See the note above
about Time Zones.

=item * format_datetime( $datetime_object )

This method takes the given C<DateTime> object and returns a
corresponding C<Date::Manip::ParseDate> parseable string.  See the
note above about Time Zones.

=item * parse_duration( $date_manip_duration_string )

This method takes the giben duration string and returns the
corresponding C<DateTime::Duration> object.  If
C<Date::Manip::ParseDateDelta> was unable to parse the input string
then undef will be returned.

=item * format_duration( $datetime_duration_object )

This method takes the given C<DateTime::Duration> object and returns a
corresponding C<Date::Manip::ParseDateDelta> parseable string.

=back

=head1 AUTHOR

Ben Bennett <fiji at limey dot net>

=head1 COPYRIGHT

Copyright (c) 2003 Ben Bennett.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

Portions of the code in this distribution are derived from other
works.  Please see the CREDITS file for more details.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

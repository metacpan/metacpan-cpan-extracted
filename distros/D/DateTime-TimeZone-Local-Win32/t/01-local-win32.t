use strict;
use warnings;

use constant {
    DT_TZ_MIN => 2.16,
    SECONDS_PER_HOUR => 60 * 60,
    MINUTES_PER_HOUR => 60,
};

use Test::More 0.88;

eval {
    require DateTime;
    require DateTime::TimeZone::Local;
    require DateTime::TimeZone::Local::Win32;
};
if ($@) {
    plan skip_all =>
        'These tests run only when DateTime and DateTime::TimeZone are present.';
}
use File::Basename qw( basename );
use File::Spec;
use Sys::Hostname qw( hostname );

use lib File::Spec->catdir( File::Spec->curdir, 't' );

my $Registry;

use Win32::TieRegistry 0.27 ( TiedRef => \$Registry, Delimiter => q{/} );

my $tzi_key = $Registry->Open(
    'LMachine/SYSTEM/CurrentControlSet/Control/TimeZoneInformation/', {
        Access => Win32::TieRegistry::KEY_READ()
            | Win32::TieRegistry::KEY_WRITE()
    }
);

my ($registry_writable, $minimum_DT_TZ);
if ($tzi_key)
{
    $registry_writable = 1;
}
else
{
    $registry_writable = 0;
}
if ( $DateTime::TimeZone::Local::VERSION >= DT_TZ_MIN )
{
    $minimum_DT_TZ = 1;
}

my $WindowsTZKey;

{
    foreach my $win_tz_name ( windows_tz_names() ) {
        SKIP: {
            unless ( $ENV{'AUTOMATED_TESTING'} ) {
                skip (
                    "$win_tz_name - Set and test Windows time zone (Automated only)",
                    4
                );
            }
            set_and_test_windows_tz( $win_tz_name, undef, $tzi_key, $registry_writable );
        }
    }

    my $denver_time_zone_with_newlines = join( '', "Mountain Standard Time", map { chr } qw(  0 10 0 0 0 0 0 0
        82 0 0 0 63 32 0 0 63 120 0 0 32 0 0 0 72 0 0 0 64 116 122 114 101 115
        46 100 108 108 44 45 49 57 50 0 0 0 0 0 1 0 0 0 63 13 0 0 63 63 63 0 63
        13 0 0 1 0 0 0 64 116 122 114 101 115 46 100 108 108 44 45 49 57 49 0 72
        0 0 0 0 0 0 0 63 120 0 0 213 63 63 0 0 0 0 0 0 ) );

    # We test these explicitly because we want to make sure that at
    # least a few known names do work, rather than just relying on
    # looping through a list.
    foreach my $pair (
        [ 'Eastern Standard Time',  'America/New_York' ],
        [ 'Dateline Standard Time', '-1200' ],
        [ 'Israel Standard Time',   'Asia/Jerusalem' ],
        ) {
        set_and_test_windows_tz( @{$pair}, $tzi_key, $registry_writable );
    }
    set_and_test_windows_tz( $denver_time_zone_with_newlines, 'America/Denver', $tzi_key, $registry_writable );
}

done_testing();

sub get_dt_by_week_and_day {
    my $year = shift;
    my $month = shift;
    my $day_of_week = shift || 7; # Windows representation of Sunday is 0 while DateTime is 7
    my $week = shift;
    my $hour = shift;
    my $minute = shift;
    my $second = shift;
    my $millisecond = shift;
    my $time_zone = shift;

    my $dt = DateTime->last_day_of_month(
        time_zone => $time_zone,
        year => $year,
        month => $month,
        hour => 12 # setting to noon local time to avoid any time invalid times (will be updated later in this subroutine)
    );

    my $day = $dt->day();
    if ( ( my $date_difference = abs( 7 - abs( $dt->day_of_week() - $day_of_week ) ) ) < 7 ) {
        $day -= $date_difference;
    }

    if ( $week != 5 ) {
        use integer;
        $day = $day - (( $day / 7 ) - ( 0 + ( $day % 7 == 0 ))) * 7 + ( $week - 1 ) * 7;
    }

    eval {
        $dt->set(
            day => $day,
            hour => $hour,
            minute => $minute,
            second => $second,
            nanosecond => $millisecond * 1000
        );
    };
    if ($@ =~ /^Invalid local time/) {
        $hour++;

        $dt->set(
            day => $day,
            hour => $hour,
            minute => $minute,
            second => $second,
            nanosecond => $millisecond * 1000
        );
    }

    return $dt;
}

sub get_windows_timezone_offsets {
    my $dt = shift;
    my $feb_dt = shift;
    my $aug_dt = shift;
    my $windows_tz_info = shift;

    # Daylight Savings Time not configured for this time zone
    if ( $windows_tz_info->{'standardMonth'} == 0 ) {
        return (
            $windows_tz_info->{'bias'} * -1,
            $windows_tz_info->{'bias'} * -1,
            $windows_tz_info->{'bias'} * -1
        );
    }

    my @offsets;

    foreach my $date ( $dt, $feb_dt, $aug_dt ) {

        # standard time
        my $standard_date = get_dt_by_week_and_day(
            $date->year(),
            $windows_tz_info->{'standardMonth'},
            $windows_tz_info->{'standardDayOfWeek'},
            $windows_tz_info->{'standardWeekOfMonth'},
            $windows_tz_info->{'standardHour'},
            $windows_tz_info->{'standardMinute'},
            $windows_tz_info->{'standardSecond'},
            $windows_tz_info->{'standardMilliseconds'},
            $date->time_zone_long_name(),
        );

        # daylight time
        my $daylight_date = get_dt_by_week_and_day(
            $date->year(),
            $windows_tz_info->{'daylightMonth'},
            $windows_tz_info->{'daylightDayOfWeek'},
            $windows_tz_info->{'daylightWeekOfMonth'},
            $windows_tz_info->{'daylightHour'},
            $windows_tz_info->{'daylightMinute'},
            $windows_tz_info->{'daylightSecond'},
            $windows_tz_info->{'daylightMilliseconds'},
            $date->time_zone_long_name(),
        );

        my $bias = $windows_tz_info->{'bias'};
        if ( DateTime->compare( $standard_date, $daylight_date ) < 0 ) {
            if (
                    ( DateTime->compare( $standard_date, $date ) <= 0 )
                    && ( DateTime->compare( $date, $daylight_date ) < 0 )
                ) {
                $bias += $windows_tz_info->{'standardBias'};
            }
            else {
                $bias += $windows_tz_info->{'daylightBias'};
            }
        }
        else {
            if (
                    ( DateTime->compare( $daylight_date, $date ) <= 0 )
                    && ( DateTime->compare( $date, $standard_date ) < 0 )
                ) {
                $bias += $windows_tz_info->{'daylightBias'};
            }
            else {
                $bias += $windows_tz_info->{'standardBias'};
            }
        }
        $bias *= -1;
        push @offsets, $bias;
    }

    return @offsets;
}

sub windows_tz_names {
    $WindowsTZKey = $Registry->Open(
        'LMachine/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Time Zones/',
        { Access => Win32::TieRegistry::KEY_READ() }
    );

    $WindowsTZKey ||= $Registry->Open(
        'LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Time Zones/',
        { Access => Win32::TieRegistry::KEY_READ() }
    );

    return unless $WindowsTZKey;

    return $WindowsTZKey->SubKeyNames();
}

sub set_and_test_windows_tz {
    my $windows_tz_name = shift;
    my $iana_name      = shift;
    my $tzi_key         = shift;
    my $registry_writable = shift;

    if ($registry_writable)
    {
        if (   defined $tzi_key
            && defined $tzi_key->{'/TimeZoneKeyName'}
            && $tzi_key->{'/TimeZoneKeyName'} ne '' ) {
            local $tzi_key->{'/TimeZoneKeyName'} = $windows_tz_name;

            test_windows_zone( $windows_tz_name, $iana_name, $registry_writable );
        }
        else {
            local $tzi_key->{'/StandardName'} = (
                  $WindowsTZKey->{ $windows_tz_name . q{/} }
                ? $WindowsTZKey->{ $windows_tz_name . '/Std' }
                : 'MAKE BELIEVE VALUE'
            );

            test_windows_zone( $windows_tz_name, $iana_name, $registry_writable );
        }
    }
    else
    {
        test_windows_zone( $windows_tz_name, $iana_name, $registry_writable );
    }
}

sub test_windows_zone {
    my $windows_tz_name = shift;
    my $iana_name      = shift;
    my $registry_writable = shift;
    my %KnownBad = map { $_ => 1 } ( 'Samoa Standard Time', 'Central Asia Standard Time' );


    my $tz;
    if ( $registry_writable && $minimum_DT_TZ ) {
        $tz = DateTime::TimeZone::Local::Win32->FromRegistry();

        ok(
            $tz && DateTime::TimeZone->is_valid_name( $tz->name() ),
            "$windows_tz_name - found valid IANA time zone '" .
            DateTime::TimeZone::Local::Win32->_FindWindowsTZName() . "' from Windows"
        );
    }
    else {
        my $tz_name = DateTime::TimeZone::Local::Win32->_WindowsToIANA( $windows_tz_name );
        ok (
            defined $tz_name,
            "$windows_tz_name - found time zone '" . $windows_tz_name . "' from Hash"
        );
    }

    if ( defined $iana_name ) {
        my $desc = "$windows_tz_name was mapped to $iana_name";
        if ( $registry_writable && $tz && $minimum_DT_TZ ) {
            is( $tz->name(), $iana_name, "$desc (Registry)" );
        }
        elsif ( $registry_writable && $minimum_DT_TZ ) {
            fail("$desc (Registry)");
        }
        else {
            my $tz_name = DateTime::TimeZone::Local::Win32->_WindowsToIANA( $windows_tz_name );
            is ( $tz_name, $iana_name, "$desc (Hash)" );
        }
    }
    else {
        SKIP: {
            unless ( $ENV{'AUTHOR_TESTING'} && $registry_writable ) {
                skip (
                    "$windows_tz_name - Windows offset matches IANA offset (Maintainer only)",
                    3
                );
            }
            if ( !$tz || !DateTime::TimeZone->is_valid_name( $tz->name() ) ) {
                skip (
                    "Time Zone display for $windows_tz_name not testable",
                    3
                );
            }
            my $dt = DateTime->now(
                time_zone => $tz->name(),
            );

            # typical times always Winter or Summer time depending on hemisphere if daylight savings in use
            # and attempting to avoid Ramadan as Morocco suspends daylight savings during Ramadan
            my $feb_dt = DateTime->new(
                time_zone => $tz->name(),
                year => $dt->year(),
                month => 2,
                day => 1,
            );
            my $aug_dt = DateTime->new(
                time_zone => $tz->name(),
                year => $dt->year(),
                month => 8,
                day => 1,
            );

            # Windows time zone offsets are defined in a structure defined here and offsets are in minutes):
            #     https://msdn.microsoft.com/en-us/library/windows/desktop/ms725481(v=vs.85).aspx
            my $windows_tz_info = {};
            @{$windows_tz_info}{
                    'bias',
                    'standardBias',
                    'daylightBias',
                    'standardYear',
                    'standardMonth',
                    'standardDayOfWeek',
                    'standardWeekOfMonth',
                    'standardHour',
                    'standardMinute',
                    'standardSecond',
                    'standardMilliseconds',
                    'daylightYear',
                    'daylightMonth',
                    'daylightDayOfWeek',
                    'daylightWeekOfMonth',
                    'daylightHour',
                    'daylightMinute',
                    'daylightSecond',
                    'daylightMilliseconds'
                } = unpack("lllvvvvvvvvvvvvvvvv", $WindowsTZKey->{"${windows_tz_name}/TZI"});

            my ($windows_offset, $windows_feb_offset, $windows_aug_offset) =
                get_windows_timezone_offsets( $dt, $feb_dt, $aug_dt, $windows_tz_info );

            # offsets in DateTime::TimeZone are in seconds
            my $dt_offset = $dt->offset();
            my $feb_dt_offset = $feb_dt->offset();
            my $aug_dt_offset = $aug_dt->offset();

            # convert offsets from seconds or minutes before or after UTC to hours
            $dt_offset /= SECONDS_PER_HOUR;
            $feb_dt_offset /= SECONDS_PER_HOUR;
            $aug_dt_offset /= SECONDS_PER_HOUR;
            $windows_offset /= MINUTES_PER_HOUR;
            $windows_feb_offset /= MINUTES_PER_HOUR;
            $windows_aug_offset /= MINUTES_PER_HOUR;

            if ( $KnownBad{$windows_tz_name} ) {
            TODO: {
                    local $TODO
                        = "Microsoft has some out-of-date time zones relative to IANA";

                    is(
                        $windows_offset, $dt_offset,
                        "$windows_tz_name - Windows offset matches IANA offset for current time"
                    );

                    is(
                        $windows_feb_offset, $feb_dt_offset,
                        "$windows_tz_name - Windows offset matches IANA offset for time set February 1"
                    );

                    is(
                        $windows_aug_offset, $aug_dt_offset,
                        "$windows_tz_name - Windows offset matches IANA offset for time set August 1"
                    );
                    return;
                }
            }
            elsif ( defined $WindowsTZKey->{"${windows_tz_name}/IsObsolete"}
                && $WindowsTZKey->{"${windows_tz_name}/IsObsolete"} eq
                "0x00000001" ) {
                skip (
                    "$windows_tz_name - deprecated by Microsoft",
                    3
                );
            }
            else {
                is(
                    $windows_offset, $dt_offset,
                    "$windows_tz_name - Windows offset matches IANA offset for current time"
                );

                is(
                    $windows_feb_offset, $feb_dt_offset,
                    "$windows_tz_name - Windows offset matches IANA offset for time set February 1"
                );

                is(
                    $windows_aug_offset, $aug_dt_offset,
                    "$windows_tz_name - Windows offset matches IANA offset for time set August 1"
                );
            }
        }
    }
}

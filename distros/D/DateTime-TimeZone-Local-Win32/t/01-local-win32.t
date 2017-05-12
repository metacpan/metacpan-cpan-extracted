use strict;
use warnings;

use constant {
    DT_TZ_MIN => 2.10,
    SECONDS_PER_MINUTE => 60,
    SECONDS_PER_HOUR => 60 * 60,
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
    my %KnownBad = map { $_ => 1 } ( );


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
                year => $dt->month() < 2? $dt->year() : $dt->year() + 1,
                month => 2,
                day => 1,
            );
            my $aug_dt = DateTime->new(
                time_zone => $tz->name(),
                year => $dt->month() < 8? $dt->year() : $dt->year() + 1,
                month => 8,
                day => 1,
            );

            my $dst_offset = abs($aug_dt->offset() - $feb_dt->offset());
            my $windows_offset
                = $WindowsTZKey->{"${windows_tz_name}/Display"};

            if ( $windows_offset =~ /^\((?:GMT|UTC)\).*$/ ) {
                $windows_offset = 0;
            }
            else {
                if ( my ($sign, $hours, $minutes) = ($windows_offset =~ /^\((?:GMT|UTC)([+-])(.*?):(.*?)\).*$/ ) ) {
                    $hours =~ s/^0//;
                    $minutes =~ s/^0//;
                    $windows_offset = ( $hours * SECONDS_PER_HOUR ) + ( $minutes * SECONDS_PER_MINUTE );
                    $windows_offset *= -1 if $sign eq '-';
                }
                else {
                    skip (
                        "Time Zone display for $windows_tz_name not testable",
                        3
                    );
                }
            }

            my $dt_offset = $dt->is_dst()? $dt->offset() - $dst_offset : $dt->offset();
            my $feb_dt_offset = $feb_dt->is_dst()? $feb_dt->offset() - $dst_offset : $feb_dt->offset();
            my $aug_dt_offset = $aug_dt->is_dst()? $aug_dt->offset() - $dst_offset : $aug_dt->offset();
            
            # convert offsets from seconds before or after UTC to hours
            $dt_offset /= SECONDS_PER_HOUR;
            $feb_dt_offset /= SECONDS_PER_HOUR;
            $aug_dt_offset /= SECONDS_PER_HOUR;
            $windows_offset /= SECONDS_PER_HOUR;

            if ( $KnownBad{$windows_tz_name} ) {
            TODO: {
                    local $TODO
                        = "Microsoft has some out-of-date time zones relative to IANA";

                    is(
                        $dt_offset, $windows_offset,
                        "$windows_tz_name - Windows offset matches IANA offset for time set now"
                    );

                    is(
                        $feb_dt_offset, $windows_offset,
                        "$windows_tz_name - Windows offset matches IANA offset for time set February 1"
                    );

                    is(
                        $aug_dt_offset, $windows_offset,
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
                    $dt_offset, $windows_offset,
                    "$windows_tz_name - Windows offset matches IANA offset for time set now"
                );

                is(
                    $feb_dt_offset, $windows_offset,
                    "$windows_tz_name - Windows offset matches IANA offset for time set January 1"
                );

                is(
                    $aug_dt_offset, $windows_offset,
                    "$windows_tz_name - Windows offset matches IANA offset for time set July 1"
                );
            }
        }
    }
}

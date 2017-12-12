package App::MonM::Notifier::Util; # $Id: Util.pm 37 2017-11-28 16:34:55Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Util - Utility tools

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Util;

=head1 DESCRIPTION

Utility tools

=head2 C<getExpireOffset>

    print getExpireOffset("+1d"); # 86400
    print getExpireOffset("-1d"); # -86400

Returns offset of expires time (in secs).

Original this function is the part of CGI::Util::expire_calc!

This internal routine creates an expires time exactly some number of hours from the current time.
It incorporates modifications from  Mark Fisher.

format for time can be in any of the forms:

    now   -- expire immediately
    +180s -- in 180 seconds
    +2m   -- in 2 minutes
    +12h  -- in 12 hours
    +1d   -- in 1 day
    +3M   -- in 3 months
    +2y   -- in 2 years
    -3m   -- 3 minutes ago(!)

If you don't supply one of these forms, we assume you are specifying the date yourself

=head2 C<calcPostponetPubDate>

    my $newpubdate = calcPostponetPubDate( $user_config_struct );

Returns new the "public date" value for record in database for user

=head2 C<checkLevel>

    my $status = checkLevel( $conf_level, $test_level );

This functions checks permissions to send a message by $test_level of the message

=head2 C<checkPubDate>

    my $status = checkPubDate( $user_config_struct );

Returns the sign (BOOL) of the permission to send a message (allowed or not allowed) by public date

=head2 C<getPeriods>

    my %periods = getPeriods( $user_config_struct );
    my %periods = getPeriods( $user_config_struct, $channel_name );

This function returns periods on everyday of week for all channels or only for specified

Format of the returned hash-structure:

    monday => [start_time, finish_time],

=head2 C<mysleep>

    mysleep( $secs );

This function do a delay in safety mode. See sleep Perl-function

=head2 C<trim>

    my $trimmed = trim( $text );

Trims the start and end of a line

=head2 C<tz_diff>

    print tz_diff( time );

Returns TimeZone difference value

=head2 C<is_ipv4>

    is_ipv4("127.0.0.1") ? "OK" : "NO";

Returns true or false if argument has not IPv4

=head2 C<resolve>

    my $name = resolve("127.0.0.1");
    my $ipv4 = resolve("localhost");

Returns IP/Hostname by Hostname/IP. See L<Sys::Net/resolv>

=head2 C<is_iso8601>

    is_iso8601("2017-11-28T10:12:14Z") ? "OK" : "NO";

Return true or false if argument has not ISO 8601

See L<http://www.w3.org/TR/NOTE-datetime>

=head2 C<time2iso>

    my $iso = time2iso( time() );

Converts time() fromat to ISO 8601 format

See L<http://www.w3.org/TR/NOTE-datetime>

=head2 C<iso2time>

    my $tm = time2iso( "2017-11-28T10:12:14Z" );

Converts Date and Time in ISO 8601 format to time() format

See L<http://www.w3.org/TR/NOTE-datetime>

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use constant {
        DAYS_OF_WEEK    => [qw/sunday monday tuesday wednesday thursday friday saturday/],
        DAYS_OF_WEEK_S  => [qw/sun mon tue wed thu fri sat/],
        OFFSET_START    => 0,          # 00:00
        OFFSET_FINISH   => 60*60*24-1, # 23:59
        SLEEP           => 60, # Default delay
    };

use base qw/Exporter/;

use Time::Local;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Carp; # carp - warn; croak - die;
use Time::Local qw//;
use App::MonM::Notifier::Const;
use Socket qw/inet_ntoa inet_aton AF_INET/;
use DateTime;
use DateTime::Format::W3CDTF;

use vars qw/$VERSION @EXPORT @EXPORT_OK/;
$VERSION = '1.00';

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = (qw/
        getExpireOffset
        calcPostponetPubDate
        checkPubDate
        getPeriods
        mysleep
        checkLevel
        trim
        tz_diff
        is_ipv4
        resolve
        is_iso8601 time2iso iso2time
    /);

# Other items we are prepared to export if requested
@EXPORT_OK = (qw/
        DAYS_OF_WEEK
        DAYS_OF_WEEK_S
    /, @EXPORT);

sub getExpireOffset {
    my $time  = shift;
    my %mult = (
            's' => 1,
            'm' => 60,
            'h' => 60*60,
            'd' => 60*60*24,
            'M' => 60*60*24*30,
            'y' => 60*60*24*365
        );
    if (!$time || (lc($time) eq 'now')) {
        return 0;
    } elsif ($time =~ /^\d+/) {
        return $time; # secs
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
        return ($mult{$2} || 1) * $1;
    }
    return $time;
}
sub calcPostponetPubDate {
    my %periods = getPeriods(@_);
    return unless %periods && keys %periods;

    my @dow = @{DAYS_OF_WEEK()};

    my $curtime = time();
    my $wday = (localtime($curtime))[6];

    my $start = $curtime + 7 * (OFFSET_FINISH + 1);
    for (my $i = 0; $i <= $#dow; $i++) {
        my $r = $periods{$dow[$i]};
        next unless is_array($r);
        my $chkstart = $r->[0];
        next unless defined $chkstart;

        if ($chkstart > $curtime and $chkstart < $start) {
            $start = $chkstart;
        }
        #$r->[2] = scalar(localtime($newtime + $roff + $r->[0]));
    }

    return $start;
}
sub checkPubDate {
    my %periods = getPeriods(@_);
    return 0 unless %periods && keys %periods;

    my @dow = @{DAYS_OF_WEEK()};

    my $curtime = time();
    my $wday = (localtime($curtime))[6];
    my ($start, $finish) = ($periods{$dow[$wday]}[0], $periods{$dow[$wday]}[1]);
    $finish += 59 if defined $finish;
    if ($start && ($curtime >= $start) && $finish && ($curtime <= $finish)) {
        #printf(">>> %s -> %s\n", scalar(localtime($start)), scalar(localtime($finish)));
        return 1;
    }
    return 0;
}
sub getPeriods { # Get periods as hash
    my $us = shift;
    my $channel = shift;

    return () unless is_hash($us) && keys %$us;
    my @dow = @{DAYS_OF_WEEK()};
    my @dows = @{DAYS_OF_WEEK_S()};
    my $n = $#dow;
    my %struct;
    my $channels = hash($us => "channel");
    my $period_global = value($us => "period") || "00:00-23:59";
    foreach my $chname (keys %$channels) {
        next if $channel && lc($chname) ne lc($channel);
        my $ch = hash($channels => $chname);
        next unless $ch && keys %$ch;
        next unless value($ch => "enable");
        #printf("%s\n", Dumper($ch));
        my $period_channel = value($ch => "period") || $period_global;
        for (my $i = 0; $i <= $n; $i++) {
            my ($s, $f) = _parsePeriod(value($ch => $dow[$i]) || value($ch => $dows[$i]) || $period_channel);
            next unless defined $s;
            #printf("%s> %s: %d - %d\n", $chname, $dow[$i], $s, $f);
            my $r = $struct{$dow[$i]};
            if ($r) {
                $struct{$dow[$i]}[0] = $s if $r->[0] && $r->[0] > $s;
                $struct{$dow[$i]}[1] = $f if $r->[1] && $r->[1] < $f;
            } else {
                $struct{$dow[$i]} = [$s, $f];
            }
        }
    }
    my $curtime = time();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($curtime);
    my $newtime = timelocal( 0, 0, 0, $mday, $mon, $year );

    for (my $i = 0; $i <= $n; $i++) {
        my $r = $struct{$dow[$i]};
        next unless is_array($r);
        my $j = $i-$wday; $j = 7 + $j if $j < 0; # Real offset index
        my $roff = $j * (OFFSET_FINISH + 1);
        $r->[0] = $newtime + $roff + $r->[0];
        $r->[1] = $newtime + $roff + $r->[1];
    }
    return %struct;
}
sub _parsePeriod {
    my $period = shift;
    #printf("%s\n", $period);
    return (undef,undef) unless defined $period;
    my $start = OFFSET_START;   # 00:00
    my $finish = OFFSET_FINISH; # 23:59
    if ($period =~ /^\-+$/) {
        return (undef,undef);
    } elsif ($period =~ /none|no|undef|off/i) {
        return (undef,undef);
    } elsif ($period =~ /(\d{1,2})\s*\:\s*(\d{1,2})\s*\-+\s*(\d{1,2})\s*\:\s*(\d{1,2})/) { # 00:00-23:59
        my ($sh,$sm,$fh,$fm) = ($1,$2,$3,$4);
        $start = $sh*60*60 + $sm*60;
        $finish = $fh*60*60 + $fm*60;
    } elsif ($period =~ /(\d{1,2})\s*\-+\s*(\d{1,2})\s*\:\s*(\d{1,2})/) { # 00-23:59
        my ($sh,$fh,$fm) = ($1,$2,$3);
        $start = $sh*60*60;
        $finish = $fh*60*60 + $fm*60;
    } elsif ($period =~ /(\d{1,2})\s*\-+\s*(\d{1,2})/) { # 00-23
        my ($sh,$fh,$fm) = ($1,$2,59);
        $start = $sh*60*60;
        $finish = $fh*60*60 + $fm*60;
    } else { # Errors
        return (undef,undef);
    }

    $start = OFFSET_START if $start < OFFSET_START or $start > OFFSET_FINISH;
    $finish = OFFSET_FINISH if $finish <= OFFSET_START or $finish > OFFSET_FINISH;
    return ($start, $finish);
}
sub mysleep {
    my $delay = shift || SLEEP;
    foreach (1..$delay) {
        sleep 1
    }
    return 1
}
sub checkLevel {
    my $cfg_level = trim(shift || ''); # Level or mask from configuration (chanal define)
    my $test = shift || 0; # Level from message-hash for testing (as integer value)
    return 0 unless is_int8($test);
    return 0 if ($test < 0) or ($test > 32);
    return 0 unless $cfg_level;

    # Level or Mask from config. Default - All
    my ($lvl,$msk) = ("","");
    my $priority_mask = 0;
    if ($cfg_level =~ /[^a-z]/i) {
        $msk = $cfg_level;
        $msk =~ s/^[^a-z]+//;
        $priority_mask = setPriorityMask($msk) if $msk;
    } elsif (lc($cfg_level) eq 'none') {
        return 0;
    } else {
        $lvl = $cfg_level;
        my %ls = %{(LEVELS)};
        return 0 unless exists($ls{$lvl});
        $priority_mask = getPriorityMask(getLevelByName(lc($lvl))) if $lvl;
    }
    $priority_mask = getPriorityMask unless ($lvl or $msk); # Default
    #printf("%010b [%d]\n", $priority_mask, $priority_mask);
    return getBit($priority_mask, $test);
}
sub trim {
    my $txt = shift;
    return $txt if !defined($txt);
    $txt =~ s/^\s+//;
    $txt =~ s/\s+$//;
    return $txt;
}
sub tz_diff {
    my $tm = shift || time;
    my $diff = Time::Local::timegm(localtime($tm)) - Time::Local::timegm(gmtime($tm));
    my $direc = $diff < 0 ? '-' : '+';
    $diff  = abs($diff);
    my $tz_hr = int( $diff / 3600 );
    my $tz_mi = int( $diff / 60 - $tz_hr * 60 );
    return sprintf("%s%02d%02d", $direc, $tz_hr, $tz_mi);
}
sub is_ipv4 {
    my $ip = shift;
    $ip =~ /^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/;
    foreach ($1,$2,$3,$4){
        next if $_ < 256 and $_ >= 0;
        return 0;
    }
    return 1;
}
sub resolve { # Resolving. See Socket::inet_ntoa
    # Original: Sys::Net::resolv
    my $name = shift;
    # resolv ip to a hostname
    if ($name =~ m/^\s*[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s*$/) {
        return scalar gethostbyaddr(inet_aton($name), AF_INET);
    }
    # resolv hostname to ip
    else {
        return inet_ntoa(scalar gethostbyname($name));
    }
}
sub is_iso8601 {
    my $t = shift;
    return 0 unless $t;
    return 1 if ($t =~ /^(\d\d\d\d) # Year
        (?:-(\d\d) # -Month
         (?:-(\d\d) # -Day
          (?:T
           (\d\d):(\d\d) # Hour:Minute
           (?:
              :(\d\d)     # :Second
              (\.\d+)?    # .Fractional_Second
           )?
           ( Z          # UTC
           | [+-]\d\d:\d\d    # Hour:Minute TZ offset
             (?::\d\d)?       # :Second TZ offset
           )?)?)?)?$/x);
    return 0;
}
sub time2iso { # Time to ISO 8601
    my $tm = shift || time;
    my $dt = DateTime->from_epoch( epoch => $tm );
    #my $iso = $dt->iso8601();
    my $w3c = DateTime::Format::W3CDTF->new;
    return $w3c->format_datetime($dt);
}
sub iso2time { # ISO 8601 to Time
    my $iso = shift || time2iso();
    my $w3c = DateTime::Format::W3CDTF->new;
    my $dt = $w3c->parse_datetime($iso);
    return $dt->epoch;
}


1;

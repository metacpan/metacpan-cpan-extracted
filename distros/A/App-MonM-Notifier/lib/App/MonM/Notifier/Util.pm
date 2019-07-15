package App::MonM::Notifier::Util; # $Id: Util.pm 59 2019-07-14 09:14:38Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Util - Utility tools

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Notifier::Util;

=head1 DESCRIPTION

Utility tools

=head2 checkPubDate

    my $status = checkPubDate( $user_config_struct, $channel_name );

Returns the sign (BOOL) of the permission to send a message (allowed or not allowed) by public date

=head2 getPeriods

    my %periods = getPeriods( $user_config_struct );
    my %periods = getPeriods( $user_config_struct, $channel_name );

This function returns periods on everyday of week for all channels or only for specified

Format of the returned hash-structure:

    monday => [start_time, finish_time],

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION @EXPORT @EXPORT_OK/;
$VERSION = '1.01';

use constant {
        DAYS_OF_WEEK    => [qw/sunday monday tuesday wednesday thursday friday saturday/],
        DAYS_OF_WEEK_S  => [qw/sun mon tue wed thu fri sat/],
        OFFSET_START    => 0,          # 00:00
        OFFSET_FINISH   => 60*60*24-1, # 23:59
    };

use base qw/Exporter/;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Carp; # carp - warn; croak - die;
use Time::Local;

use App::MonM::Notifier::Const;

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = (qw/
        checkPubDate
        getPeriods
    /);

# Other items we are prepared to export if requested
@EXPORT_OK = (qw/
        DAYS_OF_WEEK
        DAYS_OF_WEEK_S
    /, @EXPORT);

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

1;

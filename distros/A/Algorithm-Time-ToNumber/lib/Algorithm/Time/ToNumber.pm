package Algorithm::Time::ToNumber;

use 5.006;
use strict;
use warnings;
use Math::Trig qw(pi);
use Time::Piece;
use XSLoader;

=head1 NAME

Algorithm::Time::ToNumber - convert time to a number

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

XSLoader::load(__PACKAGE__, $VERSION);

=head1 SYNOPSIS

    use Algorithm::Time::ToNumber;

    print "---------------------------------------------------\n";
    print "------------------noon_fail------------------------\n";
    print "---------------------------------------------------\n";

    my $hour=0;
    while ($hour < 24) {
        my $time = $hour . ':00';
        print $time . ' ' . Algorithm::Time::ToNumber->noon_fail($time) . "\n";

        $time = $hour . ':30';
        print $time . ' ' . Algorithm::Time::ToNumber->noon_fail($time) . "\n";

        $hour++;
    }

    print "---------------------------------------------------\n";
    print "----------------midnight_fail----------------------\n";
    print "---------------------------------------------------\n";

    $hour=0;
    while ($hour < 24) {
        my $time = $hour . ':00';
        print $time . ' ' . Algorithm::Time::ToNumber->midnight_fail($time) . "\n";

        $time = $hour . ':30';
        print $time . ' ' . Algorithm::Time::ToNumber->midnight_fail($time) . "\n";

        $hour++;
    }

    print "---------------------------------------------------\n";
    print "---------------------circle------------------------\n";
    print "---------------------------------------------------\n";

    # this is what you want if you plan to use it with isolation forest

    $hour=0;
    while ($hour < 24) {
        my $time = $hour . ':00';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $time = $hour . ':30';
        ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $hour++;
    }

    print "---------------------------------------------------\n";
    print "----------------------angle------------------------\n";
    print "---------------------------------------------------\n";

    $hour=0;
    while ($hour < 24) {
        my $time = $hour . ':00';
        my ($sin_angle) = Algorithm::Time::ToNumber->circle($time);
        print $time . ' ' . $sin_angle . "\n";

        $time = $hour . ':30';
        ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->circle($time);
        print $time . ' ' . $sin_angle . "\n";

        $hour++;
    }

    print "---------------------------------------------------\n";
    print "--------------suricata_to_circle-------------------\n";
    print "---------------------------------------------------\n";

    $hour = 0;
    while ($hour < 24) {
        my $time = '2026-07-03T' .$hour . ':00:31.121465-0500';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $time = '2026-07-03T' .$hour . ':00:31.121465-0500';
        ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $hour++;
    }

    print "---------------------------------------------------\n";
    print "----------------circle_day-------------------------\n";
    print "---------------------------------------------------\n";

    my $day = 0;
    while ($day < 7) {
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->circle_day($day);
        print $day . ' ' . $sin_angle . ' ' . $cos_angle . "\n";
        $day++;
    }

    print "---------------------------------------------------\n";
    print "-----------------angle_day-------------------------\n";
    print "---------------------------------------------------\n";

    $day = 0;
    while ($day < 7) {
        my $sin_angle = Algorithm::Time::ToNumber->angle_day($day);
        print $day . ' ' . $sin_angle . "\n";
        $day++;
    }

    print "---------------------------------------------------\n";
    print "----------suricata_to_circle_day-------------------\n";
    print "---------------------------------------------------\n";

    $hour = 0;
    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle_day($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";
        $hour++;
    }

    print "---------------------------------------------------\n";
    print "----------suricata_to_angle_day--------------------\n";
    print "---------------------------------------------------\n";

    $hour = 0;
    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my $sin_angle = Algorithm::Time::ToNumber->suricata_to_angle_day($time);
        print $time . ' ' . $sin_angle . "\n";
        $hour++;
    }

    print "---------------------------------------------------\n";
    print "--------suricata_to_circle_both--------------------\n";
    print "---------------------------------------------------\n";

    $hour = 0;
    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle_both($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";
        $hour++;
    }

    print "---------------------------------------------------\n";
    print "---------suricata_to_angle_both--------------------\n";
    print "---------------------------------------------------\n";

    $hour = 0;
    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my $sin_angle = Algorithm::Time::ToNumber->suricata_to_angle_both($time);
        print $time . ' ' . $sin_angle . "\n";
        $hour++;
    }

=head1 SUBROUTINES

=head2 noon_fail

Wraps at 00:00. This will result in a gap at 12:00.

    my $hour=0;

    while ($hour < 24) {
        my $time = $hour . ':00';
        print $time . ' ' . Algorithm::Time::ToNumber->noon_fail($time) . "\n";

        $time = $hour . ':30';
        print $time . ' ' . Algorithm::Time::ToNumber->noon_fail($time) . "\n";

        $hour++;
    }

=cut

sub noon_fail {
    my ($class, $time) = @_;
    my ($h, $m, $s) = split(/:/, $time);
    $s //= 0;

    my $hours = $h + $m / 60 + $s / 3600;

    $hours -= 24 if $hours >= 12;

    return $hours;
}

=head2 midnight_fail

Wraps at 12:00. This will result in a gap at 00:00.

    my $hour=0;

    while ($hour < 24) {
        my $time = $hour . ':00';
        print $time . ' ' . Algorithm::Time::ToNumber->midnight_fail($time) . "\n";

        $time = $hour . ':30';
        print $time . ' ' . Algorithm::Time::ToNumber->midnight_fail($time) . "\n";

        $hour++;
    }

=cut

sub midnight_fail {
    my ($class, $time) = @_;

	my ($h, $m, $s) = split /:/, $time;
    $s //= 0;

    return $h + $m / 60 + $s / 3600;
}

=head2 circle

This returns two floats.

This is suitable for using with isolation forest. When using it with isolation
forest one needs to save both returns as their own feature.

    my $hour=0;

    while ($hour < 24) {
        my $time = $hour . ':00';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $time = $hour . ':30';
        ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $hour++;
    }

=cut

sub circle {
	my ($class, $time) = @_;

    my ($h, $m, $s) = split( /:/, $time);
    $s //= 0;

    my $angle = 2 * pi * ($h * 3600 + $m * 60 + $s) / 86400;

    return (sin($angle), cos($angle));
}

=head2 angle

This returns a continue number, but will result in points overlapping.

It is the same as circle, but does not take the time to compute cos.

    my $hour=0;

    while ($hour < 24) {
        my $time = $hour . ':00';
        my ($sin_angle) = Algorithm::Time::ToNumber->angle($time);
        print $time . ' ' . $sin_angle . "\n";

        $time = $hour . ':30';
        ($sin_angle) = Algorithm::Time::ToNumber->angle($time);
        print $time . ' ' . $sin_angle . "\n";

        $hour++;
    }

=cut

sub angle {
	my ($class, $time) = @_;
	
    my ($h, $m, $s) = split( /:/, $time);
    $s //= 0;

    my $angle = 2 * pi * ($h * 3600 + $m * 60 + $s) / 86400;

    return sin($angle);
}

=head2 suricata_to_circle

Convert .timestamp from Suricata EVE output to something that
circle can parse and return it.

    my $hour = 0;

    while ($hour < 24) {
        my $time = '2026-07-03T' .$hour . ':00:31.121465-0500';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $time = '2026-07-03T' .$hour . ':00:31.121465-0500';
        ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";

        $hour++;
    }

=cut

sub suricata_to_circle {
	my ($class, $time) = @_;

	$time =~ s/^.*T//;
	$time =~ s/\-.*$//;

	return Algorithm::Time::ToNumber->circle($time);
}

=head2 circle_day

Convert day of week to sin/cos values on a circle, suitable for use with
isolation forest. The day value should be 0 (Sunday) through 6 (Saturday),
matching the convention used by Perl's C<localtime>.

    my $day = 0;

    while ($day < 7) {
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->circle_day($day);
        print $day . ' ' . $sin_angle . ' ' . $cos_angle . "\n";
        $day++;
    }

=cut

sub circle_day {
	my ($class, $day) = @_;

	my $angle = 2 * pi * $day / 7;

	return (sin($angle), cos($angle));
}

=head2 angle_day

Like circle_day, but returns only the sin value.

    my $day = 0;

    while ($day < 7) {
        my $sin_angle = Algorithm::Time::ToNumber->angle_day($day);
        print $day . ' ' . $sin_angle . "\n";
        $day++;
    }

=cut

sub angle_day {
	my ($class, $day) = @_;

	my $angle = 2 * pi * $day / 7;

	return sin($angle);
}

=head2 suricata_to_circle_day

Convert .timestamp from Suricata EVE output to a circle_day value based on
the day of week.

    my $hour = 0;

    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle_day($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";
        $hour++;
    }

=cut

sub suricata_to_circle_day {
	my ($class, $time) = @_;

	my ($date) = $time =~ /^(\d{4}-\d{2}-\d{2})T/;

	my $t = Time::Piece->strptime($date, '%Y-%m-%d');

	return Algorithm::Time::ToNumber->circle_day($t->day_of_week);
}

=head2 suricata_to_angle_day

Convert .timestamp from Suricata EVE output to an angle_day value based on
the day of week.

    my $hour = 0;

    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my $sin_angle = Algorithm::Time::ToNumber->suricata_to_angle_day($time);
        print $time . ' ' . $sin_angle . "\n";
        $hour++;
    }

=cut

sub suricata_to_angle_day {
	my ($class, $time) = @_;

	my ($date) = $time =~ /^(\d{4}-\d{2}-\d{2})T/;

	my $t = Time::Piece->strptime($date, '%Y-%m-%d');

	return Algorithm::Time::ToNumber->angle_day($t->day_of_week);
}

=head2 suricata_to_circle_both

Convert .timestamp from Suricata EVE output to a sin/cos pair encoding both
the day of week and time of day as a single position within the week. The
week is treated as a 604800-second circle (7 days * 86400 seconds).

    my $hour = 0;

    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my ($sin_angle, $cos_angle) = Algorithm::Time::ToNumber->suricata_to_circle_both($time);
        print $time . ' ' . $sin_angle . ' ' . $cos_angle . "\n";
        $hour++;
    }

=cut


=head2 suricata_to_angle_both

Like suricata_to_circle_both, but returns only the sin value.

    my $hour = 0;

    while ($hour < 24) {
        my $time = '2026-07-03T' . $hour . ':00:31.121465-0500';
        my $sin_angle = Algorithm::Time::ToNumber->suricata_to_angle_both($time);
        print $time . ' ' . $sin_angle . "\n";
        $hour++;
    }

=cut


=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-time-tonumber at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Time-ToNumber>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Time::ToNumber


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Time-ToNumber>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Algorithm-Time-ToNumber>

=item * Search CPAN

L<https://metacpan.org/release/Algorithm-Time-ToNumber>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1; # End of Algorithm::Time::ToNumber

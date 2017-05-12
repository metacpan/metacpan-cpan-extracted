package DateTime::Format::Duration::ISO8601;

our $DATE = '2016-06-29'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub format_duration {
    my ($self, $dtdur) = @_;

    my ($y, $m, $w, $d, $H, $M, $S, $ns) = (
        $dtdur->years,
        $dtdur->months,
        $dtdur->weeks,
        $dtdur->days,
        $dtdur->hours,
        $dtdur->minutes,
        $dtdur->seconds,
        $dtdur->nanoseconds,
    );

    $S += $ns / 1_000_000_000;

    my $has_date = $y || $m || $w || $d;
    my $has_time = $H || $M || $S;

    return "PT0H0M0S" if !$has_date && !$has_time;

    join(
        "",
        "P",
        ($y, "Y") x !!$y,
        ($m, "M") x !!$m,
        ($w, "W") x !!$w,
        ($d, "D") x !!$d,
        (
            "T",
            ($H, "H") x !!$H,
            ($M, "M") x !!$M,
            ($S, "S") x !!$S,
        ) x !!$has_time,
    );
}

1;
# ABSTRACT: Format DateTime::Duration object as ISO8601 duration string

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Duration::ISO8601 - Format DateTime::Duration object as ISO8601 duration string

=head1 VERSION

This document describes version 0.002 of DateTime::Format::Duration::ISO8601 (from Perl distribution DateTime-Format-Duration-ISO8601), released on 2016-06-29.

=head1 SYNOPSIS

 use DateTime::Format::Duration::ISO8601;

 my $d = DateTime::Format::Duration::ISO8601->new;
 say $d->format_duration(
     DateTime::Duration->new(years=>3, months=>5, seconds=>10),
 ); # => P3Y5MT10S

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 format_duration($dur_obj) => str

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Format-Duration-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Format-Duration-ISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Duration-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Format::ISO8601> to format L<DateTime> object into ISO8601 date/time
string. At the time of this writing, there is no support to format
L<DateTime::Duration> object, hence this module.

L<DateTime::Format::Duration> to format DateTime::Duration object using
strftime-style formatting.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

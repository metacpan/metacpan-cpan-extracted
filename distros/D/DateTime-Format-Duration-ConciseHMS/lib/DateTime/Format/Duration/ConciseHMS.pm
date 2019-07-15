package DateTime::Format::Duration::ConciseHMS;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    return bless \%args, $class;
}

sub format_duration {
    my ($self, $dtdur) = @_;

    unless (eval { $dtdur->isa('DateTime::Duration') }) {
        die "'$dtdur' not a DateTime::Duration instance";
    }

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

    $d += $w * 7;

    my $has_date = $y || $m || $w || $d;
    my $has_time = $H || $M || $S;

    join(
        " ",
        ("${y}y") x !!$y,
        ("${m}mo") x !!$m,
        ("${d}d") x !!$d,
        (
            sprintf("%02d:%02d:%02d%s", $H, $M, $S,
                    $ns ? sprintf(".%03d", $ns/1e6) : "")
        ) x !!($has_time || !$has_date),

    );
}

1;
# ABSTRACT: Format DateTime::Duration object as concise HMS format

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Duration::ConciseHMS - Format DateTime::Duration object as concise HMS format

=head1 VERSION

This document describes version 0.001 of DateTime::Format::Duration::ConciseHMS (from Perl distribution DateTime-Format-Duration-ConciseHMS), released on 2019-06-19.

=head1 SYNOPSIS

 use DateTime::Format::Duration::ConciseHMS;

 my $format = DateTime::Format::Duration::ConciseHMS->new;
 say $format->format_duration(
     DateTime::Duration->new(years=>3, months=>5, seconds=>10),
 ); # => "3y 5mo 00:00:10"

=head1 DESCRIPTION

This module formats L<DateTime::Duration> objects as "concise HMS" format.
Duration of days and larger will be represented like "1y" (1 year), "2mo" (2
months), "3d" (3 days) while duration of hours/minutes/seconds will be
represented using hh:mm:ss e.g. 04:05:06. Examples:

 00:00:00
 1d
 3y 5mo 00:00:10.123

=head1 METHODS

=head2 new

=head2 format_duration

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Format-Duration-ConciseHMS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Format-Duration-ConciseHMS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Duration-ConciseHMS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Duration>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

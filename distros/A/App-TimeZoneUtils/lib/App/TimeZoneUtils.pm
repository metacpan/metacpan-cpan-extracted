package App::TimeZoneUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-06'; # DATE
our $DIST = 'App-TimeZoneUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{detect_local_time_zone} = {
    v => 1.1,
    summary => 'Detect local time zone',
    description => <<'_',

Currently uses <pm:DateTime::TimeZone>, which has several heuristics itself
(please see the module for more details). When local time zone cannot be
determined, it dies.

_
    args => {
    },
    examples => [
    ],
};
sub detect_local_time_zone {
    require DateTime;
    require DateTime::TimeZone;
    my %args = @_;

    my $tz = DateTime::TimeZone->new(name => "local");
    my $dt = DateTime->now(time_zone => "UTC");
    my $offset_in_seconds = $tz->offset_for_datetime($dt);
    my $offset_abs = abs($offset_in_seconds);
    my $offset_sign = $offset_in_seconds > 0 ? "+" : "-";
    my $offset_h = int($offset_abs / 3600);
    my $offset_m = int(($offset_abs - $offset_h*3600)/60);
    my $offset_in_hhmm = sprintf(
        "%s%02d%02d", $offset_sign, $offset_h, $offset_m);
    [200, "OK", {
        name => $tz->name,
        offset_in_seconds => $offset_in_seconds,
        offset_in_hhmm    => $offset_in_hhmm,
        is_dst => $tz->is_dst_for_datetime($dt) ? 1:0,
    }];
}

1;
# ABSTRACT: An assortment of time-zone-related CLI utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeZoneUtils - An assortment of time-zone-related CLI utilities

=head1 VERSION

This document describes version 0.001 of App::TimeZoneUtils (from Perl distribution App-TimeZoneUtils), released on 2021-09-06.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
time zones:

=over

=item * L<detect-local-time-zone>

=back

=head1 FUNCTIONS


=head2 detect_local_time_zone

Usage:

 detect_local_time_zone() -> [$status_code, $reason, $payload, \%result_meta]

Detect local time zone.

Currently uses L<DateTime::TimeZone>, which has several heuristics itself
(please see the module for more details). When local time zone cannot be
determined, it dies.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TimeZoneUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TimeZoneUtils>.

=head1 SEE ALSO

L<App::DateUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TimeZoneUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Bencher::Scenarios::DateTime::Format::ISO8601;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-DateTime-Format-ISO8601'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Scenarios to benchmark DateTime::Format::ISO8601

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::DateTime::Format::ISO8601 - Scenarios to benchmark DateTime::Format::ISO8601

=head1 VERSION

This document describes version 0.002 of Bencher::Scenarios::DateTime::Format::ISO8601 (from Perl distribution Bencher-Scenarios-DateTime-Format-ISO8601), released on 2023-01-19.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::DateTime::Format::ISO8601::Startup>

=item * L<Bencher::Scenario::DateTime::Format::ISO8601::Parsing>

=back

This distribution contains L<Bencher> scenarios to benchmark
L<DateTime::Format::ISO8601>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTime-Format-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTime-Format-ISO8601>.

=head1 SEE ALSO

L<Bencher::Scenarios::DateTimeFormatISO8601Format>, scenarios to benchmark
L<DateTime::Format::ISO8601::Format>.

L<Bencher::Scenarios::DateTimeFormatDurationISO8601>, scenarios to benchmark
L<DateTime::Format::Duration::ISO8601>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTime-Format-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

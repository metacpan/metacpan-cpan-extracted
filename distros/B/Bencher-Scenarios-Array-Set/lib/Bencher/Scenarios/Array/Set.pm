package Bencher::Scenarios::Array::Set;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenarios-Array-Set'; # DIST
our $VERSION = '0.004'; # VERSION

1;
# ABSTRACT: Scenarios to benchmark Array::Set

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::Array::Set - Scenarios to benchmark Array::Set

=head1 VERSION

This document describes version 0.004 of Bencher::Scenarios::Array::Set (from Perl distribution Bencher-Scenarios-Array-Set), released on 2021-10-12.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::Array::Set::startup>

=item * L<Bencher::Scenario::Array::Set::intersect>

=item * L<Bencher::Scenario::Array::Set::diff>

=item * L<Bencher::Scenario::Array::Set::union>

=item * L<Bencher::Scenario::Array::Set::symdiff>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Array-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Array-Set>.

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

This software is copyright (c) 2021, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Array-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

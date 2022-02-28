package Bencher::Scenarios::ArrayData;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-05'; # DATE
our $DIST = 'Bencher-Scenarios-ArrayData'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Scenarios related to ArrayData

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::ArrayData - Scenarios related to ArrayData

=head1 VERSION

This document describes version 0.001 of Bencher::Scenarios::ArrayData (from Perl distribution Bencher-Scenarios-ArrayData), released on 2022-02-05.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::ArrayData::Word::ID::KBBI::startup>

=item * L<Bencher::Scenario::ArrayData::Word::ID::KBBI::has_item>

=item * L<Bencher::Scenario::ArrayData::Word::ID::KBBI::pick_items>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArrayData>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

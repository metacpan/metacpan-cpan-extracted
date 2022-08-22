package Data::Sah::FilterBundle::Phone;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-17'; # DATE
our $DIST = 'Data-Sah-FilterBundle-Phone'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Sah filters related to phone numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::FilterBundle::Phone - Sah filters related to phone numbers

=head1 VERSION

This document describes version 0.001 of Data::Sah::FilterBundle::Phone (from Perl distribution Data-Sah-FilterBundle-Phone), released on 2022-07-17.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution contains the following L<Sah> filter rule modules:

=over

=item * L<Data::Sah::Filter::perl::Phone::format>

=item * L<Data::Sah::Filter::perl::Phone::format_idnlocal_nospace>

=item * L<Data::Sah::Filter::perl::Phone::format_idn>

=item * L<Data::Sah::Filter::perl::Phone::format_idn_nospace>

=back

Included Sah filter modules:

=over

=item * L<Data::Sah::Filter::perl::Phone::format>

=item * L<Data::Sah::Filter::perl::Phone::format_idn>

=item * L<Data::Sah::Filter::perl::Phone::format_idn_nospace>

=item * L<Data::Sah::Filter::perl::Phone::format_idnlocal_nospace>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-FilterBundle-Phone>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-FilterBundle-Phone>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-FilterBundle-Phone>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

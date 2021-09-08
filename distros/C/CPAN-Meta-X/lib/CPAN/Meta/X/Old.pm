# no code
## no critic: TestingAndDebugging::RequireUseStrict
package CPAN::Meta::X::Old;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-27'; # DATE
our $DIST = 'CPAN-Meta-X'; # DIST
our $VERSION = '0.006'; # VERSION

1;
# ABSTRACT: Custom (x_*) keys in CPAN distribution metadata being used in the wild (old/deprecated)

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::X::Old - Custom (x_*) keys in CPAN distribution metadata being used in the wild (old/deprecated)

=head1 VERSION

This document describes version 0.006 of CPAN::Meta::X::Old (from Perl distribution CPAN-Meta-X), released on 2021-08-27.

=head1 DESCRIPTION

This is the historical companion for L<CPAN::Meta::X>.

=head1 OLD CUSTOM DISTRIBUTION METADATA KEYS

=head1 OLD CUSTOM PREREQS PHASES

=head2 x_spec phase

Express that the current distribution is following a specification defined in
the specified module. No longer used; to express "follows a specification
module" we now use (phase=develop, rel=x_spec).

References:

=over

=item * PERLANCAR, L<https://perlancar.wordpress.com/2016/12/28/x_-prereqs/>

=back

=head1 OLD CUSTOM PREREQS RELATIONSHIPS

=head1 OLD CUSTOM RESOURCES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Meta-X>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Meta-X>.

=head1 SEE ALSO

L<CPAN::Meta::X>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Meta-X>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

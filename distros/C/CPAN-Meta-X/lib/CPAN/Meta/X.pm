# no code
## no critic: TestingAndDebugging::RequireUseStrict
package CPAN::Meta::X;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-27'; # DATE
our $DIST = 'CPAN-Meta-X'; # DIST
our $VERSION = '0.006'; # VERSION

1;
# ABSTRACT: Custom (x_*) keys in CPAN distribution metadata being used in the wild

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::X - Custom (x_*) keys in CPAN distribution metadata being used in the wild

=head1 VERSION

This document describes version 0.006 of CPAN::Meta::X (from Perl distribution CPAN-Meta-X), released on 2021-08-27.

=head1 DESCRIPTION

L<The CPAN distribution metadata specification|CPAN::Meta::Spec> allows custom
keys (those that begin with C<x_> or C<X_>) to be added to the metadata. This
document tries to catalog the custom keys that are being used by CPAN authors.

In addition to custom metadata keys, this document also lists:

=over

=item * custom phases and relationships in the L<prereqs|CPAN::Meta::Spec/PREREQUISITES> hash that are being used by people

=item * custom keys in L<resources|CPAN::Meta::Spec/resources> hash

=back

=head1 CUSTOM DISTRIBUTION METADATA KEYS

=head2 x_Dist_Zilla key

A big structure recording information related to L<Dist::Zilla> which presumably
is used to build the current distribution. Some of the things being put in here
include: perl version used to build the distribution, Dist::Zilla plugins used
to build the distribution, and so on.

=head2 x_authority key

=head2 x_contributors key

List of contributors in a release.

Examples:

TBD

References:

=over

=item * DAGOLDEN, L<https://perlmaven.com/how-to-add-list-of-contributors-to-the-cpan-meta-files>

=item * SZABGAB, L<https://github.com/book/CPANio/issues/7>

=back

=head2 x_deprecated key

=head2 x_examples key

List prerequisites for example scripts.

References:

=over

=item * KENTNL, L<https://perlancar.wordpress.com/2016/12/28/x_-prereqs/>

=back

=head2 x_generated_by_perl key

=head2 x_help_wanted key

=head2 x_provides_scripts key

List scripts that are being provided in the distribution. The structure is
modelled after the standard L<provides|CPAN::Meta::Spec/provides> hash.

Examples:

So say your distribution provides a "csv2json" script, your F<META.json> would
contain:

 "x_provides_scripts": {
   "csv2json": {
     "version": "0.1",
     "file": "bin/csv2json"
   }
 }

References:

=over

=item * TOBYINK, L<https://perlmonks.org/?node_id=11123240>

=back

=head2 x_spdx_expression key

=head2 x_serialization_backend key

=head2 x_static_install key

=head1 CUSTOM PREREQS PHASES

=head2 x_benchmarks phase

Express that the current distribution is benchmarking the specified module.

References:

=over

=item * PERLANCAR, L<https://perlancar.wordpress.com/2016/12/28/x_-prereqs/>

=back

=head2 x_mentions phase

Express that the current distribution is mentioning the specified module.

References:

=over

=item * PERLANCAR, L<https://perlancar.wordpress.com/2016/12/28/x_-prereqs/>

=back

=head1 CUSTOM PREREQS RELATIONSHIPS

=head2 x_benchmarks relationship

See L</"x_benchmarks phase">.

=head2 x_features_from relationship

Express that one of the modules in the current distribution is declaring
features that are defined defined in an associated C<Module::Features::*>
module. Used with (phase=develop).

Examples: L<Text::ANSITable>, L<Text::Table::More>, and L<Text::Table::Sprintf>
declares features defined by L<Module::Features::TextTable> so they add a
dependency (phase=develop, rel=x_features_from) to
L<Module::Features::TextTable>.

References:

=over

=item * L<Module::Features> specification

=back

=head2 x_mentions relationship

See L</"x_mentions phase">.

=head2 x_spec relationship

Express that the current distribution is following a specification defined in
the specified module. Used with (phase=develop).

References:

=over

=item * PERLANCAR, L<https://perlancar.wordpress.com/2016/12/28/x_-prereqs/>

=back

=head1 CUSTOM RESOURCES

=head2 x_IRC resource

=head2 x_identifier resource

=head2 x_mailinglist resource

=head2 x_wiki resource

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Meta-X>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Meta-X>.

=head1 SEE ALSO

L<CPAN::Meta::Spec> - Specification for CPAN distribution metadata

L<CPAN::Meta::X::Old>

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

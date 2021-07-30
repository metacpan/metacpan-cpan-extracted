package CPAN::Meta::X;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-15'; # DATE
our $DIST = 'CPAN-Meta-X'; # DIST
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: List of custom (x_*) keys in CPAN distribution metadata being used in the wild

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::X - List of custom (x_*) keys in CPAN distribution metadata being used in the wild

=head1 VERSION

This document describes version 0.003 of CPAN::Meta::X (from Perl distribution CPAN-Meta-X), released on 2021-04-15.

=head1 DESCRIPTION

L<The CPAN distribution metadata specification|CPAN::Meta::Spec> allows custom
keys (those that begin with C<x_> or C<X_>) to be added to the metadata. This
document tries to catalog the custom keys that are being used by CPAN authors.

In addition to custom metadata keys, this document also lists:

=over

=item * custom phases and relationships in the L<prereqs|CPAN::Meta::Spec/PREREQUISITES> hash that are being used by people

=item * custom keys in L<resources|CPAN::Meta::Spec/resources> hash

=back

=head1 LIST OF CUSTOM DISTRIBUTION METADATA KEYS

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

=head1 LIST OF CUSTOM PREREQS PHASES

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

=head2 x_spec phase

Express that the current distribution is following a specification defined in
the specified module.

References:

=over

=item * PERLANCAR, L<https://perlancar.wordpress.com/2016/12/28/x_-prereqs/>

=back

=head1 LIST OF CUSTOM PREREQS RELATIONSHIPS

=head2 x_benchmarks relationship

See L</"x_benchmarks phase">.

=head2 x_mentions relationship

See L</"x_mentions phase">.

=head2 x_spec relationship

See L</"x_spec phase">.

=head1 LIST OF CUSTOM RESOURCES

=head2 x_IRC resource

=head2 x_identifier resource

=head2 x_mailinglist resource

=head2 x_wiki resource

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Meta-X>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Meta-X>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-CPAN-Meta-X/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Meta::Spec> - Specification for CPAN distribution metadata

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

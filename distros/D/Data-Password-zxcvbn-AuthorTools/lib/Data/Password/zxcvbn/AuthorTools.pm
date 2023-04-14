package Data::Password::zxcvbn::AuthorTools;
use v5.26;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: collection of tools to simplify building zxcvbn distributions



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::AuthorTools - collection of tools to simplify building zxcvbn distributions

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

This distribution is only useful if you want to I<maintain> L<<
C<Data::Password::zxcvbn> >> or a distribution with language-specific
(or domain-specific) data files (e.g. L<<
C<Data::Password::zxcvbn::French> >>).

Tools included:

=over

=item L<< C<Dist::Zilla::MintingProfile::zxcvbn> >>

this minting profile automates creating a new zxcvbn distribution

=item L<< C<Data::Password::zxcvbn::AuthorTools::BuildRankedDictionaries> >>

this module takes files containing ordered lists of words (from most
common to least common) and produces Perl modules that can be used
with L<< C<Data::Password::zxcvbn::Match::Dictionary> >>

=item L<< C<Data::Password::zxcvbn::AuthorTools::BuildAdjacencyGraphs> >>

this module takes files textual descriptions of keyboard layouts and
produces Perl modules that can be used with L<<
C<Data::Password::zxcvbn::Match::Spatial> >>

=item C<zxcvbn-build-data-leipzig>

this script extracts word frequency data from the corpora maintained
by Leipzig University, and produces text files that can be used by
C<BuildRankedDictionaries>; look at its source to see how to use it

=item C<zxcvbn-build-names-data-fb-leak>

this script takes JSON files containing first/last names from a
Facebook dump, and produces text files that can be used by
C<BuildRankedDictionaries>; look at its source to see how to use it

=back

=head1 How to build a language-specific distribution

=over 4

=item *

get the appropriate corpora for the language

=item *

C<dzil new -P zxcvbn Data::Password::zxcvbn::MyLang>

=item *

C<git init> in the generated directory

=item *

C<chmod +x maint/*> (this may or may not be necessary)

=item *

edit the generated C<dist.ini>, fix all the C<FIXME> in the generated files

=item *

run C<zxcvbn-build-data-leipzig> and C<zxcvbn-build-names-data-fb-leak> to generate data files

=item *

edit the files in C<maint/> to use those data files

=item *

tweak pod and comments

=item *

C<git commit> &c

=item *

ship it

=back

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

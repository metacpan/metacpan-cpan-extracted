package Acme::CPANModules::Similarity;

use strict;
use warnings;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-17'; # DATE
our $DIST = 'Acme-CPANModules-Similarity'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'_';
** Between arrays/bags/sets

<pm:Algorithm::HowSimilar> uses Algorithm::Diff to calculate similarity between
two arrays. It can also calculate similarity between two strings.

<pm:Bag::Similarity>

<pm:Set::Jaccard::SimilarityCoefficient>

<pm:Set::Partitions::Similarity>

<pm:Set::Similarity> provides several algorithms.


** Between codes

<pm:School::Code::Compare>


** Between colors

<pm:Color::Similarity>

<pm:Color::RGB::Util> provides `rgb_diff()` and `rgb_distance()` to calculate
difference between two RGB colors using one of several algorithms.


** Between files

<pm:File::FindSimilars> uses file size and a modified soundex algorithm on the
filename to determine similarity.


** Between graphs

<pm:Graph::Similarity>


** Between HTML/XML documents

<pm:HTML::Similarity> calculates the structural similarity between two HTML
documents.

<pm:XML::Similarity>


** Between images

<pm:Image::Similar>


** Between strings/texts

Similarity between two text can be calculated using Levenshtein edit distance.
There are several levenshtein modules on CPAN, among others:
<pm:Text::Levenshtein>, <pm:Text::Levenshtein::XS>,
<pm:Text::Levenshtein::Flexible>, <pm:Text::LevenshteinXS>, <pm:Text::Fuzzy>.
For more details, see <pm:Bencher::Scenario::LevenshteinModules>.

Soundex can also be used. Some example soundex moduless: <pm:Text::Soundex>,
<pm:Text::Phonetic::Soundex>.

<pm:Algorithm::HowSimilar> uses Algorithm::Diff to calculate similarity between
two strings. It's roughly similar in speed to pure-perl Levenshtein modules, and
tend to be faster for longer strings. It can also calculate similarity between
two arrays.

<pm:String::Similarity>

<pm:String::Similarity::Group>

<pm:Text::Similarity>

<pm:String::Simrank>

<pm:String::Similex>


** Between vectors

<pm:Data::CosineSimilarity>


** Between words (semantic similarity)

<pm:WordNet::Similarity>

<pm:WordNet::SenseRelate::AllWords>


** Others

<pm:Cluster::Similarity>

_

our $LIST = {
    summary => 'List of modules to finding similarity between stuffs',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to finding similarity between stuffs

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Similarity - List of modules to finding similarity between stuffs

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Similarity (from Perl distribution Acme-CPANModules-Similarity), released on 2024-01-17.

=head1 DESCRIPTION

** Between arrays/bags/sets

L<Algorithm::HowSimilar> uses Algorithm::Diff to calculate similarity between
two arrays. It can also calculate similarity between two strings.

L<Bag::Similarity>

L<Set::Jaccard::SimilarityCoefficient>

L<Set::Partitions::Similarity>

L<Set::Similarity> provides several algorithms.

** Between codes

L<School::Code::Compare>

** Between colors

L<Color::Similarity>

L<Color::RGB::Util> provides C<rgb_diff()> and C<rgb_distance()> to calculate
difference between two RGB colors using one of several algorithms.

** Between files

L<File::FindSimilars> uses file size and a modified soundex algorithm on the
filename to determine similarity.

** Between graphs

L<Graph::Similarity>

** Between HTML/XML documents

L<HTML::Similarity> calculates the structural similarity between two HTML
documents.

L<XML::Similarity>

** Between images

L<Image::Similar>

** Between strings/texts

Similarity between two text can be calculated using Levenshtein edit distance.
There are several levenshtein modules on CPAN, among others:
L<Text::Levenshtein>, L<Text::Levenshtein::XS>,
L<Text::Levenshtein::Flexible>, L<Text::LevenshteinXS>, L<Text::Fuzzy>.
For more details, see L<Bencher::Scenario::LevenshteinModules>.

Soundex can also be used. Some example soundex moduless: L<Text::Soundex>,
L<Text::Phonetic::Soundex>.

L<Algorithm::HowSimilar> uses Algorithm::Diff to calculate similarity between
two strings. It's roughly similar in speed to pure-perl Levenshtein modules, and
tend to be faster for longer strings. It can also calculate similarity between
two arrays.

L<String::Similarity>

L<String::Similarity::Group>

L<Text::Similarity>

L<String::Simrank>

L<String::Similex>

** Between vectors

L<Data::CosineSimilarity>

** Between words (semantic similarity)

L<WordNet::Similarity>

L<WordNet::SenseRelate::AllWords>

** Others

L<Cluster::Similarity>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Algorithm::HowSimilar>

Author: L<JFREEMAN|https://metacpan.org/author/JFREEMAN>

=item L<Bag::Similarity>

Author: L<WOLLMERS|https://metacpan.org/author/WOLLMERS>

=item L<Set::Jaccard::SimilarityCoefficient>

Author: L<MLFISHER|https://metacpan.org/author/MLFISHER>

=item L<Set::Partitions::Similarity>

Author: L<KUBINA|https://metacpan.org/author/KUBINA>

=item L<Set::Similarity>

Author: L<WOLLMERS|https://metacpan.org/author/WOLLMERS>

=item L<School::Code::Compare>

Author: L<BORISD|https://metacpan.org/author/BORISD>

=item L<Color::Similarity>

Author: L<MBARBON|https://metacpan.org/author/MBARBON>

=item L<Color::RGB::Util>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<File::FindSimilars>

Author: L<SUNTONG|https://metacpan.org/author/SUNTONG>

=item L<Graph::Similarity>

Author: L<SHOHEIK|https://metacpan.org/author/SHOHEIK>

=item L<HTML::Similarity>

Author: L<XERN|https://metacpan.org/author/XERN>

=item L<XML::Similarity>

Author: L<XERN|https://metacpan.org/author/XERN>

=item L<Image::Similar>

Author: L<BKB|https://metacpan.org/author/BKB>

=item L<Text::Levenshtein>

Author: L<NEILB|https://metacpan.org/author/NEILB>

=item L<Text::Levenshtein::XS>

Author: L<UGEXE|https://metacpan.org/author/UGEXE>

=item L<Text::Levenshtein::Flexible>

Author: L<MBETHKE|https://metacpan.org/author/MBETHKE>

=item L<Text::LevenshteinXS>

Author: L<JGOLDBERG|https://metacpan.org/author/JGOLDBERG>

=item L<Text::Fuzzy>

Author: L<BKB|https://metacpan.org/author/BKB>

=item L<Bencher::Scenario::LevenshteinModules>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Text::Soundex>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<Text::Phonetic::Soundex>

Author: L<MAROS|https://metacpan.org/author/MAROS>

=item L<String::Similarity>

Author: L<MLEHMANN|https://metacpan.org/author/MLEHMANN>

=item L<String::Similarity::Group>

Author: L<LEOCHARRE|https://metacpan.org/author/LEOCHARRE>

=item L<Text::Similarity>

Author: L<TPEDERSE|https://metacpan.org/author/TPEDERSE>

=item L<String::Simrank>

Author: L<SHURIKO|https://metacpan.org/author/SHURIKO>

=item L<String::Similex>

Author: L<BIAFRA|https://metacpan.org/author/BIAFRA>

=item L<Data::CosineSimilarity>

Author: L<AIMBERT|https://metacpan.org/author/AIMBERT>

=item L<WordNet::Similarity>

Author: L<TPEDERSE|https://metacpan.org/author/TPEDERSE>

=item L<WordNet::SenseRelate::AllWords>

Author: L<TPEDERSE|https://metacpan.org/author/TPEDERSE>

=item L<Cluster::Similarity>

Author: L<INGRIF|https://metacpan.org/author/INGRIF>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n Similarity

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Similarity | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Similarity -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Similarity -E'say $_->{module} for @{ $Acme::CPANModules::Similarity::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Similarity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Similarity>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Similarity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

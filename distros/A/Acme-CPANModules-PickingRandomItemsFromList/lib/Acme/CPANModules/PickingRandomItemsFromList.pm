package Acme::CPANModules::PickingRandomItemsFromList;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-05-22'; # DATE
our $DIST = 'Acme-CPANModules-PickingRandomItemsFromList'; # DIST
our $VERSION = '0.006'; # VERSION

our $LIST = {
    summary => 'List of modules to pick random items from a list',
    description => <<'MARKDOWN',

If you are picking random lines from a file, there's a separate CPANModules list
for it: <pm:Acme::CPANModules::PickingRandomLinesFromFile>.

**1. Picking a single item, with equal probability**

If you only want to pick a single item, with equal probability, you can simply
get a random element from an array using the `$ary[rand @ary]` idiom.


**2. Picking multiple items, with equal probability**

**2a. Picking multiple items, with equal probability, duplicates allowed**

If you want to allow duplicates, you can repeatedly pick random elements from an
array using the `$ary[rand @ary]` idiom.

**2b. Picking multiple items, with equal probability, duplicates not allowed**

If you do not want to allow duplicates, there are several alternatives:

<pm:List::Util> (from version 1.54, 2020-02-02) provides `sample()`. If you use
an older version, you can use `shuffle()` then get as many number of samples as
you need from the first elements of the array using slice
(`@shuffled[0..$num_wanted-1]`) or `head()`.

<pm:List::MoreUtils> also provides `samples()`.

Keywords: sample, sampling.


**3. Picking item(s), with weights**

If you want to assign different weights to different items (so one item might be
picked more likely), you can use one of these modules:

<pm:Array::Sample::WeightedRandom> offers sampling without replacement (not
allowing duplicates) or with replacement (allowing duplicates).

<pm:Random::Skew>.

<pm:Data::Random::Weighted> currently can only pick a single item.


**Tangentially-related modules**

<pm:App::PickArgs> provides CLI <prog:pick-args> to pick random items from
command-line arguments.

MARKDOWN
    tags => ['task', 'sampling', 'random'],
    entries => [
        {
            module=>'List::Util',
        },
        {
            module=>'List::MoreUtils',
        },
        {
            module=>'Array::Sample::WeightedRandom',
        },
        {
            module=>'Random::Skew',
        },
        {
            module=>'Data::Random::Weighted',
        },
    ],
};

1;
# ABSTRACT: List of modules to pick random items from a list

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PickingRandomItemsFromList - List of modules to pick random items from a list

=head1 VERSION

This document describes version 0.006 of Acme::CPANModules::PickingRandomItemsFromList (from Perl distribution Acme-CPANModules-PickingRandomItemsFromList), released on 2025-05-22.

=head1 DESCRIPTION

If you are picking random lines from a file, there's a separate CPANModules list
for it: L<Acme::CPANModules::PickingRandomLinesFromFile>.

B<1. Picking a single item, with equal probability>

If you only want to pick a single item, with equal probability, you can simply
get a random element from an array using the C<$ary[rand @ary]> idiom.

B<2. Picking multiple items, with equal probability>

B<2a. Picking multiple items, with equal probability, duplicates allowed>

If you want to allow duplicates, you can repeatedly pick random elements from an
array using the C<$ary[rand @ary]> idiom.

B<2b. Picking multiple items, with equal probability, duplicates not allowed>

If you do not want to allow duplicates, there are several alternatives:

L<List::Util> (from version 1.54, 2020-02-02) provides C<sample()>. If you use
an older version, you can use C<shuffle()> then get as many number of samples as
you need from the first elements of the array using slice
(C<@shuffled[0..$num_wanted-1]>) or C<head()>.

L<List::MoreUtils> also provides C<samples()>.

Keywords: sample, sampling.

B<3. Picking item(s), with weights>

If you want to assign different weights to different items (so one item might be
picked more likely), you can use one of these modules:

L<Array::Sample::WeightedRandom> offers sampling without replacement (not
allowing duplicates) or with replacement (allowing duplicates).

L<Random::Skew>.

L<Data::Random::Weighted> currently can only pick a single item.

B<Tangentially-related modules>

L<App::PickArgs> provides CLI L<pick-args> to pick random items from
command-line arguments.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<List::Util>

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

=item L<List::MoreUtils>

Author: L<REHSACK|https://metacpan.org/author/REHSACK>

=item L<Array::Sample::WeightedRandom>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Random::Skew>

Author: L<TRILLICH|https://metacpan.org/author/TRILLICH>

=item L<Data::Random::Weighted>

Author: L<GEISTBERG|https://metacpan.org/author/GEISTBERG>

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

 % cpanm-cpanmodules -n PickingRandomItemsFromList

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PickingRandomItemsFromList | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PickingRandomItemsFromList -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PickingRandomItemsFromList -E'say $_->{module} for @{ $Acme::CPANModules::PickingRandomItemsFromList::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PickingRandomItemsFromList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PickingRandomItemsFromList>.

=head1 SEE ALSO

L<Bencher::Scenario::SamplingFromList> for the benchmark, which we will probably
include in the future.

Related lists: L<Acme::CPANModules::Sampling>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PickingRandomItemsFromList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

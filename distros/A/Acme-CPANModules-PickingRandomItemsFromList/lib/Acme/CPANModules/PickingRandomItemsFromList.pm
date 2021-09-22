# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Acme::CPANModules::PickingRandomItemsFromList;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-18'; # DATE
our $DIST = 'Acme-CPANModules-PickingRandomItemsFromList'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'Picking random items from a list',
    description => <<'_',

If you are picking random lines from a file, there's a separate CPANModules list
for it: <pm:Acme::CPANModules::PickingRandomLinesFromFile>.

If you want to allow duplicates, you can repeatedly pick random elements from an
array using the `$ary[rand @ary]` idiom.

If you do not want to allow duplicates:

<pm:List::Util> (from version 1.54, 2020-02-02) provides `sample()`. If you use
an older version, you can use `shuffle()` then get as many number of samples as
you need using slice (`@shuffled[0..$num_wanted-1]`) or `head()`.

<pm:List::MoreUtils> provides `samples()`.

Keywords: sample, sampling.

_
    tags => ['task'],
    entries => [
        {
            module=>'List::Util',
        },
        {
            module=>'List::MoreUtils',
        },
    ],
};

1;
# ABSTRACT: Picking random items from a list

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PickingRandomItemsFromList - Picking random items from a list

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PickingRandomItemsFromList (from Perl distribution Acme-CPANModules-PickingRandomItemsFromList), released on 2021-09-18.

=head1 DESCRIPTION

If you are picking random lines from a file, there's a separate CPANModules list
for it: L<Acme::CPANModules::PickingRandomLinesFromFile>.

If you want to allow duplicates, you can repeatedly pick random elements from an
array using the C<$ary[rand @ary]> idiom.

If you do not want to allow duplicates:

L<List::Util> (from version 1.54, 2020-02-02) provides C<sample()>. If you use
an older version, you can use C<shuffle()> then get as many number of samples as
you need using slice (C<@shuffled[0..$num_wanted-1]>) or C<head()>.

L<List::MoreUtils> provides C<samples()>.

Keywords: sample, sampling.

=head1 ACME::MODULES ENTRIES

=over

=item * L<List::Util>

=item * L<List::MoreUtils>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PickingRandomItemsFromList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

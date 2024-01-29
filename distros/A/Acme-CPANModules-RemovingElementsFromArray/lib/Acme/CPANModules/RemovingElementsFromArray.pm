package Acme::CPANModules::RemovingElementsFromArray;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-30'; # DATE
our $DIST = 'Acme-CPANModules-RemovingElementsFromArray'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'List of modules to help remove elements from array',
    description => <<'MARKDOWN',

Perl provides several ways to remove elements from an array. `shift` removes one
element from the beginning, `pop` removes one element from the end, and `splice`
removes a slice of array (and insert another list in its place). There's also
`grep`, which lets you filter a list with a user-supplied code. While this does
not directly modify an array, you can simply assign the new filtered values to
the array. And I might just as well mention array slice (`@ary[1,3,4]` or
`@ary[1..4]`) which allows you to pick the range of elements you want by their
indices.

In addition to the above, there are also other modules which provide some
convenience.

**Removing duplicate items**

<pm:List::Util> provides C<uniq> (as well as C<uniqnum>, C<uniqint>, C<uniqstr>)
to remove duplicate items from a list. There's also <pm:List::Util::Uniq>
providing C<dupe>, C<dupenum>, C<dupeint>, and C<dupestr>, which return the
duplicates instead.

**Removing overlapped items**

<pm:Array::OverlapFinder> lets you find overlapping items from a series of
arrays and optionally remove them.

**Variations of `grep`**

Some modules offer variations of `grep`. For example, <pm:Array::KeepGrepped>
keeps the elements that are filtered out instead those that match the grep
expression. <pm:List::Util::sglice> offers `sglice`, which removes elements that
matches user-supplied code, except that `sglice` (like `splice`) allows you to
specify a limit to the number of elements to remove.

**mapslice**

<pm:List::Util::mapsplice> offers `mapsplice`, which removes a slice of array
but lets you replace each element with new elements using Perl code.

MARKDOWN
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to help remove elements from array

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RemovingElementsFromArray - List of modules to help remove elements from array

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::RemovingElementsFromArray (from Perl distribution Acme-CPANModules-RemovingElementsFromArray), released on 2023-09-30.

=head1 DESCRIPTION

Perl provides several ways to remove elements from an array. C<shift> removes one
element from the beginning, C<pop> removes one element from the end, and C<splice>
removes a slice of array (and insert another list in its place). There's also
C<grep>, which lets you filter a list with a user-supplied code. While this does
not directly modify an array, you can simply assign the new filtered values to
the array. And I might just as well mention array slice (C<@ary[1,3,4]> or
C<@ary[1..4]>) which allows you to pick the range of elements you want by their
indices.

In addition to the above, there are also other modules which provide some
convenience.

B<Removing duplicate items>

L<List::Util> provides C<uniq> (as well as C<uniqnum>, C<uniqint>, C<uniqstr>)
to remove duplicate items from a list. There's also L<List::Util::Uniq>
providing C<dupe>, C<dupenum>, C<dupeint>, and C<dupestr>, which return the
duplicates instead.

B<Removing overlapped items>

L<Array::OverlapFinder> lets you find overlapping items from a series of
arrays and optionally remove them.

B<< Variations of C<grep> >>

Some modules offer variations of C<grep>. For example, L<Array::KeepGrepped>
keeps the elements that are filtered out instead those that match the grep
expression. L<List::Util::sglice> offers C<sglice>, which removes elements that
matches user-supplied code, except that C<sglice> (like C<splice>) allows you to
specify a limit to the number of elements to remove.

B<mapslice>

L<List::Util::mapsplice> offers C<mapsplice>, which removes a slice of array
but lets you replace each element with new elements using Perl code.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<List::Util>

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

=item L<List::Util::Uniq>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Array::OverlapFinder>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Array::KeepGrepped>

Author: L<ONEONETWO|https://metacpan.org/author/ONEONETWO>

=item L<List::Util::sglice>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<List::Util::mapsplice>

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

 % cpanm-cpanmodules -n RemovingElementsFromArray

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RemovingElementsFromArray | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RemovingElementsFromArray -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RemovingElementsFromArray -E'say $_->{module} for @{ $Acme::CPANModules::RemovingElementsFromArray::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RemovingElementsFromArray>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RemovingElementsFromArray>.

=head1 SEE ALSO

Somewhat related lists pertaining to list/array:
L<Acme::CPANModules::GroupingElementsOfArray>.
L<Acme::CPANModules::PickingRandomItemsFromList>,
L<Acme::CPANModules::Import::RSAVAGE::ArrayAndSetOperations>,
L<Acme::CPANModules::Import::MJGARDNER::ListProcessing>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RemovingElementsFromArray>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

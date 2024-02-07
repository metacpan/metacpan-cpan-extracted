package Acme::CPANModules::DataStructureWalker;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-DataStructureWalker'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => "List of modules that traverse your data structure",
    description => <<'_',

This list catalogs modules that let you traverse your data structure by visiting
each node/item: each element of an array, each key/value pair of a hash,
recursively. Sort of like <pm:File::Find> for your data instead of filesystem.
These modules can be used for searching or modifying your data.

Many modules in this list mimic Perl's `map` interface, for example:
<pm:Data::Rmap>, <pm:Data::Dmap>, <pm:Data::Traverse>. The difference among
these modules lies in the details: in how you specify option to skip unsupported
types of references, or whether some let you control the recursion (e.g.
Data::Rmap's and Data::Dmap's `cut`),

<pm:Data::Walk> models its interface on File::Find. It lets you choose whether
you want to go depth-first or breadth-first.

Benchmarks for these modules coming soon.

Related modules:

<pm:Data::Clean> can be used to clean/sanitize your data structure more
performantly compared to your manual walking (e.g. using Data::Rmap). It works
by generating Perl code specifically for your cleaning needs.

_
    entries => [
        {module => 'Data::Rmap'},
        {module => 'Data::Dmap'},
        {module => 'Data::Visitor'},
        {module => 'Data::Transformer'},
        {module => 'Data::Traverse'},
        {module => 'Data::Leaf::Walker'},
        {module => 'Data::Walk'},

        {module => 'Data::Clean'},
    ],
};

1;
# ABSTRACT: List of modules that traverse your data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DataStructureWalker - List of modules that traverse your data structure

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::DataStructureWalker (from Perl distribution Acme-CPANModules-DataStructureWalker), released on 2023-10-29.

=head1 DESCRIPTION

This list catalogs modules that let you traverse your data structure by visiting
each node/item: each element of an array, each key/value pair of a hash,
recursively. Sort of like L<File::Find> for your data instead of filesystem.
These modules can be used for searching or modifying your data.

Many modules in this list mimic Perl's C<map> interface, for example:
L<Data::Rmap>, L<Data::Dmap>, L<Data::Traverse>. The difference among
these modules lies in the details: in how you specify option to skip unsupported
types of references, or whether some let you control the recursion (e.g.
Data::Rmap's and Data::Dmap's C<cut>),

L<Data::Walk> models its interface on File::Find. It lets you choose whether
you want to go depth-first or breadth-first.

Benchmarks for these modules coming soon.

Related modules:

L<Data::Clean> can be used to clean/sanitize your data structure more
performantly compared to your manual walking (e.g. using Data::Rmap). It works
by generating Perl code specifically for your cleaning needs.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Data::Rmap>

Author: L<BOWMANBS|https://metacpan.org/author/BOWMANBS>

=item L<Data::Dmap>

Author: L<MADZ|https://metacpan.org/author/MADZ>

=item L<Data::Visitor>

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item L<Data::Transformer>

Author: L<BALDUR|https://metacpan.org/author/BALDUR>

=item L<Data::Traverse>

Author: L<FRIEDO|https://metacpan.org/author/FRIEDO>

=item L<Data::Leaf::Walker>

Author: L<DANBOO|https://metacpan.org/author/DANBOO>

=item L<Data::Walk>

Author: L<GUIDO|https://metacpan.org/author/GUIDO>

=item L<Data::Clean>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n DataStructureWalker

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries DataStructureWalker | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DataStructureWalker -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::DataStructureWalker -E'say $_->{module} for @{ $Acme::CPANModules::DataStructureWalker::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DataStructureWalker>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DataStructureWalker>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DataStructureWalker>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

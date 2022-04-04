package Acme::CPANModules::Set;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-Set'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "List of modules that deal with sets",
    description => <<'_',

Set is an abstract data type that can store unique values, without any
particular order.

In Perl, you can implement set with a hash, with O(1) for average search speed.
The downside is hash keys are limited to strings, but you can store complex data
structures as values with some simple workaround. Less preferrably, you can also
use an array to implement a hash, with O(n) for all insertion/deletion/search
speed as you need to compare all array elements first for (uniqueness of)
values. Finally, you can choose from various existing CPAN modules that handle
sets.

_
    entries => [

        {
            module => 'Set::Light',
            description => <<'_',

Basically just a hash underneath. You are limited to storing strings as values.
Does not provide interset operations.

_
        },

        {
            module => 'Set::Tiny',
            description => <<'_',

Uses hash underneath, so you are also limited to storing strings as values. but
unlike <pm:Set::Light>, provides more methods.

_
        },

        {
            module => 'Array::Set',
            description => <<'_',

Performs set operations on array

_
        },

        # TODO: add Test::Deep, it has set()
    ],
};

1;
# ABSTRACT: List of modules that deal with sets

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Set - List of modules that deal with sets

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Set (from Perl distribution Acme-CPANModules-Set), released on 2022-03-18.

=head1 DESCRIPTION

Set is an abstract data type that can store unique values, without any
particular order.

In Perl, you can implement set with a hash, with O(1) for average search speed.
The downside is hash keys are limited to strings, but you can store complex data
structures as values with some simple workaround. Less preferrably, you can also
use an array to implement a hash, with O(n) for all insertion/deletion/search
speed as you need to compare all array elements first for (uniqueness of)
values. Finally, you can choose from various existing CPAN modules that handle
sets.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Set::Light> - (memory efficient) unordered set of strings

Author: L<RRWO|https://metacpan.org/author/RRWO>

Basically just a hash underneath. You are limited to storing strings as values.
Does not provide interset operations.


=item * L<Set::Tiny> - Simple sets of strings

Author: L<TRENDELS|https://metacpan.org/author/TRENDELS>

Uses hash underneath, so you are also limited to storing strings as values. but
unlike L<Set::Light>, provides more methods.


=item * L<Array::Set> - Perform set operations on arrays

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Performs set operations on array


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

 % cpanm-cpanmodules -n Set

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Set | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Set -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Set -E'say $_->{module} for @{ $Acme::CPANModules::Set::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Set>.

=head1 SEE ALSO

Alternative data structures: bloom filter (see
L<Acme::CPANModules::BloomFilters>).

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

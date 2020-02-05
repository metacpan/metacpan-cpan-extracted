package Acme::CPANModules::WorkingWithTree;

our $DATE = '2020-02-04'; # DATE
our $VERSION = '0.002'; # VERSION

my $text = <<'_';
**Basics**

Perl classes to represent tree (node) structure: <pm:Tree::Object> and
<pm:Tree::ObjectXS> (comes with several varieties). They provide methods like
walking a tree, checking whether a node is the first child, getting sibling
nodes, and so on.

Perl modules to manipulate tree: <pm:Data::Tree>, <pm:Tree::Simple>.

Memory-efficient tree nodes in Perl: <pm:Tree::Node>.


**Creating**

<pm:Tree::From::Struct>, <pm:Tree::From::Text>, <pm:Tree::From::TextLines>,
<pm:Tree::Create::Callback>, <pm:Tree::Create::Callback::ChildrenPerLevel>,
<pm:Tree::Create::Size>, <pm:Tree::From::FS>.

<pm:Data::Random::Tree>.


**Visualizing as text**

<pm:Tree::To::Text>, <pm:Tree::To::TextLines>.


**Visualizing as graphic**

TODO


**Other modules**

<pm:Tree::To::FS>.

Special kinds of trees: TODO.


**Roles**

<pm:Role::TinyCommons::Tree>.

_

our $LIST = {
    summary => 'Working with tree data structure in Perl',
    description => $text,
    tags => ['task'],
    entries => [
        map { +{module=>$_} }
            do { my %seen; grep { !$seen{$_}++ }
                 ($text =~ /<pm:(\w+(?:::\w+)+)>/g)
             }
    ],
};

1;
# ABSTRACT: Working with tree data structure in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithTree - Working with tree data structure in Perl

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::WorkingWithTree (from Perl distribution Acme-CPANModules-WorkingWithTree), released on 2020-02-04.

=head1 DESCRIPTION

Working with tree data structure in Perl.

B<Basics>

Perl classes to represent tree (node) structure: L<Tree::Object> and
L<Tree::ObjectXS> (comes with several varieties). They provide methods like
walking a tree, checking whether a node is the first child, getting sibling
nodes, and so on.

Perl modules to manipulate tree: L<Data::Tree>, L<Tree::Simple>.

Memory-efficient tree nodes in Perl: L<Tree::Node>.

B<Creating>

L<Tree::From::Struct>, L<Tree::From::Text>, L<Tree::From::TextLines>,
L<Tree::Create::Callback>, L<Tree::Create::Callback::ChildrenPerLevel>,
L<Tree::Create::Size>, L<Tree::From::FS>.

L<Data::Random::Tree>.

B<Visualizing as text>

L<Tree::To::Text>, L<Tree::To::TextLines>.

B<Visualizing as graphic>

TODO

B<Other modules>

L<Tree::To::FS>.

Special kinds of trees: TODO.

B<Roles>

L<Role::TinyCommons::Tree>.

=head1 INCLUDED MODULES

=over

=item * L<Tree::Object>

=item * L<Tree::ObjectXS>

=item * L<Data::Tree>

=item * L<Tree::Simple>

=item * L<Tree::Node>

=item * L<Tree::From::Struct>

=item * L<Tree::From::Text>

=item * L<Tree::From::TextLines>

=item * L<Tree::Create::Callback>

=item * L<Tree::Create::Callback::ChildrenPerLevel>

=item * L<Tree::Create::Size>

=item * L<Tree::From::FS>

=item * L<Data::Random::Tree>

=item * L<Tree::To::Text>

=item * L<Tree::To::TextLines>

=item * L<Tree::To::FS>

=item * L<Role::TinyCommons::Tree>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries WorkingWithTree | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=WorkingWithTree -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithTree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithTree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

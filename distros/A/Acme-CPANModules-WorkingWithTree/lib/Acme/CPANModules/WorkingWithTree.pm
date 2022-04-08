package Acme::CPANModules::WorkingWithTree;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-WorkingWithTree'; # DIST
our $VERSION = '0.007'; # VERSION

my $text = <<'_';
**Basics**

Perl classes to represent tree (node) structure: <pm:Tree::Object> and
<pm:Tree::ObjectXS> (comes with several varieties). They provide methods like
walking a tree, checking whether a node is the first child, getting sibling
nodes, and so on.

Perl modules to manipulate tree: <pm:Data::Tree>, <pm:Tree::Simple>.

Memory-efficient tree nodes in Perl: <pm:Tree::Node>.


**Creating**

<pm:Tree::From::Struct>, <pm:Tree::From::ObjArray>, <pm:Tree::From::Text>,
<pm:Tree::From::TextLines>, <pm:Tree::Create::Callback>,
<pm:Tree::Create::Callback::ChildrenPerLevel>, <pm:Tree::Create::Size>,
<pm:Tree::From::FS>.

<pm:Data::Random::Tree>.


**Visualizing as text**

<pm:Tree::To::Text>, <pm:Tree::To::TextLines>.

<pm:Text::Tree::Indented>. This module accepts nested array of strings instead
of tree object.


**Visualizing as graphics**

TODO


**Other modules**

<pm:Tree::To::FS>.

<pm:Tree::Shell>.

Special kinds of trees: TODO.


**Roles**

<pm:Role::TinyCommons::Tree::Node>, <pm:Role::TinyCommons::Tree::NodeMethods>.


**Modules that produce or work with Role::TinyCommons::Tree::Node-compliant tree objects**

<pm:Org::Parser>, <pm:Org::Parser::Tiny>.

<pm:Tree::Dump>.

<pm:Data::CSel> and its related modules: <pm:App::htmlsel>, <pm:App::jsonsel>,
<pm:App::orgsel>, <pm:App::podsel>, <pm:App::ppisel>, <pm:App::yamlsel>,
<pm:App::CSelUtils>.

_

our $LIST = {
    summary => 'List of modules to work with tree data structure',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to work with tree data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithTree - List of modules to work with tree data structure

=head1 VERSION

This document describes version 0.007 of Acme::CPANModules::WorkingWithTree (from Perl distribution Acme-CPANModules-WorkingWithTree), released on 2022-03-18.

=head1 DESCRIPTION

B<Basics>

Perl classes to represent tree (node) structure: L<Tree::Object> and
L<Tree::ObjectXS> (comes with several varieties). They provide methods like
walking a tree, checking whether a node is the first child, getting sibling
nodes, and so on.

Perl modules to manipulate tree: L<Data::Tree>, L<Tree::Simple>.

Memory-efficient tree nodes in Perl: L<Tree::Node>.

B<Creating>

L<Tree::From::Struct>, L<Tree::From::ObjArray>, L<Tree::From::Text>,
L<Tree::From::TextLines>, L<Tree::Create::Callback>,
L<Tree::Create::Callback::ChildrenPerLevel>, L<Tree::Create::Size>,
L<Tree::From::FS>.

L<Data::Random::Tree>.

B<Visualizing as text>

L<Tree::To::Text>, L<Tree::To::TextLines>.

L<Text::Tree::Indented>. This module accepts nested array of strings instead
of tree object.

B<Visualizing as graphics>

TODO

B<Other modules>

L<Tree::To::FS>.

L<Tree::Shell>.

Special kinds of trees: TODO.

B<Roles>

L<Role::TinyCommons::Tree::Node>, L<Role::TinyCommons::Tree::NodeMethods>.

B<Modules that produce or work with Role::TinyCommons::Tree::Node-compliant tree objects>

L<Org::Parser>, L<Org::Parser::Tiny>.

L<Tree::Dump>.

L<Data::CSel> and its related modules: L<App::htmlsel>, L<App::jsonsel>,
L<App::orgsel>, L<App::podsel>, L<App::ppisel>, L<App::yamlsel>,
L<App::CSelUtils>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Tree::Object> - Generic tree objects

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::ObjectXS> - Generic tree objects (with XS accessors, etc)

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Data::Tree> - a hash-based tree-like data structure

Author: L<TEX|https://metacpan.org/author/TEX>

=item * L<Tree::Simple> - A simple tree object

Author: L<RSAVAGE|https://metacpan.org/author/RSAVAGE>

=item * L<Tree::Node> - Memory-efficient tree nodes in Perl

Author: L<RRWO|https://metacpan.org/author/RRWO>

=item * L<Tree::From::Struct> - Build a tree object from hash structure

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::From::ObjArray> - Build a tree of objects from a nested array of objects

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::From::Text> - Build a tree object from text

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::From::TextLines> - Build a tree object from lines of text, each line indented to express structure

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::Create::Callback> - Create tree object by using a callback

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::Create::Callback::ChildrenPerLevel> - Create tree object by using a callback (and number of children per level)

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::Create::Size> - Create a tree object of certain size

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::From::FS>

=item * L<Data::Random::Tree> - Create a random tree

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::To::Text> - Show a tree object structure as text

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::To::TextLines> - Render a tree object as indented text lines

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Text::Tree::Indented> - render a tree data structure in the classic indented view

Author: L<NEILB|https://metacpan.org/author/NEILB>

=item * L<Tree::To::FS> - Create a directory structure using tree object

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::Shell> - Navigate and manipulate in-memory tree objects using a CLI shell

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Role::TinyCommons::Tree::Node> - Role for a tree node object

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Role::TinyCommons::Tree::NodeMethods> - Role that provides tree node methods

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Org::Parser> - Parse Org documents

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Org::Parser::Tiny> - Parse Org documents with as little code (and no non-core deps) as possible

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Tree::Dump> - Dump a tree object

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Data::CSel> - Select tree node objects using CSS Selector-like syntax

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::htmlsel> - Select HTML::Element nodes using CSel syntax

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::jsonsel> - Select JSON elements using CSel (CSS-selector-like) syntax

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::orgsel> - Select Org document elements using CSel (CSS-selector-like) syntax

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::podsel> - Select Pod::Elemental nodes using CSel syntax

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::ppisel> - Select PPI::Element nodes using CSel syntax

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::yamlsel> - Select YAML elements using CSel (CSS-selector-like) syntax

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::CSelUtils> - Utilities related to Data::CSel

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

 % cpanm-cpanmodules -n WorkingWithTree

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries WorkingWithTree | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=WorkingWithTree -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::WorkingWithTree -E'say $_->{module} for @{ $Acme::CPANModules::WorkingWithTree::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithTree>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithTree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

package Acme::CPANModules::WorkingWithTree;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'Acme-CPANModules-WorkingWithTree'; # DIST
our $VERSION = '0.006'; # VERSION

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
    summary => 'Working with tree data structure in Perl',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Working with tree data structure in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithTree - Working with tree data structure in Perl

=head1 VERSION

This document describes version 0.006 of Acme::CPANModules::WorkingWithTree (from Perl distribution Acme-CPANModules-WorkingWithTree), released on 2021-10-07.

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

=head1 ACME::MODULES ENTRIES

=over

=item * L<Tree::Object>

=item * L<Tree::ObjectXS>

=item * L<Data::Tree>

=item * L<Tree::Simple>

=item * L<Tree::Node>

=item * L<Tree::From::Struct>

=item * L<Tree::From::ObjArray>

=item * L<Tree::From::Text>

=item * L<Tree::From::TextLines>

=item * L<Tree::Create::Callback>

=item * L<Tree::Create::Callback::ChildrenPerLevel>

=item * L<Tree::Create::Size>

=item * L<Tree::From::FS>

=item * L<Data::Random::Tree>

=item * L<Tree::To::Text>

=item * L<Tree::To::TextLines>

=item * L<Text::Tree::Indented>

=item * L<Tree::To::FS>

=item * L<Tree::Shell>

=item * L<Role::TinyCommons::Tree::Node>

=item * L<Role::TinyCommons::Tree::NodeMethods>

=item * L<Org::Parser>

=item * L<Org::Parser::Tiny>

=item * L<Tree::Dump>

=item * L<Data::CSel>

=item * L<App::htmlsel>

=item * L<App::jsonsel>

=item * L<App::orgsel>

=item * L<App::podsel>

=item * L<App::ppisel>

=item * L<App::yamlsel>

=item * L<App::CSelUtils>

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

This software is copyright (c) 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithTree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

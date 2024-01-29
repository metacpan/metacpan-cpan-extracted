package Acme::CPANModules::OrderingAndRunningTasks;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-20'; # DATE
our $DIST = 'Acme-CPANModules-OrderingAndRunningTasks'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of modules/tools to order multiple tasks (with possible interdependency) and running them (possibly in parallel)',
    description => <<'_',

This list reviews what tools are available on CPAN and in general to order
multiple tasks (with possible interdependency) and running them (possibly in
parallel).

To specify dependency, you can use a graph then do a topological sort on it.
This will make sure that a task that depends on another is executed after the
latter. This will also check circular dependencies: if there is a circular
dependency, the graph becomes cyclical and will fail to sort topologically.
There are several modules to do topological sorting, among them: <pm:Graph>,
<pm:Data::Graph::Util>, <pm:Sort::Topological>. There's also
<pm:Algorithm::Dependency>.

To run tasks in parallel, you can also represent the tasks and dependencies
among them using a graph, then separate the connected subgraphs. The subgraphs
do not connect to one another and thus you can run the tasks in a subgraph in
parallel with tasks in another subgraph. These modules can search and return
connected subgraphs: <pm:Graph> (`connected_components` method),
<pm:Data::Graph::Util> (`connected_components` function).

Keyword: dependency ordering, parallel execution

_
    entries => [
        {
            module => 'Sub::Genius',
        },
        {
            module => 'App::Dothe',
        },
        {
            module => 'Zapp',
        },
        {
            module => 'Minion::Job',
        },
        {
            module => 'Sparrow',
        },
    ],
};

1;
# ABSTRACT: List of modules/tools to order multiple tasks (with possible interdependency) and running them (possibly in parallel)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OrderingAndRunningTasks - List of modules/tools to order multiple tasks (with possible interdependency) and running them (possibly in parallel)

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::OrderingAndRunningTasks (from Perl distribution Acme-CPANModules-OrderingAndRunningTasks), released on 2023-12-20.

=head1 DESCRIPTION

This list reviews what tools are available on CPAN and in general to order
multiple tasks (with possible interdependency) and running them (possibly in
parallel).

To specify dependency, you can use a graph then do a topological sort on it.
This will make sure that a task that depends on another is executed after the
latter. This will also check circular dependencies: if there is a circular
dependency, the graph becomes cyclical and will fail to sort topologically.
There are several modules to do topological sorting, among them: L<Graph>,
L<Data::Graph::Util>, L<Sort::Topological>. There's also
L<Algorithm::Dependency>.

To run tasks in parallel, you can also represent the tasks and dependencies
among them using a graph, then separate the connected subgraphs. The subgraphs
do not connect to one another and thus you can run the tasks in a subgraph in
parallel with tasks in another subgraph. These modules can search and return
connected subgraphs: L<Graph> (C<connected_components> method),
L<Data::Graph::Util> (C<connected_components> function).

Keyword: dependency ordering, parallel execution

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Sub::Genius>

Author: L<OODLER|https://metacpan.org/author/OODLER>

=item L<App::Dothe>

Author: L<YANICK|https://metacpan.org/author/YANICK>

=item L<Zapp>

Author: L<PREACTION|https://metacpan.org/author/PREACTION>

=item L<Minion::Job>

Author: L<SRI|https://metacpan.org/author/SRI>

=item L<Sparrow>

Author: L<MELEZHIK|https://metacpan.org/author/MELEZHIK>

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

 % cpanm-cpanmodules -n OrderingAndRunningTasks

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries OrderingAndRunningTasks | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OrderingAndRunningTasks -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::OrderingAndRunningTasks -E'say $_->{module} for @{ $Acme::CPANModules::OrderingAndRunningTasks::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OrderingAndRunningTasks>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OrderingAndRunningTasks>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OrderingAndRunningTasks>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

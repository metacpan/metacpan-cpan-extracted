package Acme::CPANModules::TableData;

use strict;
use warnings;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-22'; # DATE
our $DIST = 'Acme-CPANModules-TableData'; # DIST
our $VERSION = '0.002'; # VERSION

my $text = <<'MARKDOWN';

<pm:TableData> is a way to package 2-dimensional table data as a Perl/CPAN
module. It also provides a standard interface to access the data, including
iterating the data rows, getting the column names, and so on.


**The tables**

All Perl modules under `TableData::*` namespace are modules that contain table
data. Examples include: `TableData::Sample::DeNiro`,
`TableData::Perl::CPAN::Release::Static`,
`TableData::Perl::CPAN::Release::Dynamic`.


**CLIs**

<prog:td> (from <pm:App::td>) offers commands to manipulate table data. In
addition to a `TableData::*` module, you can also feed it CSV, TSV, JSON, YAML
files. The commands include: head, tail, sort, sum, avg, select rows, wc (count
rows), grep, map, etc.

<prog:tabledata> (from <pm:App::tabledata>) is the official CLI for `TableData`.
Currently it offers less commands than `td`, but it can also list `TableData::*`
modules in local installation or CPAN.

<prog:fsql> (from <pm:App::fsql>) allows you to query `TableData::*` modules (as
well as CSV/TSV/JSON/YAML files) using SQL.


**Sah schemas**

<pm:Sah::Schemas::TableData>


**Tie**

<pm:Tie::Array::TableData>


**Miscelaneous**

<pm:Perinci::Sub::Gen::AccessTable> accepts TableData module.

MARKDOWN

our $LIST = {
    summary => 'List of modules related to TableData',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules related to TableData

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::TableData - List of modules related to TableData

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::TableData (from Perl distribution Acme-CPANModules-TableData), released on 2024-01-22.

=head1 DESCRIPTION

L<TableData> is a way to package 2-dimensional table data as a Perl/CPAN
module. It also provides a standard interface to access the data, including
iterating the data rows, getting the column names, and so on.

B<The tables>

All Perl modules under C<TableData::*> namespace are modules that contain table
data. Examples include: C<TableData::Sample::DeNiro>,
C<TableData::Perl::CPAN::Release::Static>,
C<TableData::Perl::CPAN::Release::Dynamic>.

B<CLIs>

L<td> (from L<App::td>) offers commands to manipulate table data. In
addition to a C<TableData::*> module, you can also feed it CSV, TSV, JSON, YAML
files. The commands include: head, tail, sort, sum, avg, select rows, wc (count
rows), grep, map, etc.

L<tabledata> (from L<App::tabledata>) is the official CLI for C<TableData>.
Currently it offers less commands than C<td>, but it can also list C<TableData::*>
modules in local installation or CPAN.

L<fsql> (from L<App::fsql>) allows you to query C<TableData::*> modules (as
well as CSV/TSV/JSON/YAML files) using SQL.

B<Sah schemas>

L<Sah::Schemas::TableData>

B<Tie>

L<Tie::Array::TableData>

B<Miscelaneous>

L<Perinci::Sub::Gen::AccessTable> accepts TableData module.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<TableData>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::td>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::tabledata>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::fsql>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Sah::Schemas::TableData>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Tie::Array::TableData>

=item L<Perinci::Sub::Gen::AccessTable>

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

 % cpanm-cpanmodules -n TableData

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries TableData | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=TableData -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::TableData -E'say $_->{module} for @{ $Acme::CPANModules::TableData::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-TableData>.

=head1 SEE ALSO

Related lists: L<Acme::CPANModules::ArrayData>, L<Acme::CPANModules::HashData>.

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

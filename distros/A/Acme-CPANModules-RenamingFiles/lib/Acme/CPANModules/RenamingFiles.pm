package Acme::CPANModules::RenamingFiles;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-14'; # DATE
our $DIST = 'Acme-CPANModules-RenamingFiles'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of Perl modules (and scripts) to rename multiple files',
    description => <<'_',

This list will attempt to catalog Perl modules (and scripts) that can be used to
rename multiple files, often by letting you transform the filename using Perl
code or regex.

The granddaddy of all this is of course Larry's own script <prog:rename>, which
appeared as a dozen-line simple example at least as early as 1989 in `eg/`
subdirectory of the Perl 3.0 source code (while regex itself was introduced just
a year earlier in Perl 2.0). Later in Perl 5.8 the examples subdirectory was
removed from the source code. Currently there are at least three evolutions from
this script on CPAN: <pm:rename> by Peder Stray (since 2000), <pm:File::Rename>
by Robin Barker (since 2005), and <pm:App::FileTools::BulkRename> by Stirling
Westrup (since 2010).

<prog:rename> by Peder Stray (you might have difficulty installing the archive
using CPAN client since it does not include a module) is based on Larry Wall's
`rename` script and has grown to feature dry-run mode, backup, interactive
prompt, etc.

<prog:rename> from <pm:File::Rename> by Robin Barker is also based on Larry
Wall's script and refactors the functionality into a module. It does not have as
many options as Peder's version but offers a Unicode option.

<prog:brn> from <pm:App::FileTools::BulkRename> (since 2010) by Stirling
Westrup. Another fork of Larry Wall's `rename`. It features dry-run mode
(`--nop`) and saving/loading presets of options (including the Perl expression)
into its config file.

<prog:perlmv> from <pm:App::perlmv> (since 2010) is my take in this space. I
wanted to reuse my rename one-liners so I made a "scriptlet" feature which you
can save and run using the script (`brn` also does this, in the form of
presets). `perlmv` features dry-run mode, recursive renaming, reverse ordering
(to work around issue like wanting to rename files named 1, 2, 3, ... to 2, 3,
4, ...). The distribution also comes with sister scripts <prog:perlln>,
<prog:perlln_s>, and <prog:perlcp>.

<prog:perlmv-u> from <pm:App::perlmv> (since 2017) is my other take. The main
feature is undo. It does not yet has nearly as many features as its older
brother `perlmv`.

<prog:pmv> from <pm:File::PerlMove> (since 2007) by Johan Vromans of
`Getopt::Long` fame. Like `File::Rename`, it also refactors the logic into
module. It also added a DWIM for specific Perl expression like `uc`, `lc` when
dealing with case-insensitive filesystems.

<pm:App::FileRenameUtils>, a collection of mass renaming utilities.

_
    'x.app.cpanmodules.show_entries' => 0,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of Perl modules (and scripts) to rename multiple files

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RenamingFiles - List of Perl modules (and scripts) to rename multiple files

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::RenamingFiles (from Perl distribution Acme-CPANModules-RenamingFiles), released on 2022-11-14.

=head1 DESCRIPTION

This list will attempt to catalog Perl modules (and scripts) that can be used to
rename multiple files, often by letting you transform the filename using Perl
code or regex.

The granddaddy of all this is of course Larry's own script L<rename>, which
appeared as a dozen-line simple example at least as early as 1989 in C<eg/>
subdirectory of the Perl 3.0 source code (while regex itself was introduced just
a year earlier in Perl 2.0). Later in Perl 5.8 the examples subdirectory was
removed from the source code. Currently there are at least three evolutions from
this script on CPAN: L<rename> by Peder Stray (since 2000), L<File::Rename>
by Robin Barker (since 2005), and L<App::FileTools::BulkRename> by Stirling
Westrup (since 2010).

L<rename> by Peder Stray (you might have difficulty installing the archive
using CPAN client since it does not include a module) is based on Larry Wall's
C<rename> script and has grown to feature dry-run mode, backup, interactive
prompt, etc.

L<rename> from L<File::Rename> by Robin Barker is also based on Larry
Wall's script and refactors the functionality into a module. It does not have as
many options as Peder's version but offers a Unicode option.

L<brn> from L<App::FileTools::BulkRename> (since 2010) by Stirling
Westrup. Another fork of Larry Wall's C<rename>. It features dry-run mode
(C<--nop>) and saving/loading presets of options (including the Perl expression)
into its config file.

L<perlmv> from L<App::perlmv> (since 2010) is my take in this space. I
wanted to reuse my rename one-liners so I made a "scriptlet" feature which you
can save and run using the script (C<brn> also does this, in the form of
presets). C<perlmv> features dry-run mode, recursive renaming, reverse ordering
(to work around issue like wanting to rename files named 1, 2, 3, ... to 2, 3,
4, ...). The distribution also comes with sister scripts L<perlln>,
L<perlln_s>, and L<perlcp>.

L<perlmv-u> from L<App::perlmv> (since 2017) is my other take. The main
feature is undo. It does not yet has nearly as many features as its older
brother C<perlmv>.

L<pmv> from L<File::PerlMove> (since 2007) by Johan Vromans of
C<Getopt::Long> fame. Like C<File::Rename>, it also refactors the logic into
module. It also added a DWIM for specific Perl expression like C<uc>, C<lc> when
dealing with case-insensitive filesystems.

L<App::FileRenameUtils>, a collection of mass renaming utilities.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<rename>

=item L<File::Rename>

Author: L<RMBARKER|https://metacpan.org/author/RMBARKER>

=item L<App::FileTools::BulkRename>

=item L<App::perlmv>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<File::PerlMove>

Author: L<JV|https://metacpan.org/author/JV>

=item L<App::FileRenameUtils>

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

 % cpanm-cpanmodules -n RenamingFiles

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RenamingFiles | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RenamingFiles -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RenamingFiles -E'say $_->{module} for @{ $Acme::CPANModules::RenamingFiles::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RenamingFiles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RenamingFiles>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RenamingFiles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

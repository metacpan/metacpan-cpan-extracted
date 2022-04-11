package Acme::CPANModules::Symlink;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-Symlink'; # DIST
our $VERSION = '0.001'; # VERSION

our $description = <<'_';

**Creating**

Perl provides the `symlink` builtin.

<pm:Setup::File::Symlink> can create/fix/delete symlink. Part of the Setup
module family, the functions in this module are idempotent with transaction/undo
support.


**Finding**

Perl provides the `-l` operator to test if a file or filehandle is a symbolic
link. This performs an `lstat()` call, which unlike `stat()` can detect if a
handle is symbolic link.


**Testing**

<pm:Test::Symlink>

<pm:File::MoreUtil> provides some utilities that are symlink-aware, like
`l_abs_path` and `file_exists`.


**Other utilities**

<pm:File::Symlink::Relative> creates relative symbolic links.

<pm:File::Symlink::Util> provides utility routines related to symlinks.


**More specific utilities**

<pm:File::LinkTree::Builder>

<prog:short> (from <pm:App::short>).

<prog:lntree> (from <pm:App::lntree) to create a mirror based on symlinks.


**Windows symlinks**

<pm:Win32::NTFS::Symlink>

_

our $LIST = {
    summary => "List of modules that deal with symbolic links (symlinks)",
    description => $description,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules that deal with symbolic links (symlinks)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Symlink - List of modules that deal with symbolic links (symlinks)

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Symlink (from Perl distribution Acme-CPANModules-Symlink), released on 2022-03-18.

=head1 DESCRIPTION

B<Creating>

Perl provides the C<symlink> builtin.

L<Setup::File::Symlink> can create/fix/delete symlink. Part of the Setup
module family, the functions in this module are idempotent with transaction/undo
support.

B<Finding>

Perl provides the C<-l> operator to test if a file or filehandle is a symbolic
link. This performs an C<lstat()> call, which unlike C<stat()> can detect if a
handle is symbolic link.

B<Testing>

L<Test::Symlink>

L<File::MoreUtil> provides some utilities that are symlink-aware, like
C<l_abs_path> and C<file_exists>.

B<Other utilities>

L<File::Symlink::Relative> creates relative symbolic links.

L<File::Symlink::Util> provides utility routines related to symlinks.

B<More specific utilities>

L<File::LinkTree::Builder>

L<short> (from L<App::short>).

L<lntree> (from <pm:App::lntree) to create a mirror based on symlinks.

B<Windows symlinks>

L<Win32::NTFS::Symlink>

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Setup::File::Symlink> - Setup symlink (existence, target)

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Test::Symlink> - Test::Builder based test for symlink correctness

Author: L<NIKC|https://metacpan.org/author/NIKC>

=item * L<File::MoreUtil> - File-related utilities

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<File::Symlink::Relative> - Create relative symbolic links

Author: L<WYANT|https://metacpan.org/author/WYANT>

=item * L<File::Symlink::Util> - Utilities related to symbolic links

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<File::LinkTree::Builder> - builds a tree of symlinks based on file metadata

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item * L<App::short> - Manage short directory symlinks

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Win32::NTFS::Symlink> - Support for NTFS symlinks and junctions on Microsoft

Author: L<BAYMAX|https://metacpan.org/author/BAYMAX>

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

 % cpanm-cpanmodules -n Symlink

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Symlink | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Symlink -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Symlink -E'say $_->{module} for @{ $Acme::CPANModules::Symlink::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Symlink>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Symlink>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Symlink>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

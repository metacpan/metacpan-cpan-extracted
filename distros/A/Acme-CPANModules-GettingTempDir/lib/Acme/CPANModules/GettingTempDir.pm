package Acme::CPANModules::GettingTempDir;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-GettingTempDir'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of ways of getting system-wide temporary directory in a portable way',
    description => <<'_',

There's the good ol' <pm:File::Spec> which has a `tmpdir` function. On Unix it
looks at `TMPDIR` environment variable before falling back to `/tmp`.
<pm:File::Temp> uses this for its `tempdir` when a template is not specified.

Then there's <pm:File::Util::Tempdir> which tries a little harder. On Unix, its
`get_tempdir` will look at `TMPDIR`, then also `TEMPDIR`, `TMP`, `TEMP`. If none
of those are set, it will return the first existing directory from the list:
`/tmp`, `/var/tmp`. If everything fails, will die.

File::Util::Tempdir also provides `get_user_tempdir` which returns a
user-private temporary directory, which can be useful if you want to create
temporary file with predetermined names. It will return temporary directory
pointed by `XDG_RUNTIME_DIR` (e.g. `/run/user/1000`) or, if unavailable, will
create a subdirectory under the world-writable temporary directory (e.g.
`/tmp/1000`).

_
    tags => ['task'],
    entries => [
        {
            module=>'File::Spec',
        },
        {
            module=>'File::Util::Tempdir',
        },
    ],
};

1;
# ABSTRACT: List of ways of getting system-wide temporary directory in a portable way

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::GettingTempDir - List of ways of getting system-wide temporary directory in a portable way

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::GettingTempDir (from Perl distribution Acme-CPANModules-GettingTempDir), released on 2023-10-29.

=head1 DESCRIPTION

There's the good ol' L<File::Spec> which has a C<tmpdir> function. On Unix it
looks at C<TMPDIR> environment variable before falling back to C</tmp>.
L<File::Temp> uses this for its C<tempdir> when a template is not specified.

Then there's L<File::Util::Tempdir> which tries a little harder. On Unix, its
C<get_tempdir> will look at C<TMPDIR>, then also C<TEMPDIR>, C<TMP>, C<TEMP>. If none
of those are set, it will return the first existing directory from the list:
C</tmp>, C</var/tmp>. If everything fails, will die.

File::Util::Tempdir also provides C<get_user_tempdir> which returns a
user-private temporary directory, which can be useful if you want to create
temporary file with predetermined names. It will return temporary directory
pointed by C<XDG_RUNTIME_DIR> (e.g. C</run/user/1000>) or, if unavailable, will
create a subdirectory under the world-writable temporary directory (e.g.
C</tmp/1000>).

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<File::Spec>

Author: L<XSAWYERX|https://metacpan.org/author/XSAWYERX>

=item L<File::Util::Tempdir>

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

 % cpanm-cpanmodules -n GettingTempDir

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries GettingTempDir | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=GettingTempDir -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::GettingTempDir -E'say $_->{module} for @{ $Acme::CPANModules::GettingTempDir::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-GettingTempDir>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-GettingTempDir>.

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-GettingTempDir>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

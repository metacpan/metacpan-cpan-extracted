package Acme::CPANModules::PERLANCAR::Task::GettingTempDir;

our $DATE = '2018-09-20'; # DATE
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'Getting system-wide temporary directory in a portable way',
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
# ABSTRACT: Getting system-wide temporary directory in a portable way

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Task::GettingTempDir - Getting system-wide temporary directory in a portable way

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::PERLANCAR::Task::GettingTempDir (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2018-09-20.

=head1 DESCRIPTION

Getting system-wide temporary directory in a portable way.

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

=head1 INCLUDED MODULES

=over

=item * L<File::Spec>

=item * L<File::Util::Tempdir>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

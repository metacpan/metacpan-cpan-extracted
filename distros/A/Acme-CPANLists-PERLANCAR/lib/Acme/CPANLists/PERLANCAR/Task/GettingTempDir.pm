package Acme::CPANLists::PERLANCAR::Task::GettingTempDir;

our $DATE = '2017-07-01'; # DATE
our $VERSION = '0.23'; # VERSION

our @Module_Lists = (
    {
        summary => 'Getting system-wide temporary directory in a portable way',
        description => <<'_',

There's the good ol' <pm:File::Spec> which has a `tmpdir` function. On Unix it
looks at `TMPDIR` environment variable before falling back to `/tmp`.
<pm:File::Temp> uses this for its `tempdir` when a template is not specified.

Then there's <pm:File::Util::Tempdir> which tries a little harder. On Unix, its
`get_tempdir` will look at `TMPDIR`, then also `TEMPDIR`, `TMP`, `TEMP`. If none
of those are set, it will return the first existing directory from the list:
`/tmp`, `/var/tmp`. If everything fails, will die.

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
    },
);

1;
# ABSTRACT: Getting system-wide temporary directory in a portable way

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Task::GettingTempDir - Getting system-wide temporary directory in a portable way

=head1 VERSION

This document describes version 0.23 of Acme::CPANLists::PERLANCAR::Task::GettingTempDir (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-07-01.

=head1 MODULE LISTS

=head2 Getting system-wide temporary directory in a portable way

There's the good ol' L<File::Spec> which has a C<tmpdir> function. On Unix it
looks at C<TMPDIR> environment variable before falling back to C</tmp>.
L<File::Temp> uses this for its C<tempdir> when a template is not specified.

Then there's L<File::Util::Tempdir> which tries a little harder. On Unix, its
C<get_tempdir> will look at C<TMPDIR>, then also C<TEMPDIR>, C<TMP>, C<TEMP>. If none
of those are set, it will return the first existing directory from the list:
C</tmp>, C</var/tmp>. If everything fails, will die.


=over

=item * L<File::Spec>

=item * L<File::Util::Tempdir>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

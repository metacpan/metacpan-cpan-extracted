package Acme::CPANLists::PERLANCAR::LocalCPANMirror;

our $DATE = '2017-07-28'; # DATE
our $VERSION = '0.25'; # VERSION

our @Module_Lists = (
    {
        summary => 'Creating a local CPAN mirror',
        description => <<'_',

Since CPAN repository is just a hierarchy of files, you can simply use a
recursive download/mirror tool over http/https/ftp. However, for additional
features you can take a look at the modules in this list.

_
        entries => [
            {
                module=>'CPAN::Mini',
                description => <<'_',

This module lets you create a so-called "mini mirror", which only contains the
newest release for each distribution (where CPAN might also contains previous
versions of a distribution as long as the CPAN author does not clean up his
previous releases). This produces a significantly smaller CPAN mirror which you
can use on your PC/laptop for offline development use.

_
            },
            {
                module=>'App::lcpan',
                description => <<'_',

This application not only lets you download a CPAN mini mirror (using
<pm:CPAN::Mini> actually) but also index the package list and distribution
metadata into a SQLite database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.

_
            },
        ],
    },
);

1;
# ABSTRACT: Creating a local CPAN mirror

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::LocalCPANMirror - Creating a local CPAN mirror

=head1 VERSION

This document describes version 0.25 of Acme::CPANLists::PERLANCAR::LocalCPANMirror (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-07-28.

=head1 MODULE LISTS

=head2 Creating a local CPAN mirror

Since CPAN repository is just a hierarchy of files, you can simply use a
recursive download/mirror tool over http/https/ftp. However, for additional
features you can take a look at the modules in this list.


=over

=item * L<CPAN::Mini>

This module lets you create a so-called "mini mirror", which only contains the
newest release for each distribution (where CPAN might also contains previous
versions of a distribution as long as the CPAN author does not clean up his
previous releases). This produces a significantly smaller CPAN mirror which you
can use on your PC/laptop for offline development use.


=item * L<App::lcpan>

This application not only lets you download a CPAN mini mirror (using
L<CPAN::Mini> actually) but also index the package list and distribution
metadata into a SQLite database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.


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

L<Acme::CPANLists::PERLANCAR::CustomCPAN>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Acme::CPANModules::LocalCPANIndex;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Creating an index against local CPAN mirror',
    description => <<'_',

Since CPAN repository index is just a couple of text files (currently: list of
authors in `authors/01mailrc.txt.gz` and list of packages in
`modules/02packages.details.txt.gz`), to perform more complex or detailed
queries additional index is often desired. The following modules accomplish
that.

_
    entries => [
        {
            module=>'App::lcpan',
            description => <<'_',

In addition to downloading a CPAN mini mirror (using <pm:CPAN::Mini>), this
utility also indexes the package list and distribution metadata into a SQLite
database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.

_
        },
        {
            module=>'CPAN::SQLite',
            description => <<'_',

This module parses the two CPAN text file indexes (`authors/01mailrc.txt.gz` and
`modules/02packages.details.txt.gz`) and puts the information into a SQLite
database. This lets you perform queries more quickly without reparsing the text
files each time. But it does not parse distribution metadata so you don't get
additional querying capability like dependencies.

_
        },
    ],
};

1;
# ABSTRACT: Creating an index against local CPAN mirror

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::LocalCPANIndex - Creating an index against local CPAN mirror

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::LocalCPANIndex (from Perl distribution Acme-CPANModules-LocalCPANIndex), released on 2019-01-09.

=head1 DESCRIPTION

Creating an index against local CPAN mirror.

Since CPAN repository index is just a couple of text files (currently: list of
authors in C<authors/01mailrc.txt.gz> and list of packages in
C<modules/02packages.details.txt.gz>), to perform more complex or detailed
queries additional index is often desired. The following modules accomplish
that.

=head1 INCLUDED MODULES

=over

=item * L<App::lcpan>

In addition to downloading a CPAN mini mirror (using L<CPAN::Mini>), this
utility also indexes the package list and distribution metadata into a SQLite
database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.


=item * L<CPAN::SQLite>

This module parses the two CPAN text file indexes (C<authors/01mailrc.txt.gz> and
C<modules/02packages.details.txt.gz>) and puts the information into a SQLite
database. This lets you perform queries more quickly without reparsing the text
files each time. But it does not parse distribution metadata so you don't get
additional querying capability like dependencies.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-LocalCPANIndex>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-LocalCPANIndex>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-LocalCPANIndex>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::LocalCPANMirror>

L<Acme::CPANModules::CustomCPAN>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

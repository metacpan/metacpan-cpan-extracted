package Acme::CPANModules::API::Dead::Currency;

our $DATE = '2018-10-07'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Marking dead currency APIs",
    description => <<'_',

CPAN is full of unmaintained modules, including dead API's. Sadly, there's
currently no easy way to mark such modules (CPANRatings is also dead, MetaCPAN
only lets us ++ a module), hence this list.

_
    entries => [
        {module=>'Finance::Currency::Convert::WebserviceX'},
        {module=>'Finance::Currency::Convert'},
        {module=>'Finance::Currency::Convert::XE'},
        {module=>'Finance::Currency::Convert::Yahoo'},
    ],
};

1;
# ABSTRACT: Marking dead currency APIs

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::API::Dead::Currency - Marking dead currency APIs

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::API::Dead::Currency (from Perl distribution Acme-CPANModules-API-Dead-Currency), released on 2018-10-07.

=head1 DESCRIPTION

Marking dead currency APIs.

CPAN is full of unmaintained modules, including dead API's. Sadly, there's
currently no easy way to mark such modules (CPANRatings is also dead, MetaCPAN
only lets us ++ a module), hence this list.

=head1 INCLUDED MODULES

=over

=item * L<Finance::Currency::Convert::WebserviceX>

=item * L<Finance::Currency::Convert>

=item * L<Finance::Currency::Convert::XE>

=item * L<Finance::Currency::Convert::Yahoo>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-API-Dead-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-API-Dead-Currency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-API-Dead-Currency>

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

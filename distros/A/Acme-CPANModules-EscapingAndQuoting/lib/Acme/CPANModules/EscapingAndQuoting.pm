package Acme::CPANModules::EscapingAndQuoting;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-23'; # DATE
our $DIST = 'Acme-CPANModules-EscapingAndQuoting'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Various modules that escape/quote data to make it safe',
    entries => [
        {
            module=>'HTML::Entities',
        },
        {
            module=>'URI::Escape',
            alternate_modules => ['URI::Escape::XS'],
        },
        {
            module=>'String::PodQuote',
        },
        {
            module=>'String::ShellQuote',
            alternate_modules => ['Win32::ShellQuote', 'ShellQuote::Any', 'ShellQuote::Any::Tiny'],
        },
        {
            module=>'String::ShellQuote',
        },
        {
            module=>'String::Escape',
        },
        {
            module=>'String::JS',
        },
        {
            module=>'Unicode::Escape',
        },
        {
            module=>'TeX::Encode',
        },
        {
            module=>'String::PerlQuote',
        },
        {
            module=>'MIME::Base64',
        },
        {
            module=>'Data::Clean',
        },
        {
            module=>'Data::Clean::ForJSON',
        },
    ],
};

1;
# ABSTRACT: Various modules that escape/quote data to make it safe

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::EscapingAndQuoting - Various modules that escape/quote data to make it safe

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::EscapingAndQuoting (from Perl distribution Acme-CPANModules-EscapingAndQuoting), released on 2019-12-23.

=head1 DESCRIPTION

Various modules that escape/quote data to make it safe.

=head1 INCLUDED MODULES

=over

=item * L<HTML::Entities>

=item * L<URI::Escape>

Alternate modules: L<URI::Escape::XS>

=item * L<String::PodQuote>

=item * L<String::ShellQuote>

Alternate modules: L<Win32::ShellQuote>, L<ShellQuote::Any>, L<ShellQuote::Any::Tiny>

=item * L<String::ShellQuote>

=item * L<String::Escape>

=item * L<String::JS>

=item * L<Unicode::Escape>

=item * L<TeX::Encode>

=item * L<String::PerlQuote>

=item * L<MIME::Base64>

=item * L<Data::Clean>

=item * L<Data::Clean::ForJSON>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-EscapingAndQuoting>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-EscapingAndQuoting>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-EscapingAndQuoting>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

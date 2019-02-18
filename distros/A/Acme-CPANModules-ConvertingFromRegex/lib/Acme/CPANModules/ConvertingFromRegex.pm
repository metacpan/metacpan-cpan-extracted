package Acme::CPANModules::ConvertingFromRegex;

our $DATE = '2019-02-17'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Convert a regular expression to various stuffs',
    tags => ['task'],
    entries => [
        {module=>'PPIx::Regexp', summary=>'To a PPI object'},
        {module=>'Regexp::Stringify', summary=>'To Perl string representation'},
    ],
};

1;
# ABSTRACT: Convert a regular expression to various stuffs

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ConvertingFromRegex - Convert a regular expression to various stuffs

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ConvertingFromRegex (from Perl distribution Acme-CPANModules-ConvertingFromRegex), released on 2019-02-17.

=head1 DESCRIPTION

Convert a regular expression to various stuffs.

=head1 INCLUDED MODULES

=over

=item * L<PPIx::Regexp> - To a PPI object

=item * L<Regexp::Stringify> - To Perl string representation

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ConvertingFromRegex>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ConvertingFromRegex>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ConvertingFromRegex>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::ConvertingToRegex>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

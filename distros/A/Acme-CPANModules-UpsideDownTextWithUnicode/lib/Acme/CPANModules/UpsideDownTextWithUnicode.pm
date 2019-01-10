package Acme::CPANModules::UpsideDownTextWithUnicode;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules that can flip Latin text (make your text '.
        'look upside down) using Unicode characters',
    entries => [
        {
            module=>'Text::UpsideDown',
            summary => 'First released in 2008, comes with a CLI called `ud`',
        },
        {
            module => 'Acme::Flip',
            summary => 'A 2009 reinvention of Text::UpsideDown, without any CLI',
        },
    ],
};

1;
# ABSTRACT: Modules that can flip Latin text (make your text look upside down) using Unicode characters

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::UpsideDownTextWithUnicode - Modules that can flip Latin text (make your text look upside down) using Unicode characters

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::UpsideDownTextWithUnicode (from Perl distribution Acme-CPANModules-UpsideDownTextWithUnicode), released on 2019-01-09.

=head1 DESCRIPTION

Modules that can flip Latin text (make your text look upside down) using Unicode characters.

=head1 INCLUDED MODULES

=over

=item * L<Text::UpsideDown> - First released in 2008, comes with a CLI called `ud`

=item * L<Acme::Flip> - A 2009 reinvention of Text::UpsideDown, without any CLI

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-UpsideDownTextWithUnicode>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-UpsideDownTextWithUnicode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-UpsideDownTextWithUnicode>

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

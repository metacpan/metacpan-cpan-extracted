package Acme::CPANLists::PERLANCAR::UpsideDownTextWithUnicode;

our $DATE = '2017-09-08'; # DATE
our $VERSION = '0.26'; # VERSION

our @Module_Lists = (
    {
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
    },
);

1;
# ABSTRACT: Modules that can flip Latin text (make your text look upside down) using Unicode characters

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::UpsideDownTextWithUnicode - Modules that can flip Latin text (make your text look upside down) using Unicode characters

=head1 VERSION

This document describes version 0.26 of Acme::CPANLists::PERLANCAR::UpsideDownTextWithUnicode (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-09-08.

=head1 MODULE LISTS

=head2 Modules that can flip Latin text (make your text look upside down) using Unicode characters

=over

=item * L<Text::UpsideDown> - First released in 2008, comes with a CLI called `ud`

=item * L<Acme::Flip> - A 2009 reinvention of Text::UpsideDown, without any CLI

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

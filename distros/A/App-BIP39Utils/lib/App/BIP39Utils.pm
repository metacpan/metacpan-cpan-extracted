package App::BIP39Utils;

our $DATE = '2018-01-01'; # DATE
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Collection of CLI utilities related to BIP39

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BIP39Utils - Collection of CLI utilities related to BIP39

=head1 VERSION

This document describes version 0.002 of App::BIP39Utils (from Perl distribution App-BIP39Utils), released on 2018-01-01.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
BIP39:

=over

=item * L<bip39-mnemonic-to-entropy>

=item * L<entropy-to-bip39-mnemonic>

=item * L<gen-bip39-mnemonic>

=back

Keywords: bitcoin, cryptocurrency, BIP, bitcoin improvement proposal, mnemonic
phrase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-BIP39Utils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BIP39Utils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BIP39Utils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.bitcoin.it/wiki/Mnemonic_phrase>

L<https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki>

L<WordList::EN::BIP39> and BIP39 for the other languages in
C<WordList::*::BIP39>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

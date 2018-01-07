package Bitcoin::Mnemonic;

our $DATE = '2018-01-06'; # DATE
our $VERSION = '0.002'; # VERSION

use alias::module 'Bitcoin::BIP39';

1;
# ABSTRACT: Alias package for Bitcoin::BIP39

__END__

=pod

=encoding UTF-8

=head1 NAME

Bitcoin::Mnemonic - Alias package for Bitcoin::BIP39

=head1 VERSION

This document describes version 0.002 of Bitcoin::Mnemonic (from Perl distribution Bitcoin-BIP39), released on 2018-01-06.

=head1 SYNOPSIS

Use like you would L<Bitcoin::BIP39>.

=head1 FUNCTIONS


=head2 bip39_mnemonic_to_entropy

Usage:

 bip39_mnemonic_to_entropy(%args) -> any

Convert BIP39 mnemonic phrase to entropy.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<encoding> => I<str> (default: "hex")

=item * B<language> => I<str> (default: "en")

Pick which language wordlist to use.

Will retrieve wordlist from C<< WordList::E<lt>LANG_CODEE<gt>::BIP39 >> Perl module.

For Chinese (simplified), use C<zh-simplified>. For Chinese (traditional), use
C<zh-traditional>.

=item * B<mnemonic>* => I<str>

Mnemonic phrase.

=back

Return value:  (any)


=head2 entropy_to_bip39_mnemonic

Usage:

 entropy_to_bip39_mnemonic(%args) -> any

Convert entropy to BIP39 mnemonic phrase.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<entropy> => I<buf>

Entropy (binary data).

=item * B<entropy_hex> => I<hexbuf>

Entropy (hex-encoded).

=item * B<language> => I<str> (default: "en")

Pick which language wordlist to use.

Will retrieve wordlist from C<< WordList::E<lt>LANG_CODEE<gt>::BIP39 >> Perl module.

For Chinese (simplified), use C<zh-simplified>. For Chinese (traditional), use
C<zh-traditional>.

=back

Return value:  (any)


=head2 gen_bip39_mnemonic

Usage:

 gen_bip39_mnemonic(%args) -> any

Generate BIP39 mnemonic phrase.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bits> => I<posint> (default: 128)

Size of entropy in bits.

=item * B<language> => I<str> (default: "en")

Pick which language wordlist to use.

Will retrieve wordlist from C<< WordList::E<lt>LANG_CODEE<gt>::BIP39 >> Perl module.

For Chinese (simplified), use C<zh-simplified>. For Chinese (traditional), use
C<zh-traditional>.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bitcoin-BIP39>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bitcoin-BIP39>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bitcoin-BIP39>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bitcoin::BIP39>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

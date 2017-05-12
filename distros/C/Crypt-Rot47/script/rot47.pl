#!/usr/bin/perl
use strict;
use warnings;
use Crypt::Rot47 qw(rot47);

# Parse the command-line arguments
my ($inputText) = @ARGV;
if (!defined $inputText || @ARGV != 1)
{
    die qq(Usage: rot47.pl "Some string to encrypt or decrypt");
}

# Output the resulting encrypted or decrypted text
my $outputText = rot47($inputText);
print "$outputText\n";

__END__

=head1 NAME

rot47.pl - Applies the simple ROT47 substitution cipher to the supplied text.

=head1 SYNOPSIS

  perl rot47.pl "Some string to encrypt or decrypt"
  $@>6 DEC:?8 E@ 6?4CJAE @C 564CJAE

  perl rot47.pl "$@>6 DEC:?8 E@ 6?4CJAE @C 564CJAE"
  Some string to encrypt or decrypt

=head1 DESCRIPTION

Applies the simple ROT47 substitution cipher to the supplied text. Note that for the ROT47 substitution cipher, encryption and decryption are the same operation, executing rot47.pl on its output text produces its input text again.

=head1 SEE ALSO

C<Crypt::Rot47> - Encryption and decryption of ASCII text using the ROT47 substitution cipher.

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary D. Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
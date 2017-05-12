package Crypt::Skip32::XS;

use strict;
use warnings;

our $VERSION = '0.06';
$VERSION = eval $VERSION;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    DynaLoader::bootstrap(__PACKAGE__, $VERSION);
};

1;

__END__

=head1 NAME

Crypt::Skip32::XS - Drop-in replacement for Crypt::Skip32

=head1 SYNOPSIS

    use Crypt::Skip32::XS;

    $cipher     = Crypt::Skip32::XS->new($key);
    $ciphertext = $cipher->encrypt($plaintext);
    $plaintext  = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

The C<Crypt::Skip32::XS> module is similar in function to C<Crypt::Skip32>,
but is substantially faster as it is written in C/XS instead of pure Perl.

NOTE: As of version 0.10, Crypt::Skip32 automatically uses this module if
it is installed.

=head1 METHODS

=over

=item new

    $cipher = Crypt::Skip32::XS->new($key);

Creates a new Crypt::Skip32::XS cipher object with the given key. The key
B<must> be 10 bytes long.

=item encrypt

    $ciphertext = $cipher->encrypt($plaintext);

Encrypts plaintext and returns the ciphertext.  The plaintext B<must> be of 4
bytes long.

=item decrypt

    $plaintext = $cipher->decrypt($ciphertext);

Decrypts ciphertext and returns the plaintext.  The ciphertext B<must> be 4
bytes long.

=item blocksize

    $blocksize = $cipher->blocksize;
    $blocksize = Crypt::Skip32::XS->blocksize;

Returns the size (in bytes) of the block cipher, which is always 4.

=item keysize

    $keysize = $cipher->keysize;
    $keysize = Crypt::Skip32::XS->keysize;

Returns the size (in bytes) of the key, which is always 10.

=back

=head1 PERFORMANCE

This distribution contains a benchmarking script which compares
C<Crypt::Skip32::XS> with C<Crypt::Skip32>.  These are the results on a
MacBook 2GHz with Perl 5.8.8:

    Benchmark: running perl, xs for at least 1 CPU seconds...
          perl:  1 wallclock secs ( 1.07 usr +  0.01 sys =  1.08 CPU) @ 3555.56/s (n=3840)
            xs:  1 wallclock secs ( 1.08 usr +  0.01 sys =  1.09 CPU) @ 263044.95/s (n=286719)
             Rate  perl    xs
    perl   3542/s    --  -99%
    xs   263474/s 7339%    --

=head1 SEE ALSO

L<Crypt::Skip32>

L<http://en.wikipedia.org/wiki/Skipjack_(cipher)>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to 
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Crypt-Skip32-XS>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Skip32::XS

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/crypt-skip32-xs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Skip32-XS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Skip32-XS>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Crypt-Skip32-XS>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Skip32-XS/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut

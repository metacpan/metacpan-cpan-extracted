use strict;
use warnings;

package Crypt::Rijndael::MySQL;

use base 'Crypt::Rijndael';

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $key   = shift;
    
    my @parts = unpack '(A16)*', $key;
    $key = "\0" x 16;
    $key ^= $_ foreach @parts;
    
    my $self = $class->SUPER::new($key, @_);
    bless $self, $class; # force
}

sub encrypt {
    my $self = shift;
    my $data = shift;
    
    my $complement = 16 - length($data) % 16;
    $self->SUPER::encrypt($data . (chr($complement) x $complement), @_);
}

sub decrypt {
    my $self = shift;
    
    my $data = $self->SUPER::decrypt(@_);
    
    my $complement = ord substr($data, -1);
    if (substr($data, -$complement) ne chr($complement) x $complement) {
        require Carp;
        Carp::croak('Incorrect padding (wrong password or broken data?)');
    }
    
    substr($data, 0, length($data) - $complement);
}

1;

__END__

=head1 NAME

Crypt::Rijndael::MySQL - MySQL compatible Rijndael (AES) encryption module

=head1 SYNOPSIS

    use Crypt::Rijndael::MySQL;
  
    $cipher = Crypt::Rijndael::MySQL->new($key, $mode);
    $crypted = $cipher->encrypt($plaintext);
    $plaintext = $cipher->decrypt($crypted);

=head1 DESCRIPTION

This module is a thin wrapper around Crypt::Rijndael, meant for
compatibility with MySQL AES_ENCRYPT() AND AES_DECRYPT() functions. 

=head1 SEE ALSO

L<Crypt::Rijndael>, http://dev.mysql.com/doc/refman/5.1/en/encryption-functions.html

=head1 AUTHOR

Ivan Fomichev, E<lt>ifomichev@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ivan Fomichev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

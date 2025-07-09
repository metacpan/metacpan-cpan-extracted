package Crypt::Bear::AES_CBC::Enc;
$Crypt::Bear::AES_CBC::Enc::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: AES-CBC encoder class in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::AES_CBC::Enc - AES-CBC encoder class in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $encoder = Crypt::Bear::AES_CBC::Enc->new($key);
 my $ciphertext = $d->run($iv, $cipher);

=head1 DESCRIPTION

This class represents an AES-CBC encoder. It's a subclass of L<Crypt::Bear::CBC::Enc> and inherits its C<run> and C<blocksize> methods.

=head1 METHODS

=head2 new($key)

This initializes a new AES_CBC encoder with C<$key>. C<$key> much be appropriately sized for AES (16, 24, or 32 bytes).

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::Bear::AES_CTR;
$Crypt::Bear::AES_CTR::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: AES CTR encoder for BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::AES_CTR - AES CTR encoder for BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $aead = Crypt::Bear::GCM->new(Crypt::Bear::AES_CTR->new($key));

=head1 DESCRIPTION

This creates a new AES in CTRCBC mode object. This is useful when combined with L<CCM|Crypt::Bear::GCM>, but can also be used on its own. It is a sub-class of L<Crypt::Bear::CTR>.

=head1 METHODS

=head2 new($key)

=head2 new($key)

This initializes a new AES_CTR object with C<$key>. C<$key> much be appropriately sized for AES (16, 24, or 32 bytes).

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

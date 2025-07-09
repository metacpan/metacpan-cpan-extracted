package Crypt::Bear::GCM;
$Crypt::Bear::GCM::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: GCM implementation for BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::GCM - GCM implementation for BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $aead = Crypt::Bear::GCM->new(Crypt::Bear::AES_CTR->new($key));

 $aead->reset($iv);
 $aead->aad_inject($aad);
 $aead->flip;
 my $ciphertext = $aead->run($plaintext, 1);
 my $tag = $aead->get_tag;

 $aead->reset($iv);
 $aead->aad_inject($aad);
 $aead->flip;
 my $decoded = $aead->run($ciphertext, 0);
 $aead->check_tag($tag)

=head1 DESCRIPTION

This is a subclass of L<Crypt::Bear::AEAD> that implements GCM mode. It needs a L<Crypt::Bear::CTR> such as L<Crypt::Bear::AES_CTR> for this.

=head1 METHODS

=head2 new($ctr)

Creates a new GCM mode object with the given C<CTR> object.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

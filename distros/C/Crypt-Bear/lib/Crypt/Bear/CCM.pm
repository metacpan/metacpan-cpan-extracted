package Crypt::Bear::CCM;
$Crypt::Bear::CCM::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: CCM implementation for BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::CCM - CCM implementation for BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $aead = Crypt::Bear::CCM->new(Crypt::Bear::AES_CTRCBC->new($key));

=head1 DESCRIPTION

This is a subclass of L<Crypt::Bear::AEAD> that implements CCM mode. It needs a L<Crypt::Bear::CTRCBC> such as L<Crypt::Bear::AES_CTRCBC> for this.

=head1 METHODS

=head2 new($ctrcbc)

Creates a new CCM mode object with the given C<CTRCBC> object.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

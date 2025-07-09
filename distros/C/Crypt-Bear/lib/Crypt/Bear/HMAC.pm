package Crypt::Bear::HMAC;
$Crypt::Bear::HMAC::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: HMAC implementations in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::HMAC - HMAC implementations in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $key = Crypt::Bear::HMAC::Key->new('sha256', '0123456789ABCDEF');
 my $digester = Crypt::Bear::HMAC->new($key);

 while(<>) {
     $digester->update($_);
 }
 say unpack 'H*', $digester->out;

=head1 DESCRIPTION

This represents a streaming implementation of hmac on top of common hash functions.

=head1 METHODS

=head2 new($key)

Returns a new HMAC based on the C<$key>, which should be a L<Crypt::Bear::HMAC::Key|Crypt::Bear::HMAC::Key>.

=head2 update(data)

This feeds data to the hasher.

=head2 out()

This returns the hash based on the current state.

=head2 digest()

Return the name of the hash that's being used (e.g. C<'sha256'>)

=head2 size()

This returns the size of the output.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::Bear::HMAC::Key;
$Crypt::Bear::HMAC::Key::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: A key for HMAC computation.

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::HMAC::Key - A key for HMAC computation.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $key = Crypt::Bear::HMAC::Key->new('sha256', '0123456789ABCDEF');
 my $digester = Crypt::Bear::HMAC->new($key);

=head1 DESCRIPTION

This represents a key for HMAC computation with a given hash function.

=head1 METHODS

=head2 new($digest, $key)

This creates a new HMAC key given secret key C<$key> and hash function C<$digest>.

=head2 digest()

Return the name of the hash that's being used (e.g. C<'sha256'>)

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

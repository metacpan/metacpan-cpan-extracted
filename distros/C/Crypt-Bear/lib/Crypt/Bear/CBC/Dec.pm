package Crypt::Bear::CBC::Dec;
$Crypt::Bear::CBC::Dec::VERSION = '0.003';
use Crypt::Bear;

1;

# ABSTRACT: CBC decoder baseclass BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::CBC::Dec - CBC decoder baseclass BearSSL

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This base class represents an CBC decoder, currently it's only implementation is L<Crypt::Bear::AES_CBC::Dec>.

=head1 METHODS

=head2 run($iv, $data)

This runs a CBC decode with the given IV and data, and returns the result.

=head2 block_size()

This returns the blocksize of the cipher.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

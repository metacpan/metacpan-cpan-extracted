package Crypt::OpenSSL3::MAC::Context;
$Crypt::OpenSSL3::MAC::Context::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: Message authentication code instances

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::MAC::Context - Message authentication code instances

=head1 VERSION

version 0.002

=head1 METHODS

=head2 new

=head2 init

=head2 dup

=head2 final

=head2 finalXOF

=head2 get_block_size

=head2 get_param

=head2 get_mac

=head2 get_mac_size

=head2 set_params

=head2 update

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

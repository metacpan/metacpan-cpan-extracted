package Crypt::OpenSSL3::MD::Context;
$Crypt::OpenSSL3::MD::Context::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: message digest instances

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::MD::Context - message digest instances

=head1 VERSION

version 0.002

=head1 METHODS

=head2 new

=head2 init

=head2 clear_flags

=head2 copy

=head2 ctrl

=head2 dup

=head2 final

=head2 final_xof

=head2 get_block_size

=head2 get_md

=head2 get_name

=head2 get_param

=head2 get_size

=head2 get_type

=head2 reset

=head2 set_flags

=head2 set_params

=head2 sign

=head2 sign_init

=head2 sign_final

=head2 sign_update

=head2 squeeze

=head2 test_flags

=head2 update

=head2 verify

=head2 verify_init

=head2 verify_final

=head2 verify_update

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::OpenSSL3::X509::Store::Context;
$Crypt::OpenSSL3::X509::Store::Context::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: An entry in a X509 store context

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::Store::Context - An entry in a X509 store context

=head1 VERSION

version 0.010

=head1 METHODS

=head2 new

=head2 get_cert

=head2 get_chain

=head2 get_error

=head2 get_error_string

=head2 get_error_depth

=head2 get_num_untrusted

=head2 get_param

=head2 get_rpk

=head2 get_untrusted

=head2 init

=head2 init_rpk

=head2 purpose_inherit

=head2 set_cert

=head2 set_default

=head2 set_error

=head2 set_error_depth

=head2 set_param

=head2 set_purpose

=head2 set_rpk

=head2 set_time

=head2 set_trust

=head2 set_trusted_stack

=head2 set_untrusted

=head2 set_verified_chain

=head2 verify

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

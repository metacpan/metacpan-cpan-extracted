package Crypt::OpenSSL3::X509::VerifyParam;
$Crypt::OpenSSL3::X509::VerifyParam::VERSION = '0.005';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: X509 Verification parameters

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::X509::VerifyParam - X509 Verification parameters

=head1 VERSION

version 0.005

=head1 METHODS

=head2 add_policy

=head2 add_host

=head2 clear_flags

=head2 get_auth_level

=head2 get_depth

=head2 get_email

=head2 get_flags

=head2 get_host

=head2 get_hostflags

=head2 get_inh_flags

=head2 get_ip_asc

=head2 get_peername

=head2 get_purpose

=head2 get_time

=head2 set_auth_level

=head2 set_depth

=head2 set_email

=head2 set_flags

=head2 set_host

=head2 set_hostflags

=head2 set_inh_flags

=head2 set_ip

=head2 set_ip_asc

=head2 set_purpose

=head2 set_time

=head2 set_trust

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

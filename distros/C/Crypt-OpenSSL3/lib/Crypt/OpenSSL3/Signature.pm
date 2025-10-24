package Crypt::OpenSSL3::Signature;
$Crypt::OpenSSL3::Signature::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: Signature algorithms

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::Signature - Signature algorithms

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $alg = Crypt::OpenSSL3::Signature->fetch('RSA-SHA2-512');
 my $ctx = Crypt::OpenSSL3::PKey::Context->new($pkey);
 $ctx->sign_message_init($alg, { 'pad-mode' => 'pss' });
 while (my $data = $input->get_data) {
   $ctx->sign_message_update($data);
 }
 my $signature = $ctx->sign_message_final;

=head1 DESCRIPTION

This class allows you to fetch various signing mechanisms, it's primary used with L<PKey contexts|Crypt::OpenSSL3::PKey::Context> to initialize signing or verifying.

=head1 METHODS

=head2 fetch

=head2 get_description

=head2 get_name

=head2 is_a

=head2 list_all_provided

=head2 names_list_all

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Crypt::Bear::SSL::Client;
$Crypt::Bear::SSL::Client::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;

1;

# ABSTRACT: A sans-io SSL Client in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::SSL::Client - A sans-io SSL Client in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $trust_anchors = Crypt::Bear::SSL::TrustAnchors->new;
 $trust_anchors->load_file($ca_file);
 my $client = Crypt::Bear::SSL::Client->new($trust_anchors);
 $client->reset('www.example.com');

 my $buffer = '';
 while (!$client->send_ready) {
     syswrite $socket, $client->pull_send;
     sysread $socket, my $buffer, 1024;
     $buffer .= $client->push_received($buffer);

     die "Failed to connect" if $client->is_closed;
 }

 # now we're connected

=head1 DESCRIPTION

This repressents a sans-io SSL client. It is a sub class of L<Crypt::Bear::SSL::Engine>. 

=head1 METHODS

=head2 new($trust_anchors)

This creates a new client object, with the given trust anchors.

=head2 reset($server_name, $resume = false)

Prepare or reset a client context for a new connection.

The C<$server_name> parameter is used to fill the SNI extension; the X.509 validator will also match that name against the server names included in the server's certificate. If the parameter is undef then no SNI extension will be sent, and the X.509 validator will not check presence of any specific name in the received certificate.

Therefore, setting the C<$server_name> to C<undef> shall be reserved to cases where alternate or additional methods are used to ascertain that the right server public key is used (e.g. a "known key" model).

If C<$resume_session> is true and the context was previously used then the session parameters may be reused (depending on whether the server previously sent a non-empty session ID, and accepts the session resumption). The session parameters for session resumption can also be set explicitly with C<set_session_parameters> method.

On failure, the context is marked as failed, and this function returns false. A possible failure condition is when no initial entropy was injected, and none could be obtained from the OS (either OS randomness gathering is not supported, or it failed).

=head2 forget_session()

This means that the next handshake that uses this context will necessarily be a full handshake (this applies both to new connections and to renegotiations).

=head2 set_client_certificate($private_certificate)

This function sets a client certificate chain, that the client will send to the server whenever a client certificate is requested. This certificate uses an EC public key. This sets up a client certificate using a L<Crypt::Bear::SSL::PrivateCertificate> C<$private_certificate>. Trust anchor names sent by the server are ignored.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

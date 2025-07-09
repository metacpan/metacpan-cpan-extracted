package Crypt::Bear::SSL::Server;
$Crypt::Bear::SSL::Server::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;

1;

# ABSTRACT: A sans-io SSL Client in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::SSL::Server - A sans-io SSL Client in BearSSL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $priv_cert = Crypt::Bear::SSL::PrivateCertificate->load('server.crt', 'server.key');
 my $server = Crypt::Bear::SSL::Server->new($priv_cert);
 $server->reset;

 while (!$server->send_ready) {
     sysread $socket, my $buffer, 1024;
     $server->push_received($buffer);
     die "Failed to connect" if $server->is_closed;
     syswrite $socket, $server->pull_send;
 }

=head1 DESCRIPTION

=head1 METHODS

=head2 new($private_certificate)

This creates a new client object, with the given certificate chain and private key.

=head2 reset()

Prepare or reset a client context for a new connection.

=for Pod::Coverage get_client_suites

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

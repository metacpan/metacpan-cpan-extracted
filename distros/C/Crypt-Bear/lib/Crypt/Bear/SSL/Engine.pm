package Crypt::Bear::SSL::Engine;
$Crypt::Bear::SSL::Engine::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Bear;

1;

# ABSTRACT: A sans-io SSL connection base-class in BearSSL

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bear::SSL::Engine - A sans-io SSL connection base-class in BearSSL

=head1 VERSION

version 0.003

=head1 DESCRIPTION

=head1 METHODS

=head2 push_send($data, $flush = false)

This pushes (unencrypted) application data into the buffer, and returns (encrypted) records to be sent over your socket. If C<$flush> is true and any application data is buffered in the system, it will wrap it up into a record and immediately output it.

=head2 push_received($data)

This pushed (encrypted) records received from the socket into the buffer, and returns the (decrypted) applicatoin data.

=head2 pull_send($flush = false)

This will pull any pending records to be send to the other side. This is primarily useful around opening and closing connections when data can't be send yet. If C<$flush> is true, it will create an empty record if no pending data is available, this can be useful for keep-alive purposes.

=head2 send_ready()

This returns true if the connection is ready for application data to be pushed in to be sent to the other side. This is useful to know when you're done connecting. Note that this can also be false when the send buffer is full, sp so it's not very useful for other purposes.

=head2 is_closed()

This returns true if the connection is closed. If this is unexpected you should probably call C<last_error> as well to find out why.

=head2 close()

If, at that point, the context is open and in ready state, then a `close_notify` alert is assembled and marked for sending; this triggers the closure protocol. Otherwise, no such alert is assembled.

=head2 last_error()

The error indicator is C<'ok'> if no error was encountered since the last call to C<reset()>. Other status values are "sticky": they remain set, and prevent all I/O activity, until cleared. Only the reset calls clear the error indicator.

=head2 inject_entropy($data)

Inject some "initial entropy" in the context.

This entropy will be added to what can be obtained from the underlying operating system, if that OS is supported.

This function may be called several times; all injected entropy chunks are cumulatively mixed.

If entropy gathering from the OS is supported and compiled in, then this step is optional. Otherwise, it is mandatory to inject randomness, and the caller MUST take care to push (as one or several successive calls) enough entropy to achieve cryptographic resistance (at least 80 bits, preferably 128 or more). The engine will report an error if no entropy was provided and none can be obtained from the OS.

Take care that this function cannot assess the cryptographic quality of the provided bytes.

In all generality, "entropy" must here be considered to mean "that which the attacker cannot predict". If your OS/architecture does not have a suitable source of randomness, then you can make do with the combination of a large enough secret value (possibly a copy of an asymmetric private key that you also store on the system) AND a non-repeating value (e.g. current time, provided that the local clock cannot be reset or altered by the attacker).

=head2 get_server_name()

For clients, this is the name provided with C<reset>; for servers, this is the name received from the client as part of the ClientHello message. If there is no such name (e.g. the client did not send an SNI extension) then the returned string is empty.

=head2 get_version()

This function returns the protocol version that is used by the engine (e.g. C<'tls-1.2'>). That value is set after sending (for a server) or receiving (for a client) the ServerHello message.

=head2 set_versions($version_min, $version_max)

Set the minimum and maximum supported protocol versions.

Supported values include C<'tls-1.0'>, C<'tls-1.1'>, and C<'tls-1.2'>. C<$version_max> MUST NOT be lower than `version_min`.

=for Pod::Coverage get_session_parameters
set_session_parameters
get_ecdhe_curve

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

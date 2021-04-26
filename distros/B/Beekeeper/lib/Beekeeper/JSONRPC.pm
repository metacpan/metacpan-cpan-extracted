package Beekeeper::JSONRPC;

our $VERSION = '0.01';

=head1 NAME

Beekeeper::JSONRPC - Representation of JSON-RPC objects

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

All Beekeeper RPC calls follow the JSON-RPC 2.0 specification (see L<http://www.jsonrpc.org/specification>).

Constructors on this class are not actually used and are provided just for completeness.

=cut

use Beekeeper::JSONRPC::Request;
use Beekeeper::JSONRPC::Notification;
use Beekeeper::JSONRPC::Response;
use Beekeeper::JSONRPC::Error;

sub request {
    my $class = shift;
    Beekeeper::JSONRPC::Request->new(@_);
}

sub notification {
    my $class = shift;
    Beekeeper::JSONRPC::Notification->new(@_);
}

sub response {
    my $class = shift;
    Beekeeper::JSONRPC::Response->new(@_);
}

sub error {
    my $class = shift;
    Beekeeper::JSONRPC::Error->new(@_);
}

1;

=encoding utf8

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut

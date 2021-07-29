package Beekeeper::JSONRPC::Error;

use strict;
use warnings;

our $VERSION = '0.09';


use overload '""' => sub { $_[0]->{error}->{message} };

sub new {
    my ($class, %args) = @_;

    bless {
        jsonrpc => '2.0',
        id      => undef,
        error   => {
            code    => $args{code}    || -32603,
            message => $args{message} || "Internal error",
            data    => $args{data},
        },
    }, $class;
}

sub id      { $_[0]->{id}               }
sub message { $_[0]->{error}->{message} }
sub code    { $_[0]->{error}->{code}    }
sub data    { $_[0]->{error}->{data}    }

sub success { 0 }

sub TO_JSON { return { %{$_[0]} } }


sub parse_error {
    shift->new(
        code    => -32700,
        message => "Parse error",
        data    => "Invalid JSON was received by the server",
        @_ 
    );
}

sub invalid_request {
    shift->new(
        code    => -32600,
        message => "Invalid request",
        data    => "The JSON sent is not a valid request object.",
        @_ 
    );
}

sub request_timeout {
    shift->new(
        code    => -31600,
        message => "Request timeout",
        @_ 
    );
}

sub request_not_authenticated {
    shift->new(
        code    => -401,
        message => "Not logged in",
        data    => "Request was not authenticated",
        @_ 
    );
}

sub request_not_authorized {
    shift->new(
        code    => -403,
        message => "Request not authorized",
        data    => "Request was not authorized",
        @_ 
    );
}

sub method_not_found {
    shift->new(
        code    => -32601,
        message => "Method not found",
        data    => "The method does not exist",
        @_ 
    );
}

sub method_not_available {
    shift->new(
        code    => -31601,
        message => "Method not available",
        data    => "The method is not available.",
        @_ 
    );
}

sub invalid_params {
    shift->new(
        code    => -32602,
        message => "Invalid params",
        data    => "Invalid method parameters.",
        @_ 
    );
}

sub internal_error {
    shift->new(
        code    => -32603,
        message => "Internal error",
        data    => "Internal JSON-RPC error.",
        @_ 
    );
}

sub server_error {
    shift->new(
        code    => -32000,
        message => "Server error",
        @_ 
    );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::JSONRPC::Error - Representation of a JSON-RPC error
 
=head1 VERSION
 
Version 0.09

=head1 SYNOPSIS

  my $client = Beekeeper::Client->instance;
  
  my $resp = $client->call_remote(
      method => 'myapp.svc.foo',
      params => { foo => 'bar' },
  );
  
  unless ($resp->success) {
      # Error response
      die $resp->code . $resp->message;
  }

=head1 DESCRIPTION

Objects of this class represent a JSON-RPC error (see L<http://www.jsonrpc.org/specification>).

When an RPC call could not be executed successfully the worker replies with a 
L<Beekeeper::JSONRPC::Error> object. These objects may be returned also due to  
client side errors, like network disconnections or timeouts.

Method L<Beekeeper::Client::call_remote> returns objects of this class on failure.

=head1 ACCESSORS

=over

=item message

Returns a string providing a short description of the error.

=item code

Returns a number that indicates the error type that occurred.

=item data

Returns an arbitrary value or data structure containing additional information 
about the error. This may be present or not.

=item id

Returns the id of the request it is responding to. It is unique per client connection,
and it is used for response matching.

=item success

Always returns false. It is used to determine if a method was executed successfully
or not (C<$response-E<gt>result> cannot be trusted as it may be undefined on success).

=back

=head1 CONSTRUCTORS

=head3 new ( %args )

=over

=item message

A string providing a short description of the error.

=item code

A number that indicates the error type that occurred.

Error codes from and including -32768 to -32000 are reserved for predefined
errors of the JSON-RPC spec.

=item data

An arbitrary value or data structure containing additional information 
about the error. This may be present or not.

=back

=head3 server_error ( %args )

=head3 invalid_params ( %args )

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut

package Beekeeper::JSONRPC::Request;

use strict;
use warnings;

our $VERSION = '0.10';


sub new {
    my $class = shift;
    bless {
        jsonrpc => '2.0',
        method  => undef,
        params  => undef,
        id      => undef,
        @_
    }, $class;
}

sub method     { $_[0]->{method} }
sub params     { $_[0]->{params} }
sub id         { $_[0]->{id}     }

sub response {
    $_[0]->{_response};
}

sub result {
    # Shortcut for $req->response->result
    return ($_[0]->{_response}) ? $_[0]->{_response}->{result} : undef;
}

sub success {
    # Shortcut for $req->response->success
    return ($_[0]->{_response}) ? $_[0]->{_response}->success : undef;
}

sub mqtt_properties {
    $_[0]->{_mqtt_properties};
}

sub async_response {
    $_[0]->{_async_response} = 1;
}

sub deflate_response {
    $_[0]->{_deflate_response} = $_[2] || 1024;
}

sub send_response {
    $_[0]->{_worker}->__send_response(@_);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::JSONRPC::Request - Representation of a JSON-RPC request
 
=head1 VERSION
 
Version 0.09

=head1 SYNOPSIS

  my $client = Beekeeper::Client->instance;
  
  my $req = $client->call_remote_async(
      method => 'myapp.svc.foo',
      params => { foo => 'bar' },
  );
  
  $client->wait_async_calls;
  
  die unless ($req->success);
  
  print $req->result;

=head1 DESCRIPTION

Objects of this class represent a JSON-RPC request (see L<http://www.jsonrpc.org/specification>).

The method L<Beekeeper::Client::call_remote_async> returns objects of this class.

On worker classes the method handlers setted by L<Beekeeper::Worker::accept_remote_calls> 
will receive these objects as parameters.

=head1 ACCESSORS

=over

=item method

Returns a string with the name of the method invoked.

=item params

Returns the arbitrary data structure passed as parameters.

=item id

A value of any type, which is used to match responses with requests.

=item response

Once the request is complete, it returns the corresponding L<Beekeeper::JSONRPC::Response> 
or L<Beekeeper::JSONRPC::Error> object.

=item result

Once the request is complete, it returns the result encapsulated in the response.

It is just a shortcut for C<$req-E<gt>response-E<gt>result>.

=item success

Once the request is complete, it returns true unless the response is an error. It is 
used to determine if a method was executed successfully or not (C<$response-E<gt>result> 
cannot be trusted as it may be undefined on success).

Returns undef if the request is in still progress.

It is just a shortcut for C<$req-E<gt>response-E<gt>success>.

=item mqtt_properties

Returns a hashref containing the MQTT properties of the request.

=back

=head1 METHODS

=head3 deflate_response ( min_size => $min_size )

Deflate the JSON response for the request before being sent to the caller if it is
longer than `$min_size`. If `$min_size` is not specified a default of 1024 is used.

=head3 async_response

On worker classes remote calls can be processed concurrently by means of calling
C<$req-E<gt>async_response> to tell Beekeeper that the response for the request will
be deferred until it is available, freeing the worker to accept more requests.

Once the response is ready, it must be sent back to the caller with C<$req-E<gt>send_response>.

=head3 send_response ( $val )

Send back to the caller the provided value or data structure as response.

Error responses can be returned sending L<Beekeeper::JSONRPC::Error> objects.

=head1 SEE ALSO
 
L<Beekeeper::Client>, L<Beekeeper::Worker>.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2023 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut

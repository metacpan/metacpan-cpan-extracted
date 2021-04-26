package Beekeeper::JSONRPC::Response;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME
 
Beekeeper::JSONRPC::Response - Representation of a JSON-RPC response.
 
=head1 VERSION
 
Version 0.01

=head1 SYNOPSIS

  my $client = Beekeeper::Client->instance;
  
  my $resp = $client->do_job(
      method => 'myapp.svc.foo',
      params => { foo => 'bar' },
  );
  
  die unless ($resp->success);

  print $resp->result;

=head1 DESCRIPTION

Objects of this class represents a JSON-RPC response (see L<http://www.jsonrpc.org/specification>).

When a RPC call is made the worker replies with a Beekeeper::JSONRPC::Response object
if the invoked method was executed successfully. On error, a Beekeeper::JSONRPC::Error
is returned instead.

Method C<Beekeeper::Client-\>do_job> returns objects of this class on success.

=head1 ACCESSORS

=over 4

=item result

Arbitrary value or data structure returned by the invoked method.
It is undefined if the invoked method does not returns anything.

=item id

The id of the request it is responding to. It is unique per client connection,
and it is used for response matching.

=item success

Always returns true. Used to determine if a method was executed successfully
or not ($response->result cannot be trusted as it may be undefined on success).

=back

=cut

sub new {
    my $class = shift;

    bless {
        jsonrpc => '2.0',
        result  => undef,
        id      => undef,
        @_
    }, $class;
}

sub result  { $_[0]->{result} }
sub id      { $_[0]->{id}     }

sub success { 1 }

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

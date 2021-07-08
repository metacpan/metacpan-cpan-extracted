package Beekeeper::JSONRPC::Response;

use strict;
use warnings;

our $VERSION = '0.07';


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

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::JSONRPC::Response - Representation of a JSON-RPC response
 
=head1 VERSION
 
Version 0.07

=head1 SYNOPSIS

  my $client = Beekeeper::Client->instance;
  
  my $resp = $client->call_remote(
      method => 'myapp.svc.foo',
      params => { foo => 'bar' },
  );
  
  die unless ($resp->success);

  print $resp->result;

=head1 DESCRIPTION

Objects of this class represent a JSON-RPC response (see L<http://www.jsonrpc.org/specification>).

When an RPC call is made the worker replies with a L<Beekeeper::JSONRPC::Response> object
if the invoked method was executed successfully. On error, a L<Beekeeper::JSONRPC::Error>
is returned instead.

Method L<Beekeeper::Client::call_remote> returns objects of this class on success.

=head1 ACCESSORS

=over

=item result

Returns the arbitrary value or data structure returned by the invoked method.
It is undefined if the invoked method does not returns anything.

=item id

Returns the id of the request it is responding to. It is unique per client connection,
and it is used for response matching.

=item success

Always returns true. It is used to determine if a method was executed successfully
or not (C<$response-E<gt>result> cannot be trusted as it may be undefined on success).

=back

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

package Beekeeper::JSONRPC::Request;

use strict;
use warnings;

our $VERSION = '0.05';


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
    # Shortcut for $job->response->result
    return ($_[0]->{_response}) ? $_[0]->{_response}->{result} : undef;
}

sub success {
    # Shortcut for $job->response->success
    return ($_[0]->{_response}) ? $_[0]->{_response}->success : undef;
}

sub mqtt_properties {
    $_[0]->{_mqtt_prop};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::JSONRPC::Request - Representation of a JSON-RPC request.
 
=head1 VERSION
 
Version 0.05

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

Objects of this class represents a JSON-RPC request (see L<http://www.jsonrpc.org/specification>).

Method C<Beekeeper::Client-\>call_remote_async> returns objects of this class.

=head1 ACCESSORS

=over 4

=item method

A string with the name of the method to be invoked.

=item params

An arbitrary data structure to be passed as parameters to the defined method.

=item id

A value of any type, which is used to match responses with requests.

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

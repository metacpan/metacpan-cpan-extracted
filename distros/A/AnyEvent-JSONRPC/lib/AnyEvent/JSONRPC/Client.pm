package AnyEvent::JSONRPC::Client;

use Any::Moose;

no Any::Moose;

__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::JSONRPC::Client - Base class for JSON-RPC clients

=head1 SYNOPSIS

    use AnyEvent::JSONRPC::XXX::Client;
    
    my $client = AnyEvent::JSONRPC::XXX::Client->new(
        ...
    );
    
    # blocking interface
    my $res = $client->call( echo => 'foo bar' )->recv; # => 'foo bar';
    
    # non-blocking interface
    $client->call( echo => 'foo bar' )->cb(sub {
        my $res = $_[0]->recv;  # => 'foo bar';
    });

=head1 DESCRIPTION

This is the base class for clients in the L<AnyEvent::JSONRPC> suite of
modules. Current implementations includes a
L<TCP|AnyEvent::JSONRPC::TCP::Client> client and a
L<HTTP|AnyEvent::JSONRPC::HTTP::Client> client. See these for arguments to the
constructors.

=head2 AnyEvent condvars

The main thing you have to remember is that all the data retrieval methods
return an AnyEvent condvar, C<$cv>.  If you want the actual data from the
request, there are a few things you can do.

=head1 METHODS

=head2 new (%options)

Create new client object and return it.

    my $client = AnyEvent::JSONRPC::TCP::Client->new(
        %options,
    );

Available options are specific to each implementation.

=head2 call ($method, @params)

Call remote method named C<$method> with parameters C<@params>. And return condvar object for response.

    my $cv = $client->call( echo => 'Hello!' );
    my $res = $cv->recv;

If server returns an error, C<< $cv->recv >> causes croak by using C<< $cv->croak >>. So you can handle this like following:

    my $res;
    eval { $res = $cv->recv };
    
    if (my $error = $@) {
        # ...
    }

=head2 notify ($method, @params)

Same as call method, but not handle response. This method just notify to server.

    $client->notify( echo => 'Hello' );

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

package AnyEvent::Ident::Server;

use strict;
use warnings;
use AnyEvent;
use AnyEvent::Socket qw( tcp_server );
use AnyEvent::Handle;
use AnyEvent::Ident::Request;
use AnyEvent::Ident::Response;
use AnyEvent::Ident::Transaction;
use Carp qw( croak carp );

# ABSTRACT: Simple asynchronous ident server
our $VERSION = '0.07'; # VERSION


sub new
{
  my $class = shift;
  my $args  = ref $_[0] eq 'HASH' ? (\%{$_[0]}) : ({@_});
  my $port  = $args->{port};
  $port = 113 unless defined $port;
  bless {
    hostname => $args->{hostname},  
    port     => $port,
    on_error => $args->{on_error} || sub { carp $_[0] },
    on_bind  => $args->{on_bind}  || sub { },
  }, $class;
}


sub start
{
  my($self, $callback) = @_;
  
  croak "already started" if $self->{guard};
  
  my $cb = sub {
    my ($fh, $host, $port) = @_;

    my $handle;
    $handle = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub {
        my ($hdl, $fatal, $msg) = @_;
        $self->{on_error}->($msg);
        $_[0]->destroy;
      },
      on_eof   => sub {
        $handle->destroy;
      },
    );
    
    $handle->on_read(sub {
      $handle->push_read( line => sub {
        my($handle, $line) = @_;
        $line =~ s/\015?\012//g;
        my $req = eval { AnyEvent::Ident::Request->new($line) };
        return $handle->push_write("$line:ERROR:INVALID-PORT\015\012") if $@;
        my $tx = bless { 
          req            => $req,
          remote_port    => $port,
          local_port     => $self->{bindport},
          remote_address => $host,
          cb             => sub {
            my($res) = @_;
            $handle->push_write($res->as_string . "\015\012");
          },
        }, 'AnyEvent::Ident::Transaction';
        $callback->($tx);
      })
    });
  };

  $self->{guard} = tcp_server $self->{hostname}, $self->{port}, $cb, sub {
    my($fh, $host, $port) = @_;
    $self->{bindport} = $port;
    $self->{on_bind}->($self);
  };
  
  $self;
}


sub bindport { shift->{bindport} }


sub stop
{
  my($self) = @_;
  delete $self->{guard};
  delete $self->{bindport};
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Ident::Server - Simple asynchronous ident server

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 use AnyEvent::Ident::Server;
 my $server = AnyEvent::Ident::Server->new;
 
 $server->start(sub {
   my $tx = shift;
   if($tx->req->server_port == 400
   && $tx->req->client_port == 500)
   {
     $tx->reply_with_user('UNIX', 'grimlock');
   }
   else
   {
     $tx->reply_with_error('NO-USER');
   }
 });

=head1 DESCRIPTION

Provide a simple asynchronous ident server.  This class manages 
connections and handles client errors for you, but you have to provide 
an implementation which determines the owner for a connection given a 
server and client port. This class may also be useful for testing ident 
clients against (see the test suite in this distribution, it uses this 
class to test L<AnyEvent::Ident::Client>), or for constructing an ident 
server which always returns the same user (which may be useful for some 
applications, such as IRC).

=head1 CONSTRUCTOR

 my $server = AnyEvent::Ident::Server->new(%args);

The constructor takes the following optional arguments:

=head2 hostname

default 127.0.0.1

The hostname to connect to.

=head2 port

default 113

The port to connect to.

=head2 on_error

default carp error

A callback subref to be called on error (either connection or transmission error).
Passes the error string as the first argument to the callback.

=head2 on_bind

A callback subref to be called when the socket has been bound to a port.  Useful
when using an ephemeral and you do not know the port number in advance.

=head2 start

 $server->start( $callback );

Start the Ident server.  The given callback will be called on each ident
request (there may be multiple ident requests for each connection).  The
first and only argument passed to the callback is the transaction, an
instance of L<AnyEvent::Ident::Transaction>.  The most important attribute
on the transaction object are C<res>, the response object (itself an instance of 
L<AnyEvent::Ident::Transaction> with C<server_port> and C<client_port>
attributes) and the most important methods on the transaction object are
C<reply_with_user> and C<reply_with_error> which reply with a successful and 
error response respectively.

=head2 bindport

 my $port = $server->bindport;

The bind port.  If port is set to zero in the constructor or on
start, then an ephemeral port will be used, and you can get the
port number here.

=head2 stop

 $server-E<gt>stop

Stop the server and unbind to the port.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

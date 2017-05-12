package AnyEvent::Ident::Client;

use strict;
use warnings;
use AnyEvent::Socket qw( tcp_connect );
use AnyEvent::Handle;
use Carp qw( carp );

# ABSTRACT: Simple asynchronous ident client
our $VERSION = '0.07'; # VERSION


sub new
{
  my $class = shift;
  my $args     = ref $_[0] eq 'HASH' ? (\%{$_[0]}) : ({@_});
  my $port = $args->{port};
  $port = 113 unless defined $port;
  bless { 
    hostname       => $args->{hostname}       || '127.0.0.1',  
    port           => $port,
    on_error       => $args->{on_error}       || sub { carp $_[0] },
    response_class => $args->{response_class} || 'AnyEvent::Ident::Response',
  }, $class;
}


sub ident
{
  my($self, $server_port, $client_port, $cb) = @_;
  
  unless(eval { $self->{response_class}->can('new') })
  {
    eval 'use ' . $self->{response_class};
    die $@ if $@;
  }
  
  my $key = join ':', $server_port, $client_port;
  push @{ $self->{$key} }, $cb;
  return if @{ $self->{$key} } > 1;
  
  # if handle is defined then the connection is open and we can push 
  # the request right away.
  if(defined $self->{handle})
  {
    $self->{handle}->push_write("$server_port,$client_port\015\012");
    return;
  }
  
  # if handle is not defined, but wait is, then we are waiting for
  # the connection, and we queue up the request
  if(defined $self->{wait})
  {
    push @{ $self->{wait} }, "$server_port,$client_port\015\012";
    return;
  }
  
  $self->{wait} = [];
  
  tcp_connect $self->{hostname}, $self->{port}, sub {
    my($fh) = @_;
    return $self->_cleanup->{on_error}->("unable to connect: $!") unless $fh;
    
    $self->{handle} = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub {
        my ($hdl, $fatal, $msg) = @_;
        $self->{on_error}->($msg);
        $self->_cleanup;
        $_[0]->destroy;
        delete $self->{handle};
      },
      on_eof   => sub {
        $self->_cleanup;
        $self->{handle}->destroy;
       delete $self->{handle};
      },
    );
    
    $self->{handle}->push_write("$server_port,$client_port\015\012");
    $self->{handle}->push_write($_) for @{ $self->{wait} };
    delete $self->{wait};
    
    $self->{handle}->on_read(sub {
      $self->{handle}->push_read( line => sub {
        my($handle, $line) = @_;
        $line =~ s/\015?\012//g;
        my $res = $self->{response_class}->new($line);
        my $key = $res->_key;
        if(defined $self->{$key})
        {
          $_->($res) for @{ $self->{$key} };
          delete $self->{$key};
        }
      });
    });
  };
  
  return $self;
}


sub _cleanup
{
  my $self = shift;
  foreach my $key (grep /^(\d+):(\d+)$/, keys %$self)
  {
    $_->($self->{response_class}->new("$1,$2:ERROR:UNKNOWN-ERROR"))
      for @{ $self->{$key} };
    delete $self->{$key};
  }
  $self;
}

sub close
{
  my $self = shift;
  if(defined $self->{handle})
  {
    $self->_cleanup;
    $self->{handle}->destroy;
    delete $self->{handle};
    delete $self->{wait};
  }
}

sub DESTROY
{
  shift->close;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Ident::Client - Simple asynchronous ident client

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 use AnyEvent::Ident::Client;
 
 my $client = AnyEvent::Ident::Client->new( hostname => 127.0.0.1' );
 $client->ident($server_port, $client_port, sub {
   my($res) = @_; # isa AnyEvent::Client::Response 
   if($res->is_success)
   {
     print "user: ", $res->username, "\n";
     print "os:   ", $res->os, "\n";
   }
   else
   {
     warn "Ident error: " $res->error_type;
   }
 });

=head1 CONSTRUCTOR

 my $client = AnyEvent::Ident::Client->new(%args);

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

=head2 response_close

default L<AnyEvent::Ident::Response>

Bless the response object into the given class.  This class SHOULD inherit from
L<AnyEvent::Ident::Response>, or at least mimic its interface.  This allows you
to define your own methods for the response class.

=head1 METHODS

=head2 ident

 $client->ident( $server_port, $client_port, $callback );

Send an ident request to the ident server with the given TCP port pair.
The callback will be called when the response is returned from the
server.  Its only argument will be an instance of 
L<AnyEvent::Ident::Response>.

On the first call to this method, a connection to the ident server
is opened, and will remain open until C<close> (see below) is called,
or if the C<$client> object falls out of scope.

=head2 close

 $client->close;

Close the connection to the ident server.  Requests that are in progress will
receive an error response with the type C<UNKNOWN-ERROR>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package AnyEvent::FTP::Server;

use strict;
use warnings;
use 5.010;
use Moo;
use AnyEvent::Handle;
use AnyEvent::Socket qw( tcp_server );
use AnyEvent::FTP::Server::Connection;
use Socket qw( unpack_sockaddr_in inet_ntoa );

# ABSTRACT: Simple asynchronous ftp server
our $VERSION = '0.17'; # VERSION


$AnyEvent::FTP::Server::VERSION //= 'dev';

with 'AnyEvent::FTP::Role::Event';

__PACKAGE__->define_events(qw( bind connect ));


has hostname => (
  is       => 'ro',
);


has port => (
  is      => 'ro',
  default => sub { 21 },
);


has default_context => (
  is      => 'ro',
  default => sub { 'AnyEvent::FTP::Server::Context::FSRW' },
);


has welcome => (
  is      => 'ro',
  default => sub { [ 220 => "aeftpd $AnyEvent::FTP::Server::VERSION" ] },
);


has bindport => (
  is => 'rw',
);


has inet => (
  is      => 'ro',
  default => sub { 0 },
);

sub BUILD
{
  eval 'use ' . shift->default_context;
  die $@ if $@;
}


sub start
{
  my($self) = @_;
  $self->inet ? $self->_start_inet : $self->_start_standalone;
}

sub _start_inet
{
  my($self) = @_;

  my $con = AnyEvent::FTP::Server::Connection->new(
    context => $self->{default_context}->new,
    ip      => do {
      my $sockname = getsockname STDIN;
      my ($sockport, $sockaddr) = unpack_sockaddr_in ($sockname);
      inet_ntoa ($sockaddr);
    },
  );

  my $handle;
  $handle = AnyEvent::Handle->new(
    fh => *STDIN,
      on_error => sub {
        my($hdl, $fatal, $msg) = @_;
        $con->close;
        $_[0]->destroy;
        undef $handle;
        undef $con;
      },
      on_eof   => sub {
        $con->close;
        $handle->destroy;
        undef $handle;
        undef $con;
      },
  );

  $self->emit(connect => $con);

  STDOUT->autoflush(1);
  STDIN->autoflush(1);

  $con->on_response(sub {
    my($raw) = @_;
    print STDOUT $raw;
  });

  $con->on_close(sub {
    close STDOUT;
    exit;
  });

  $con->send_response(@{ $self->welcome });

  $handle->on_read(sub {
    $handle->push_read( line => sub {
      my($handle, $line) = @_;
      $con->process_request($line);
    });
  });

  $self;
}

sub _start_standalone
{
  my($self) = @_;

  my $prepare = sub {
    my($fh, $host, $port) = @_;
    $self->bindport($port);
    $self->emit(bind => $port);
  };

  my $connect = sub {
    my($fh, $host, $port) = @_;

    my $con = AnyEvent::FTP::Server::Connection->new(
      context => $self->{default_context}->new,
      ip => do {
        my($port, $addr) = unpack_sockaddr_in getsockname $fh;
        inet_ntoa $addr;
      },
    );

    my $handle;
    $handle = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub {
        my($hdl, $fatal, $msg) = @_;
        $con->close;
        $_[0]->destroy;
        undef $handle;
        undef $con;
      },
      on_eof   => sub {
        $con->close;
        $handle->destroy;
        undef $handle;
        undef $con;
      },
    );

    $self->emit(connect => $con);

    $con->on_response(sub {
      my($raw) = @_;
      $handle->push_write($raw);
    });

    $con->on_close(sub {
      $handle->push_shutdown;
    });

    $con->send_response(@{ $self->welcome });

    $handle->on_read(sub {
      $handle->push_read( line => sub {
        my($handle, $line) = @_;
        $con->process_request($line);
      });
    });

  };

  tcp_server $self->hostname, $self->port || undef, $connect, $prepare;

  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server - Simple asynchronous ftp server

=head1 VERSION

version 0.17

=head1 SYNOPSIS

 use AnyEvent;
 use AnyEvent::FTP::Server;
 
 my $server = AnyEvent::FTP::Server->new;
 $server->start;
 AnyEvent->condvar->recv;

=head1 DESCRIPTION

B<CAUTION> L<AnyEvent::FTP::Server> hasn't been audited by anyone, including
its author, in order to ensure that it is secure.  It is intended to be used
primarily in testing the companion client L<AnyEvent::FTP::Client>.  It can
also be used to write your own context or personality (to use the L<Net::FTPServer>
terminology) that use alternate back ends (say a database or memory store)
that could theoretically be made to be secure, but you will need to carefully
vett both the L<AnyEvent::FTP::Server> code as well as your own customizations
before you deploy on the Internet or on an untrusted network.

This class is used for L<AnyEvent::FTP> server instances.
Each time a client connects to the server a L<AnyEvent::FTP::Server::Connection>
instance is created to manage the TCP connection.  Each connection
also has a L<AnyEvent::FTP::Server::Context> which defines the behavior or
personality of the server, and each context instance keeps track of the
current directory, user authentication and authorization status of each
connected client.

=head1 ATTRIBUTES

=head2 hostname

 my $hostname = $server->hostname;

Readonly, and should be assigned at the constructor. The hostname to listen
on.

=head2 port

 my $port = $server->port;

The port to listen to. Default is 21 - a different port can be assigned
at the constructor.

=head2 default_context

 my $context = $server->default_context;

Readonly: the default context class (can be set as a parameter in the
constructor).

=head2 welcome

 my($code, $message) = @{ $server->welcome };

The welcome messages as key value pairs. Read only and can be overridden by
the constructor.

=head2 bindport

 my $port = $server->bindport;
 $server->bindport($port);

Retrieves or sets the TCP port to bind to.

=head2 inet

 my $bool = $server->inet;

Readonly (assignable via the constructor). If true, then assume a TCP
connection has been established by inet. The default (false) is to start
a standalone server.

=head1 METHODS

=head2 start

 $server->start;

Call this method to start the service.

=head1 SEE ALSO

L<Net::FTPServer>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

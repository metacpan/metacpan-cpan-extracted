package AnyEvent::Finger::Client;

use strict;
use warnings;
use AnyEvent::Socket qw( tcp_connect );
use AnyEvent::Handle;
use Carp qw( carp );

# ABSTRACT: Simple asynchronous finger client
our $VERSION = '0.14'; # VERSION


sub new
{
  my $class = shift;
  my $args  = ref $_[0] eq 'HASH' ? (\%{$_[0]}) : ({@_});
  my $port  = $args->{port};
  $port = 79 unless defined $port;
  bless {
    hostname => $args->{hostname} || '127.0.0.1',
    port     => $port,
    timeout  => $args->{timeout}  || 60,
    on_error => $args->{on_error} || sub { carp $_[0] },
  }, $class;
}


sub finger
{
  my $self     = shift;
  my $request  = shift;
  $request = '' unless defined $request;
  my $callback = shift || sub {};
  my $args     = ref $_[0] eq 'HASH' ? (\%{$_[0]}) : ({@_});

  for(qw( hostname port timeout on_error ))
  {
    next if defined $args->{$_};
    $args->{$_} = $self->{$_};
  }

  tcp_connect $args->{hostname}, $args->{port}, sub {

    my($fh) = @_;
    return $args->{on_error}->("unable to connect: $!") unless $fh;

    my @lines;

    my $handle;
    $handle = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub {
        my ($hdl, $fatal, $msg) = @_;
        $args->{on_error}->($msg);
        $_[0]->destroy;
      },
      on_eof   => sub {
        $handle->destroy;
        $callback->(\@lines);
      },
    );

    if(ref $request && $request->isa('AnyEvent::Finger::Request'))
    { $request = $request->{raw} }
    $handle->push_write("$request\015\012");

    $handle->on_read(sub {
      $handle->push_read( line => sub {
        my($handle, $line) = @_;
        $line =~ s/\015?\012//g;
        push @lines, $line;
      });
    });

  }, sub { $args->{timeout} };

  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Finger::Client - Simple asynchronous finger client

=head1 VERSION

version 0.14

=head1 SYNOPSIS

 use AnyEvent;
 use AnyEvent::Finger::Client;
 
 my $done = AnyEvent->condvar;
 
 my $client = AnyEvent::Finger::Client->new(
   hostname => 'localhost',
 );
 
 $client->finger('username', sub {
   my($lines) = @_;
   print "[response]\n";
   print join "\n", @$lines;
 }, on_error => sub {
   print STDERR shift;
 });

=head1 DESCRIPTION

Provide a simple asynchronous finger client.

=head1 CONSTRUCTOR

 my $client = AnyEvent::Finger::Client->new(%options);

The constructor takes the following optional arguments:

=over 4

=item *

hostname (default 127.0.0.1)

The hostname to connect to.

=item *

port (default 79)

The port to connect to.

=item *

timeout (default 60)

The connection timeout.

=item *

on_error (carp error)

A callback subref to be called on error (either connection or transmission error).
Passes the error string as the first argument to the callback.

=back

=head1 METHODS

=head2 finger

 $client->finger($request, $callback, [ \%options ])

Connect to the finger server make the given request and call the given callback
when the response is complete.  The response will be passed to the callback as
an array reference of lines.  Each line will have the new line (\n or \r or \r\n)
removed.  Any of the arguments passed into the constructor as passed above
may be overridden specifying them in the options hash (third argument).

=head1 SEE ALSO

=over 4

=item L<AnyEvent::Finger>

=item L<AnyEvent::Server>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

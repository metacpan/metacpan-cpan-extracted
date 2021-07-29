package AnyEvent::FTP::Server::Context;

use strict;
use warnings;
use 5.010;
use Moo;

# ABSTRACT: FTP Server client context class
our $VERSION = '0.17'; # VERSION

with 'AnyEvent::FTP::Role::Event';
with 'AnyEvent::FTP::Server::Role::Context';

__PACKAGE__->define_events(qw( auth ));

has ready => (
  is      => 'rw',
  default => sub { 1 },
);

has ascii_layer => (
  is      => 'rw',
  default => ':raw:eol(CRLF-Native)'
);

sub push_request
{
  my($self, $con, $req) = @_;

  push @{ $self->{request_queue} }, [ $con, $req ];

  $self->process_queue if $self->ready;

  $self;
}

sub process_queue
{
  my($self) = @_;

  return $self unless @{ $self->{request_queue} } > 0;

  $self->ready(0);

  my($con, $req) = @{ shift @{ $self->{request_queue} } };

  my $command = lc $req->command;

  if($self->can('auth_command_check_hook'))
  {
    return unless $self->auth_command_check_hook($con, $command);
  }

  my $method = join '_', 'cmd', $command;

  if($self->can($method))
  {
    $self->$method($con, $req);
  }
  else
  {
    $self->invalid_command($con, $req);
  }

  $self;
}

sub invalid_command
{
  my($self, $con, $req) = @_;
  $con->send_response(500 => $req->command . ' not understood');
  $self->done;
}

sub invalid_syntax
{
  my($self, $con, $raw) = @_;
  $con->send_response(500 => 'Command not understood');
  $self->done;
}

sub help_quit { "QUIT" }

sub cmd_quit
{
  my($self, $con, $req) = @_;
  $con->send_response(221 => 'Goodbye');
  $con->close;
  $self;
}

sub done
{
  my($self) = @_;
  $self->ready(1);
  $self->process_queue;
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Context - FTP Server client context class

=head1 VERSION

version 0.17

=head1 METHODS

=head2 cmd_quit

 $ctx->cmd_quit($con, $req);

Sends a quit command through $con ($req is unused.). Returns the $ctx object.

=head2 done

 $ctx->done;

B<TODO>: document. Returns the $ctx object.

=head2 help_quit

 my $quit_str = $ctx->help_quit;

Returns the string "QUIT".

=head2 invalid_command

 $ctx->invalid_command($con, $req);

Sends an invalid command due to the request $req through $con.

=head2 invalid_syntax

 $ctx->invalid_syntax($con, $raw);

Sends a command not understood response through $con.

=head2 process_queue

 $ctx->process_queue;

Processes the request queue.

=head2 push_request

 $ctx->push_request($con, $req);

Pushes the request to the queue.

=head2 ready

 my $bool = $ctx->ready;
 $ctx->ready($bool)

Gets or sets the "is ready" status, which is a boolean.

=head2 ascii_layer

 $ctx->ascii_layer;

The L<PerlIO> layer to apply for writing (C<STOR>, C<STOU>, C<APPE>) and
reading (C<RETR>) when operating under ASCII file transfer mode.  By
default a layer that takes C<CRLF> and emits native line endings is used
for writing and a takes native line endings and emits C<CRLF> when reading
is used.

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

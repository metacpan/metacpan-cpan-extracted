package AnyEvent::FTP::Client::Transfer;

use strict;
use warnings;
use 5.010;
use Moo;
use AnyEvent;
use AnyEvent::Handle;
use Carp qw( confess );

# ABSTRACT: Transfer class for asynchronous ftp client
our $VERSION = '0.20'; # VERSION


# TODO: implement ABOR


with 'AnyEvent::FTP::Role::Event';


__PACKAGE__->define_events(qw( open close eof ));

has cv => (
  is      => 'ro',
  lazy    => 1,
  default => sub { AnyEvent->condvar },
);

has client => (
  is       => 'ro',
  required => 1,
);

has remote_name => (
  is      => 'rw',
  lazy    => 1,
  default => sub { shift->command->[1] },
);

has local => (
  is       => 'ro',
  required => 1,
);

has command => (
  is       => 'ro',
  required => 1,
);

has restart => (
  is      => 'ro',
  default => sub { 0 },
  coerce  => sub { $_[0] // 0 },
);


sub cb { shift->{cv}->cb(@_) }
sub ready { shift->{cv}->ready }
sub recv { shift->{cv}->recv }

sub handle
{
  my($self, $fh) = @_;

  my $handle;
  $handle = AnyEvent::Handle->new(
    fh => $fh,
    on_error => sub {
      my($hdl, $fatal, $msg) = @_;
      $self->emit('eof');
      $_[0]->destroy;
    },
    on_eof => sub {
      $self->emit('eof');
      $handle->destroy;
    },
    # this avoids deep recursion exception error (usually
    # a warning) in example fput.pl when the buffer is
    # small (1024 on my debian VM)
    autocork  => 1,
  );

  $self->emit(open => $handle);

  $handle;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Transfer - Transfer class for asynchronous ftp client

=head1 VERSION

version 0.20

=head1 SYNOPSIS

 use AnyEvent::FTP::Client;
 my $client = AnyEvent::FTP::Client;
 $client->connect('ftp://ftp.cpan.org')->cb(sub {
 
   # $upload_transfer and $download_transfer are instances of
   # AnyEvent::FTP::Client::Transfer
   my $upload_transfer = $client->stor('remote_filename.txt', 'content');
 
   my $buffer;
   my $download_transfer = $client->retr('remote_filename.txt', \$buffer);
 
 });

=head1 DESCRIPTION

This class represents a file transfer with a remote server.  Transfers
may be initiated between a remote file name and a local object.  The
local object may be a regular scalar, reference to a scalar or a file
handle, for details, see the C<stor>, C<stou>, C<appe> and C<retr>
methods in L<AnyEvent::FTP::Client>.

This documentation covers what you can do with the transfer object once it
has been initiated.

=head1 ROLES

This class consumes these roles:

=over 4

=item *

L<AnyEvent::FTP::Role::Event>

=back

=head1 EVENTS

This class provides these events:

=head2 open

Emitted when the data connection is opened, and passes in as its first argument
the L<AnyEvent::Handle> instance used to transfer the file.

 $xfer->on_open(sub {
   my($handle) = @_;
   # $handle isa AnyEvent::Handle
 });

=head2 close

Emitted when the transfer is complete, either due to a successful transfer or
the server returned a failure status.  Passes in the final
L<AnyEvent::FTP::Client::Response> message associated with the transfer.

 $xfer->on_close(sub {
   my($res) = @_;
   # $res isa AnyEvent::FTP::Client::Response
 });

=head2 eof

Emitted when the data connection closes.

 $xfer->on_eof(sub {
   # no args passed in
 });

=head1 METHODS

=head2 cb

Register a callback with the transfer to be executed when the transfer
successfully completes, or fails. Works exactly like the L<AnyEvent> condition
variable C<cb> method.

=head2 ready

Returns true if the transfer has completed (either successfully or not).  If true, then it is safe to call
C<recv> to retrieve the response (Some event loops do not support calling C<recv> before there is a message
waiting).

=head2 recv

Retrieve the L<AnyEvent::FTP::Client::Response> object.

=head2 remote_name

For C<STOU> transfers ONLY, this returns the remote file name.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

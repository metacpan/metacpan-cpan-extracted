package AnyEvent::Handle::Writer;

use 5.8.8;
use common::sense 2;m{
use strict;
use warnings;
}x;
use AnyEvent::Handle;
use AnyEvent::Util;
BEGIN{ push our @ISA, 'AnyEvent::Handle'; }

=head1 NAME

AnyEvent::Handle::Writer - Extended version of AnyEvent::Handle with additional write options

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

   use AnyEvent;
   use AnyEvent::Handle::Writer;

   my $hdl; $hdl = AnyEvent::Handle::Writer->new(
      fh => $fh,
      on_error => sub {
         my ($hdl, $fatal, $msg) = @_;
         warn "got error $msg\n";
         $hdl->destroy;
      }
   );

   # Custom writer
   $hdl->push_write(sub {
      my $h = shift;
      if ($have_data) {
         $h->unshift_write($data);
         return 1; # Work done
      } else {
         return 0; # Work not done, call me again
      }
   });

   # sendfile
   $hdl->push_sendfile('/path/to/file', 1024);

=head1 RATIONALE

We have great l<AnyEvent::Handle>. But it have only raw write queue. This module extends it with
callbacks in write queue and adds a C<push_sendfile()> call, which would be processed at correct time

=head1 METHODS

=cut

=head2 push_write($data)

L<AnyEvent::Handle/WRITE_QUEUE>

=head2 push_write(type => @args)

L<AnyEvent::Handle/WRITE_QUEUE>

=head2 push_write($cb->($handle))

This version of call allow to push a callback, which will be invoked when the write queue before it became empty.

   Callback should return:
      true  - when there is no work to be done with this callback.
              it will be removed from queue and continue
      false - when it want to be called again (i.e. not all work was done)
              it will be kept in queue and called on next drain

This call allow us to implement such a thing:

   $handle->push_write("HTTP/1.1 200 OK\012\015\012\015");
   $handle->push_write(sub {
      # Manual work on handle
      my $h = shift;
      my $len = syswrite($h->{fh}, $data); # Here may be also sendfile work
      if (defined $len) {
         diag "written $len";
         substr $data, 0, $len, "";
         if (length $data) {
            return 0; # want be called again
         } else {
            return 1; # all done
         }
      } elsif (!$!{EAGAIN} and !$!{EINTR} and !$!{WSAEWOULDBLOCK}) {
         $h->_error ($!, 1);
         return 1; # No more requests to me, got an error
      }
      else { return 0; }
   });
   $handle->push_write("HTTP/1.1 200 OK\012\015\012\015");
   $handle->push_write("Common response");

=head2 unshift_write($data)
=head2 unshift_write(type => @args)
=head2 unshift_write($cb->($handle))

Analogically to C<unshift_read>, it unshift write data at the beginngin of queue. B<The only recommended usage is from write callback>

   $handle->push_write("1")
   $handle->push_write(sub {
      my $h = shift;
      $h->unshift_write("2");
      return 1;
   });
   $handle->push_write("3");
   
   # The output will be "123"

=cut


sub new {
   my $pkg = shift;
   my $self;
   my %args = @_;
   $args{on_drain} = _shadow_on_drain(delete $args{on_drain});
   $self = $pkg->AnyEvent::Handle::new(%args);
   $self;
}

sub _shadow_on_drain {
   my $old = shift;
   return sub {
      my $h = shift;
      #warn "on drain called";
      #warn "Ready ".int $h;
      $h->{_writer_buffer_clean} = 1;
      if (@{ $h->{_writer_wbuf} || [] }) {
         $h->_drain_writer_wbuf;
      } else {
         $old->($h) if defined $old;
      }
   };
}

sub push_write {
   my $self = shift;
   #warn "push_write ";
   if (@_ > 1) {
      my $type = shift;

      @_ = ($AnyEvent::Handle::WH{$type} ||= AnyEvent::Handle::_load_func "$type\::anyevent_write_type"
            or Carp::croak "unsupported/unloadable type '$type' passed to AnyEvent::Handle::push_write")
           ->($self, @_);
   }
   if (ref $_[0] or @{ $self->{_writer_wbuf} }) {
      push @{ $self->{_writer_wbuf} }, $_[0];
   } else {
      $self->{_writer_buffer_clean} = 0;
      $self->AnyEvent::Handle::push_write(@_);
   }
   $self->_drain_writer_wbuf;
}

sub unshift_write {
   my $self = shift;
   if (@_ > 1) {
      my $type = shift;

      @_ = ($AnyEvent::Handle::WH{$type} ||= AnyEvent::Handle::_load_func "$type\::anyevent_write_type"
            or Carp::croak "unsupported/unloadable type '$type' passed to AnyEvent::Handle::push_write")
           ->($self, @_);
   }
   if (ref $_[0]) {
      unshift @{ $self->{_writer_wbuf} }, $_[0];
   } else {
      if ($self->{_writer_buffer_clean}) {
         $self->{_writer_buffer_clean} = 0;
         $self->AnyEvent::Handle::push_write(@_);
      } else {
         unshift @{ $self->{_writer_wbuf} }, $_[0];
      }
   }
   $self->_drain_writer_wbuf;
}

sub _drain_writer_wbuf {
   #warn "call my_drain";
   my $self = shift;
   if (ref $self->{_writer_wbuf}[0]) {
      if($self->{_writer_wbuf}[0]->($self)) {
         shift @{$self->{_writer_wbuf}};
         # Write nothing but call AE::Handle logic
      };
      unless($self->{_ww} or length $self->{_wbuf} ) {
      	$self->{_writer_ww} = AE::io $self->{fh}, 1, sub {
      		delete $self->{_writer_ww};
      		$self->_drain_writer_wbuf;
      	}
      } else {
         $self->_drain_wbuf;
      }
      #syswrite($self->{fh},'');
   } else {
      #warn "Not a cb";
      $self->AnyEvent::Handle::push_write(shift @{$self->{_writer_wbuf}});
   }
}

sub on_drain {
   my ($self,$cb) = @_;
   $cb = _shadow_on_drain($cb);
   $self->AnyEvent::Handle::on_drain($cb);
}

=head2 push_sendfile($filename, [$size, [$offset]]);

Push sendfile operation into write queue. If sendfile cannot be found (L<Sys::Sendfile>)
or if it fails with one of ENOSYS, ENOTSUP, EOPNOTSUPP, EAFNOSUPPORT, EPROTOTYPE or ENOTSOCK, it will be emulated with chunked read/write

   $handle->push_write("HTTP/1.0 200 OK\nContent-length: $size\n...\n\n");
   $handle->push_sendfile($file, $size, $offset);

=cut

our $NO_SENDFILE;

sub push_sendfile {
   my $self = shift;
   my $file = shift;
   my $size = shift;
   my $offset = shift;
   my $do_sendfile = 0;
   if (!$self->{tls} and !$NO_SENDFILE) {
      eval { 
         require Sys::Sendfile;
         $do_sendfile = 1;
      } or $NO_SENDFILE = 1;
   }
   my $f;
   my $open = sub {
      if (open $f, '<:raw', $file) {
         $size ||= (stat $f)[7];
         $offset ||= 0;
         #warn "Successfully opened file $file: $size | ".fileno($f);
         AnyEvent::Util::fh_nonblocking $f, 1;
         return 1;
      } else {
         #warn "open failed: $!";
         $self->_error($!,1); # Fatal error, write queue became broken
         return 0;
      }
   };
      my $emulation = sub {
         $open->() or return 1 unless $f;
         my $h = $_[0];
         my $buf;
         # Here I'm assume, that reading from fs is faster, than writing to socket.
         # So I don't create io watcher on filehandle.
         # When we're asked to give a write data, we're trying to read it
         my $read = sysread($f,$buf,($self->{read_size} || 8192));
         #warn "sysread()=$read";
         if (defined $read and $read >= 0) {
            #warn "read $read";
            $size -= $read;
            if ($read > 0) {
               $h->unshift_write($buf);
               return 0;
            }
            elsif ($size > 0) {
               return 0;
            }
            else { # EOF
               close $f;
               if ($size > 0) {
                  warn "File $file was truncated during sendfile.\n\tHave to sent $size more, but got EOF";
                  #$h->_error ($!, 1);
               }
               return 1;
            }
         }
         elsif ($!{EAGAIN} or $!{EINTR} or $!{WSAEWOULDBLOCK}) {
            # warn "retry $!";
            return 0; # Call me later
         }
         else {
            # warn "failed with error $!";
            $h->_error ($!, 1);
            close $f;
            return 1; # No more requests to me, got an error
         }
      };
      my $sendfile = sub {
         goto &$emulation unless $do_sendfile;
         $open->() or return 1 unless $f;
         # warn "sendfile";
         my $h = $_[0];
         my $len = Sys::Sendfile::sendfile($h->{fh}, $f, $size, $offset);
         if (defined $len) {
            # warn "Written $len by sendfile $!";
            $offset += $len;
            $size -= $len;
            if ($size > 0) {
            	# warn "want more (+$size)";
               return 0; # want be called again
            } else {
            warn "all done";
               close $f;
               return 1; # done
            }
         }
         elsif ($!{EAGAIN} or $!{EINTR} or $!{WSAEWOULDBLOCK}) {
            return 0; # Call me later
         }
         elsif ($!{EINVAL}) {
            warn "Fallback to emulation because of $!\n";
            $do_sendfile = 0;
            goto &$emulation;
         }
         elsif ( $!{EINVAL} or $!{ENOSYS} or $!{ENOTSUP} or $!{EOPNOTSUPP} or $!{EAFNOSUPPORT} or $!{EPROTOTYPE} or $!{ENOTSOCK} ) {
            $do_sendfile = 0;
            goto &$emulation;
         }
         else {
         	warn "sendfile: $!";
            $h->_error ($!, 1);
            close $f;
            return 1; # No more requests to me, got an error
         }
      };
      $self->push_write($do_sendfile ? $sendfile : $emulation);
}

#sub DESTROY {
#	my $self = shift;
#	warn "DESTROY handle";
#	return $self->AnyEvent::Handle::DESTROY;
#}

1;

=head1 ACKNOWLEDGEMENTS


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1; # End of AnyEvent::Handle::Writer

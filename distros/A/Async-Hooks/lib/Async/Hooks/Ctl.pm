package Async::Hooks::Ctl;
{
  $Async::Hooks::Ctl::VERSION = '0.16';
}

# ABSTRACT: Hook control object

use strict;
use warnings;

# $self is a arrayref with three positions:
#   . first  is a arrayref with hooks to call;
#   . second is a arrayref with the arguments of each hook;
#   . third is the cleanup sub: always called even when done().
#

sub new { return bless [undef, $_[1] || [], $_[2] || [], $_[3]], $_[0] }

sub args { return $_[0][2] }

# stop() or done() stops the chain
sub done {
  my $ctl = $_[0];

  @{$ctl->[1]} = ();

  return $ctl->_cleanup(1);
}

*stop = \&done;


# decline(), declined() or next() will call the next hook in the chain
sub decline {
  my $ctl = $_[0];

  my $hook = shift @{$ctl->[1]};
  return $hook->($ctl, $ctl->[2]) if $hook;

  return $ctl->_cleanup(0);
}

*declined = \&decline;
*next     = \&declined;


# _cleanup ends the chain processing
sub _cleanup {
  my ($ctl, $is_done) = @_;

  return unless my $cleanup = $ctl->[3];
  return $cleanup->($ctl, $ctl->[2], $is_done || 0);
}

1;    # End of Async::Hooks::Ctl


__END__
=pod

=head1 NAME

Async::Hooks::Ctl - Hook control object

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    # inside a callback

    sub my_callback {
      my $ctl = shift;     # This is the Async::Hooks::Ctl object
      my $args = shift;    # Arguments for the hook

      $args = $ctl->args;  # Args are also available with the args() method

      return $ctl->done;          # no other callbacks are called
                           # ... or ...
      return $ctl->decline;       # call next callback
    }

=head1 DESCRIPTION

A C<Async::Hooks::Ctl> object controls the sequence of invocation of
callbacks.

Each callback receives two parameters: a C<Async::Hooks::Ctl> object,
and a arrayref with the hook arguments.

Each callback must call one of the sequence control methods before
returning. Usually you just write:

    return $ctl->done();
    # ... or ...
    return $ctl->decline();

If you know what you are doing, you can also do this:

    $ctl->decline();
    # do other stuff here
    return;

But there are no guarantees that your code after the control method call
will be run at the end of the callback sequence.

The important rule is that you must call one and only one of the control
methods per callback.

The object provides two methods that control the invocation sequence,
C<decline()> and C<done()>. The C<done()> method will stop the sequence,
and no other callback will be called. The C<decline()> method will call
the next callback in the sequence.

A cleanup callback can also be defined, and it will be called at the end
of all callbacks, or imediatly after C<done()>. This callback receives a
third argument, a flag C<$is_done>, that will be true if the chain
ended with a call to C<done()> or C<stop()>.

The C<decline()> method can also be called as C<declined()> or
C<next()>. The C<done()> method can also be called as C<stop()>.

=head1 METHODS

=over

=item CLASS->new($hooks, $args, $cleanup)

The C<new()> constructor returns a C<Async::Hooks::Ctl> object. All
parameters are optional.

=over

=item * $hooks

An arrayref with all the callbacks to call.

=item * $args

An arrayref with all the hook arguments.

=item * $cleanup

A coderef with the cleanup callback to use.

=back

=item $ctl->args()

Returns the hook arguments.

=item $ctl->decline()

Calls the next callback in the hook sequence.

If there are no callbacks remaining and if a cleanup callback was
defined, it will be called with the C<$is_done> flag as false.

=item $ctl->declined()

An alias to C<< $ctl->decline() >>.

=item $ctl->next()

An alias to C<< $ctl->decline() >>.

=item $ctl->done()

Stops the callback sequence. No other callbacks in the sequence will
be called.

If a cleanup callback was defined, it will be called with the
C<$is_done> flag as true.

=item $ctl->stop()

An alias to C<< $ctl->done() >>.

=back

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


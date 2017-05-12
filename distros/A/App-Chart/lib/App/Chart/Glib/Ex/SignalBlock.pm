# or add() take one object and multiple ids
# or new() accept signalids object too



# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Glib::Ex::SignalBlock;
use 5.008;
use strict;
use warnings;
use Carp;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my $class = shift;
  my $self = bless [], $class;
  $self->add (@_);
  return $self;
}

sub new_from_signalids {
  my ($class, $ids) = @_;
  return $class->new ($ids->object, $ids->ids);
}

sub add {
  my $self = shift;
  ### SignalBlock on: "@pairs"
  if ((@_ & 1) != 0) {
    croak "SignalBlock expects even number of arguments for object,id pairs";
  }
  require Scalar::Util;
  while (@_) {
    my $object = shift @_;
    my $id = shift @_;
    $object->handler_block ($id);
    push @$self, $object,$id;
    Scalar::Util::weaken ($self->[-2]);
  }
}

sub add_signalids {
  my $self = shift;
  while (@_) {
    my $signalids = shift;
    my $object = $signalids->object;
    foreach my $id ($signalids->ids) {
      $self->add ($object, $id);
    }
  }
}

sub DESTROY {
  my ($self) = @_;
  while (@$self) {
    my $object = shift @$self;
    my $id = shift @$self;
    next if (! defined $object);  # possible weakening

    # could have been disconnected altogether by the application
    if ($object->signal_handler_is_connected ($id)) {
      ### SignalBlock unblock: "$object" . "id=$id"
      $object->handler_unblock ($id);
    }
  }
}

1;
__END__

=head1 NAME

App::Chart::Glib::Ex::SignalBlock -- block signal handlers with scope guard style

=for test_synopsis my ($obj, $id)

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::SignalBlock;
 {
   my $blocker = App::Chart::Glib::Ex::SignalBlock->new ($obj, $id);
   # handler $id for activate is not called
   $obj->activate;
 }
 # until $blocker goes out of scope ...

=head1 DESCRIPTION

B<Not sure about the arguments yet ...>

B<Blocking may be more work than disconnecting and re-connecting ...>

C<App::Chart::Glib::Ex::SignalBlock> temporarily blocks a particular signal handler
connection using C<signal_handler_block>.  When the blocker object is
destroyed it unblocks with C<signal_handler_unblock>.

The idea is that it can be easier to manage the lifespan of an object than
to ensure every exit point from a particular bit of code includes an
unblock.  For example a temporary blocking in a Perl scope, knowing no
matter how it exits (error, goto, return, etc) the signal block will be
undone.

    {
      my $blocker = App::Chart::Glib::Ex::SignalBlock->new ($obj,$id);
      ...
    }

Or objects can help to manage longer lived blocking, so as not to lose track
of things held for a period of time or main loop conditions etc.

It works to nest blockers, done either with SignalBlock or explicit calls.
Glib simply keeps a count of current blocks on each connected ID, which
means there's no need for proper nesting, blockers can overlap in any
fashion.

=head2 Alternatives

You can also simply arrange for your signal handler to do nothing when it
sees a global variable or a flag in an object.

    our $update_in_progress;

    sub my_handler {
      return if $update_in_progress;
      ...
    }

    {
      local $update_in_progress = 1;
      ...
    }

If C<my_handler> is called many times during the "update" the repeated
do-nothing calls could be slow and a block (or disconnect) the signal may be
better.  On the other hand if there's just a few calls then the overhead of
creating a blocker object might be the slowest part.

=head1 FUNCTIONS

=over 4

=item C<< $blocker = App::Chart::Glib::Ex::SignalBlock->new ($object,$id,...) >>

Do a C<< $object->signal_handler_block >> on each given C<$object> and
signal handler C<$id>, and return a SignalBlock object which will make
corresponding C<< $object->signal_handler_unblock >> calls when it's
destroyed.  So for instance if you were thinking of

    $obj->signal_handler_block ($id);
    ...
    $obj->signal_handler_unblock ($id);

instead use

    {
      my $blocker = App::Chart::Glib::Ex::SignalBlock->new ($obj,$id);
      ...
      # automatic signal_handler_unblock when $blocker out of scope
    }

SignalBlock holds weak references to the target objects, so the mere fact a
signal is blocked won't an object alive once nothing else cares if it lives
or dies.

=back

=head1 OTHER NOTES

When there's multiple signals in a SignalBlock it's currently unspecified
what order the unblock calls are made.  (What would be good?  First-in
first-out, or a stack?)  You can create multiple SignalBlock objects and
arrange your blocks to destroyed them in a particular order if it matters.

There's quite a few general purpose block-scope cleanup systems if you want
more than signal blocking.  L<Scope::Guard|Scope::Guard>, L<AtExit|AtExit>,
L<Sub::ScopeFinalizer|Scope::Guard> and L<Guard|Guard> use the destructor
style.  L<Hook::Scope|Hook::Scope> and
L<B::Hooks::EndOfScope|B::Hooks::EndOfScope> manipulate the code in a block.

=head1 SEE ALSO

L<Glib::Object>, L<Glib::Ex::FreezeNotify>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut

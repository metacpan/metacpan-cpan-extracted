# Copyright 2003 by Scott McCoy.  All rights reserved.  Released under
# the same terms as Perl itself.
#
# Portions Copyright 2003 by Rocco Caputo.  All rights reserved.  Released 
# under the same terms as Perl itself.
#
# Portions Copyright 2001-2003 by Maurice Makaay and/or Marcus
# Thiesen.  Released under the same terms as Perl itself.

# Good luck.  Send the author feedback.  Thanks for trying it.  :)
package Curses::UI::POE; 

use warnings FATAL => "all";
use strict;

use POE;
use POSIX qw( fcntl_h );
use base qw( Curses::UI );
use Curses::UI::Widget;

# Force POE::Kernel to have ran...stops my warnings...
# We do it in a BEGIN so there can be no sessions prior
# to our calling this unless somebody is being really, really bad.
BEGIN { run POE::Kernel }

*VERSION = \0.040;
our $VERSION;

use constant TOP => -1;

sub import {
    my $caller = caller;

    no strict "refs";

    *{ $caller . "::MainLoop" } = \&MainLoop;
    eval "package $caller; use POE;";
}

# XXX We assume that there will never be two Curses::UI::POE sessions.
my @modal_objects;
my @modal_callbacks;

# The session needed to make curses run in POE.
sub new {
    my ($type, %options) = @_;
    my $self = &Curses::UI::new(@_);
#   my $self = bless Curses::UI->new, $type;
#   my $self = bless &Curses::UI::new(@_), $type;

    # I have to do this here, because if our first order of business is a
    # dialog then the _start event will be too late.  This self reference is
    # just so we can stack and peel onto the list of modal objects, and get to
    # ourselves when we reach the top.
    push @modal_objects, $self;

    $self->{options}            = \%options;
    $self->{__start_callback}   = delete $options{inline_states}{_start};

    # Default so we don't get a warning about using undef
    $options{package_states}  ||= [];
    $options{object_states}   ||= [];
    $options{inline_states}   ||= {};
    $options{options}         ||= {};

    POE::Session->create
        ( options        => $options{options},
          args           => $options{args},
          inline_states  => $options{inline_states},
          package_states => $options{package_states},

          object_states  => [
            @{ $options{object_states} },
            $self, [ qw( _start init keyin timer shutdown ) ]
          ],
          
          # This is to maintain backward compatibility.
          heap => $self );

    # Copy the no-output option
    $self->{-no_output} = $options{-no_output} || 0;

    return $self;
}

# Wait until the kernel actually starts before we muck with things.
sub _start { $_[KERNEL]->yield("init") }

sub init {
    my ($self, $kernel) = @_[ OBJECT, KERNEL ];

    $kernel->select(\*STDIN, "keyin");

    # Turn blocking back on for STDIN.  Some Curses
    # implementations don't deal well with non-blocking STDIN.
    my $flags = fcntl STDIN, F_GETFL, 0 or die $!;
    fcntl STDIN, F_SETFL, $flags & ~O_NONBLOCK or die $!;

    # If we're in a dialog, then the TOP modal object is more appropriate than
    # $self, although if we're not in a dialog $self is what this actually is.
    set_read_timeout($modal_objects[TOP]);

    # When gpm_mouse isn't enabled, sometimes there is extra garbage during
    # startup.  We ignore that garbage during construction, assuming that since
    # the UI isn't rendered yet (we're still creating the root object!) the
    # input must not matter.
    $self->flushkeys;

    # Unmask...
    $self->{__start_callback}(@_)
        if defined $self->{__start_callback};
}

sub _clear_modal_callback {
    my ($self) = @_;

    my $top     = pop @modal_objects;

    # Reset focus
    $top->{-focus} = 0;

    # Dispatch callback.
    my $args    = pop @modal_callbacks;
    my $sub     = shift @$args;
    &{$sub}(@$args);
}

sub keyin {
    my ($self, $kernel) = @_[ OBJECT, KERNEL ];


    until ((my $key = $self->get_key(0)) eq -1) {
        $self->feedkey($key);

        unless ($#modal_objects) {
            $self->do_one_event;
        }
        else {
            # dispatch the event to the top-most modal object, or the root.
            $self->do_one_event($modal_objects[TOP]);
        }
    }

    # Set the root cursor mode
    unless ($self->{-no_output}) {
        Curses::curs_set($self->{-cursor_mode});
    }
}

sub timer {
    my ($self) = @_;

    # dispatch the event to the top-most modal object, or the root.
    my $top_object = $modal_objects[TOP];

    $top_object->do_timer;

    # Set the root cursor mode.
    unless ($self->{-no_output}) {
        Curses::curs_set($self->{-cursor_mode});
    }

    set_read_timeout($top_object);
}

sub shutdown {
    my ($kernel) = $_[ KERNEL ];

    # Unselect stdin
    $kernel->select(\*STDIN);
}

sub mainloop {
    my ($this) = @_;

    unless ($this->{-no_output}) {
        $this->focus(undef, 1);
        $this->draw;

        Curses::doupdate;
    }



    no warnings "redefine";

    my $modalfocus = \&Curses::UI::Widget::modalfocus;

    # Let modalfocus() be a reentrant into the POE Kernel.  This is stackable,
    # so it should not impact other behaviors, and POE keeps chugging along
    # uneffected.  This is a modal focus without a callback, this method does
    # not return until the modal widget get's cleared out.
    #
    # This is done here so that ->dailog will still work as it did previously.
    # until this is run.  And just in case, we save the old modalfocus
    # definition and redefine it later.
    sub Curses::UI::Widget::modalfocus () {
        my ($this) = @_;

        # "Fake" focus for this object.
        $this->{-has_modal_focus} = 1;
        $this->focus;
        $this->draw;

        push @modal_objects, $this;
        push @modal_callbacks, undef;

        # This is reentrant into the POE::Kernel 
        while ( $this->{-has_modal_focus} ) {
            $poe_kernel->loop_do_timeslice;
        }

        $this->{-focus} = 0;

        pop @modal_callbacks;
        pop @modal_objects;

        return $this;
    }

    POE::Kernel->run;

    # Replace previously defined method into the symbol table.
    *{"Curses::UI::Widget::modalfocus"} = $modalfocus;
}

sub set_read_timeout {
    my $this = shift; 

    my $new_timeout = -1;

    while (my ($id, $config) = each %{$this->{-timers}}) {
        next unless $config->{-enabled};

        $new_timeout = $config->{-time}
        unless $new_timeout != -1 and
            $new_timeout < $config->{-time};
    }

    $poe_kernel->delay(timer => $new_timeout) if $new_timeout >= 0;

    # Force the read timeout to be 0, so Curses::UI polls.
    $this->{-read_timeout} = 0;

    return $this;
}

{
    no warnings "redefine";
    # None of this work's if POE isn't running...
    # Redefine the callbackmodalfocus to ensure that callbacks and objects make
    # it on to our own private stack.
    sub Curses::UI::Widget::callbackmodalfocus {
        my ($this, $cb) = @_;

        # "Fake" focus for this object.
        $this->{-has_modal_focus} = 1;
        $this->focus;
        $this->draw;

        push @modal_objects, $this;

        if (defined $cb) {
            # They need a callback, so register it.
            push @modal_callbacks, $cb;
        } else {
            # Push a null callback.
            push @modal_callbacks, [sub { }];
        }

        # We assume our callers are going to return immediately back to the
        # main event loop, so we don't need a recursive call.       
        return;
    }

}

=head1 NAME

Curses::UI::POE - A subclass makes Curses::UI POE Friendly.

=head1 SYNOPSIS

 use Curses::UI::POE;

 my $cui = new Curses::UI::POE inline_states => {
     _start => sub {
         $_[HEAP]->dialog("Hello!");
     },

     _stop => sub {
         $_[HEAP]->dialog("Good bye!");
     },
 };

 $cui->mainloop

=head1 INTRODUCTION

This is a subclass for Curses::UI that enables it to work with POE.
It is designed to simply slide over Curses::UI.  Keeping the API the
same and simply forcing Curses::UI to do all of its event handling
via POE, instead of internal to itself.  This allows you to use POE
behind the scenes for things like networking clients, without Curses::UI
breaking your programs' functionality.

=head1 ADDITIONS

This is a list of distinct changes between the Curses::UI API, and the
Curses::UI::POE API.  They should all be non-obstructive additions only,
keeping Curses::UI::POE a drop-in replacement for Curses::UI.

=head2 Constructor Options

=over 2

=item inline_states

The inline_states constructor option allows insertion of inline states
into the Curses::UI::POE controlling session.  Since Curses::UI::POE is
implimented with a small session I figured it may be useful provide the
ability to the controlling session for all POE to Interface interaction.

While Curses::UI events are still seamlessly forced to use POE, this allows
you to use it for a little bit more, such as catching responses from another
POE component that should be directly connected with output.  (See the IRC
client example).

In this controlling session, however, the heap is predefined as the root
Curses::UI object, which is a hash reference.  In the Curses::UI object,
all private data is indexed by a key begining with "-".  So if you wish
to use the heap to store other data, simply dont use the "-" hash index
prefix to avoid conflicts.

=back

=head1 TIMERS

The undocumented Curses::UI timers ($cui->timer) will still work, and
they will be translated into POE delays.  I would suggest not using them,
however, as POE's internal alarms and delays are far more robust.

=head1 DIALOGS

The Curses::UI::POE dialog methods contain thier own miniature event loop,
similar to the way Curses::UI's dialog methods worked.  However instead
of blocking and polling on readkeys, it incites its own custom miniature
POE Event loop until the dialog has completed, and then its result is
returned as per the Curses::UI specifications.

=head1 MODALITY

Curses::UI::POE builds its own internal modality structure.  This allows
Curses::UI to manage it, and POE to issue the (hopefully correct) events.
To do this it uses its own custom (smaller) event loop, which is reentrant
into the POE::Loop in use (In this case, usually POE::Loop::Select).  This
way there can be several recursed layers of event loops, forcing focus on
the current modal widget, without stopping other POE::Sessions from running.

=head1 SEE ALSO

L<POE>, L<Curses::UI>.  Use of this module requires understanding of both
the Curses::UI widget set and the POE Framework.

=head1 BUGS

=over 2

=item Dialogs before ->mainloop()

Dialogs before Curses::UI::Mainloop

=back

Find more?  Send them to me!  tag@cpan.org

=head1 AUTHOR

=over 2

=item Rocco Caputo (rcaputo@cpan.org)

Rocco has helped in an astronomical number of ways.  He helped me work out
a number of issues (including how to do this in the first place) and atleast
half the code if not more came from his fingertips.

=back

=head1 MAINTAINER

=over 2

=item Scott McCoy (tag@cpan.org)

This was my stupid idea.  I also got to maintain it, although the original
code (some of which may or may not still exist) came from Rocco.

=back

=cut

1;

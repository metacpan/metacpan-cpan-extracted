package Curses::UI::AnyEvent;

our $VERSION = '0.101';

use strict;

use AnyEvent;
use base qw( Curses::UI );



sub startAsync {
    my $self = shift;

    $self->do_one_event;

    $self->{_async_watcher} = AE::io \*STDIN, 0, sub {
        $self->do_one_event($self->{_modal_object});

        if (defined $self->{_modal_object} && defined $self->{_modalfocus_cv} && !$self->{_modal_object}->{-has_modal_focus}) {
            $self->{_modalfocus_cv}->send();
        }
    };
}

sub stopAsync {
    my $self = shift;

    delete $self->{_async_watcher};
}

sub mainloop {
    my $self = shift;

    $self->startAsync();

    $self->{_cv} = AE::cv;
    $self->{_cv}->recv;
    delete $self->{_cv};

    $self->stopAsync();
}

sub mainloopExit {
    my $self = shift;

    if (exists $self->{_cv}) {
        $self->{_cv}->send();
    } else {
        warn "Called mainloopExit but mainloop wasn't running";
    }
}

sub char_read {
    my $self = shift;

    $self->Curses::UI::Common::char_read(0); ## Ignore timeout passed in to us, hard-code to 0
}


sub tempdialog() {
    my $self = shift;
    my $class = shift;
    my %args = @_;

    my $cb = delete $args{-cb} || sub {};

    my $id = "__window_$class";

    my $dialog = $self->add($id, $class, %args);

    $self->{_modalfocus_cv} = AE::cv;
    $self->{_modal_object} = $dialog;

    # "Fake" focus for this object.
    $dialog->{-has_modal_focus} = 1;
    $dialog->focus;
    $dialog->draw;

    $self->{_modalfocus_cv}->cb(sub {
        delete $self->{_modalfocus_cv};
        delete $self->{_modal_object};

        $dialog->{-focus} = 0;
        $dialog->{-has_modal_focus} = 0;

        my $return = $dialog->get;
        $self->delete($id);
        $self->root->focus(undef, 1);

        $cb->($return);
    });
}


1;



__END__

=encoding utf-8

=head1 NAME

Curses::UI::AnyEvent - Sub-class of Curses::UI for AnyEvent

=head1 SYNOPSIS

    use strict;

    use Curses::UI::AnyEvent;

    my $cui = Curses::UI::AnyEvent->new(-color_support => 1);

    $cui->set_binding(sub { exit }, "\cC");
    $cui->set_binding(sub { $cui->mainloopExit() }, "q");
   
    my $win = $cui->add('win', 'Window',
                        -border => 1,
                        -bfg  => 'red',
                       );


    my $textviewer = $win->add('mytextviewer', 'TextViewer',
                               -text => '',
                              );

    my $watcher = AE::timer 1, 1, sub {
        $textviewer->{-text} = localtime() . "\n" . $textviewer->{-text};
        $textviewer->draw;
    };

    $textviewer->focus();

    $cui->mainloop();


=head1 DESCRIPTION

Very simple integration with L<Curses::UI> and L<AnyEvent>. Just create a C<Curses::UI::AnyEvent> object instead of a C<Curses::UI> one and use it as normal.

You'll probably want to install some AnyEvent watchers before you call C<mainloop()>. Alternatively, if you want to setup the async handlers without blocking, you can use the C<startAsync> method:

    $cui->startAsync();

    ## add some other handlers...

    AE::cv->recv; ## block here instead

Most things work, including mouse support.


=head1 DIALOGS

L<Curses::UI> unfortunately implements a separate event loop in order to handle modal dialogs. This conflicts with our AnyEvent loop so it needed to be stubbed out by replacing the internal C<tempdialog> method. Informational dialogs work normally, except they return immediately instead of waiting for the dialog to be dismissed:

    $cui->dialog("Some information: blah blah blah");
    ## ^^ Returns immediately, not when dialog dismissed!

If you wish to perform some action after the dialog is dismissed, or in the case of query dialogs you wish to access the value, there is a new C<-cb> parameter that accepts a callback:

    $cui->question(-question => "What is your name?",
                   -cb => sub {
                              my $name = shift;
                              ## ...
                          });

Note that while a dialog is active, all keypresses are routed to that dialog instead of the main screen. However, since the main event loop is still active, it can still be processing externally triggered or timed events.


=head1 BUGS

There are still a few places that call `do_one_event()` in a loop instead of using the AnyEvent loop so they will busy-loop until dismissed by the user and no background events will be processed. The cases I know about are search windows and fatal error screens. I may stub these out similarly to dialogs if I need them (patches welcome).


=head1 SEE ALSO

L<Curses-UI-AnyEvent github repo|https://github.com/hoytech/Curses-UI-AnyEvent>

L<Curses::UI>

L<AnyEvent>

L<Curses::UI::POE>


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2016 Doug Hoyte.

This module is licensed under the same terms as perl itself.

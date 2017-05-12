package Bot::Backbone::Service::Interactive;
{
  $Bot::Backbone::Service::Interactive::VERSION = '0.142250';
}
use Bot::Backbone::Service;

# ABSTRACT: Access an external command through a bot

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::ChatConsumer
);

use AnyEvent::Run;
use Scalar::Util qw( reftype );


service_dispatcher as {
    not_command run_this_method 'interactive_command';
};


has handle => (
    is          => 'rw',
    isa         => 'AnyEvent::Run',
    lazy_build  => 1,
    clearer     => 'clear_handle',
);

sub _build_handle {
    my $self = shift;

    my $handle = AnyEvent::Run->new(
        cmd => $self->run_command,
        on_read => sub {
            my ($handle) = @_;

            my $input = $handle->{rbuf};
            $handle->{rbuf} = '';

            $self->got_input($input);
        },
        on_error => sub {
            $self->clear_handle;
        },
    );

    return $handle;
}


has interactive_prefix => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => '#',
);


has run_command => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
);


has input_cleaner => (
    is          => 'ro',
    isa         => 'CodeRef',
    predicate   => 'has_input_cleaner',
);


sub interactive_command {
    my ($self, $message) = @_;
    my $text = $message->text;
    
    my $p = $self->interactive_prefix;

    if ($text =~ /^$p(.*)/) {
        my $send_text = $1;
        $message->add_flag('command');
        $self->handle->push_write($send_text."\n");
    }
}


sub got_input {
    my ($self, $input) = @_;

    if ($self->has_input_cleaner) {
        local $_  = $input;
        $input = $self->input_cleaner->($input);
    }

    $self->send_message({ text => $input });
}


sub initialize { }


sub receive_message { }

1;

__END__

=pod

=head1 NAME

Bot::Backbone::Service::Interactive - Access an external command through a bot

=head1 VERSION

version 0.142250

=head1 SYNOPSIS

  # play my favorite infocom game
  service planetfall => (
      service       => 'Interactive',
      chat          => 'adventure_chat',
      run_command   => [ qw( bin/dfrotz -w 255 PLANETFA.DAT ) ],
      input_cleaner => sub {
          s/\A[\w: ]+\n\n//ms;
          s/^\>[^\n]*$//gms;
          s/\n{3,}/\n\n/gms;
          s/(Deck Nine\nThis is a featureless corridor similar to every other corridor on the ship. It curves away to starboard, and a gangway leads up. To port is the entrance to one of hte ship's primary escape pods. The pod bulkhead is closed.\n\n){2}/$1/ms;
          s/\s+\Z//ms;
          $_;
      },
  );

  # in the chat
  bot> PLANETFALL
  Infocom interactive fiction - a science fiction story
  Copyright (c) 1983 by Infocom, Inc. All rights reserved.
  PLANETFALL is a trademark of Infocom, Inc.
  Release 37 / Serial number 851003

  Another routine day of drudgery aboard the Stellar Patrol Ship Feinstein. This morning's assignment for a certain lowly Ensign Seventh Class: scrubbing the filthy metal deck at the port end of Level Nine. With your Patrol-issue self-contained multi-
  purpose all-weather scrub brush you shine the floor with a diligence born of the knowledge that at any moment dreaded Ensign First Class Blather, the bane of your shipboard existence, could appear.

  Deck Nine
  This is a featureless corridor similar to every other corridor on the ship. It curves away to starboard, and a gangway leads up. To port is the entrance to one of the ship's primary escape pods. The pod bulkhead is closed.
  alice> #port
  bot> The escape pod bulkhead is closed.
  alice> #starboard
  bot> Reactor Lobby
  The corridor widens here as it nears the main drive area. To starboard is the Ion Reactor that powers the vessel, and aft of here is the Auxiliary Control Room. The corridor continues to port.

  Ensign Blather, his uniform immaculate, enters and notices you are away from your post. "Twenty demerits, Ensign Seventh Class!" bellows Blather. "Forty if you're not back on Deck Nine in five seconds!" He curls his face into a hideous mask of disgust at
  your unbelievable negligence.

NOTE: C<dfrotz> is an external project and Planetfall is a copyright owned by
Infocom, Inc.

=head1 DESCRIPTION

This captures the input and output from an external command. It then causes the
bot to speak all the output from the command and passes any prefixed text back
to the command. This can be used to play text adventure games through a chat
channel, access a bash prompt, or whatever you like.

=head1 DISPATCHER

This dispatcher causes any text prefixed with the string in
L</interactive_prefix> to be marked as a command. That string is passed
through to the program running via L</run_command> as input (after strippingt
he prefix).

=head1 ATTRIBUTES

=head2 handle

This is an L<AnyEvent::Run> object used to handle the interaction between
running program and the bot. Normally, you do not need to set this up yourself
as it is built automatically from the L</run_command> attribute. However, if
you have some special needs, you can set this yourself instead.

The L<AnyEvent::Run> method is setup so that input is sent to L</got_input>
for handling and error causes L</handle> to clear (and, thus, stop working).

=head2 interactive_prefix

This is the character or string to use as the interactive prefix to mark any
message that is intended for the bot to send through to the handle.

The default is "#".

=head2 run_command

This is the command-line to run as the interactive command. This is an array
reference containing the arguments that would be passed through on the
command-line. It is used to construct the L</handle>.

=head2 input_cleaner

Often, the output from a command (which is input into the bot) is not
suitable for display in the channel for some reason. This method is given some
text output by the command and given the opportunity to rewrite it. The text
returned by this method is then used as the text to actual display.

By default, no such subroutine is provided and the input into the bot is
presented in the chat as-is.

=head1 METHODS

=head2 interactive_command

Implements the code that searches each chat message for the prefix and routes
any such command to the interactive program.

=head2 got_input

This method receives the input sent from the interactive command as output and
writes it back to the chat after running it through the
L</input_cleaner>, if defined.

=head2 initialize

No op.

=head2 receive_message

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

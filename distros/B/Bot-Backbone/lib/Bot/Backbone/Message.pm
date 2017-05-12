package Bot::Backbone::Message;
$Bot::Backbone::Message::VERSION = '0.161950';
use v5.10;
use Moose;

use Bot::Backbone::Identity;
use Bot::Backbone::Types qw( VolumeLevel );
use List::MoreUtils qw( all );
use Scalar::Util qw( blessed );

# ABSTRACT: Describes a message or response


has chat => (
    is          => 'ro',
    does        => 'Bot::Backbone::Service::Role::Chat',
    required    => 1,
    weak_ref    => 1,
);


has from => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Identity',
    required    => 1,
    handles     => {
        'is_from_me' => 'is_me',
    },
);


has to => (
    is          => 'rw',
    isa         => 'Maybe[Bot::Backbone::Identity]',
    required    => 1,
    handles     => {
        '_is_to_me' => 'is_me',
    },
);


has group => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
);


has volume => (
    is          => 'ro',
    isa         => VolumeLevel,
    required    => 1,
    default     => 'spoken',
);


has text => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

{
    package Bot::Backbone::Message::Arg;
$Bot::Backbone::Message::Arg::VERSION = '0.161950';
use Moose;

    has [ qw( text original ) ] => (
        is       => 'rw', 
        isa      => 'Str', 
        required => 1,
    );

    sub clone {
        my $self = shift;
        Bot::Backbone::Message::Arg->new(
            original => $self->original,
            text     => $self->text,
        );
    }

    __PACKAGE__->meta->make_immutable;
}


has args => (
    is          => 'rw',
    isa         => 'ArrayRef[Bot::Backbone::Message::Arg]',
    required    => 1,
    lazy_build  => 1,
    predicate   => 'has_args',
    traits      => [ 'Array' ],
    handles     => {
        'all_args'      => 'elements',
        'shift_args'    => 'shift',
        'unshift_args'  => 'unshift',
        'pop_args'      => 'pop',
        'push_args'     => 'push',
        'has_more_args' => 'count',
    },
);

sub _build_args {
    my $self = shift;

    my @args;
    my $source = $self->text;
    my $original = '';
    my $current = '';
    my $quote_mark;
    while (length $source > 0) {
        my $next_char = substr $source, 0, 1, '';

        # Handle "... '... (... [... {...
        if ($original =~ /^\s*$/ and $next_char =~ /['"\(\[\{]/) {
            $original  .= $next_char;
            $quote_mark = $next_char;
        }

        # Handle ..." ...' ...) ...] ...}
        elsif (defined $quote_mark
           and (($quote_mark =~ /(['"])/ and $next_char eq $1)
            or  ($quote_mark eq '('      and $next_char eq ')')
            or  ($quote_mark eq '['      and $next_char eq ']')
            or  ($quote_mark eq '{'      and $next_char eq '}'))) {

            $original .= $next_char;

            push @args, Bot::Backbone::Message::Arg->new(
                text     => $current,
                original => $original,
            );

            $original = '';
            $current  = '';
            undef $quote_mark;
        }

        # Handle quoted whitespace
        elsif (defined $quote_mark and $next_char =~ /\s/) {
            $original .= $next_char;
            $current  .= $next_char;
        }

        # Handle leading or trailing whitespace
        elsif ($next_char =~ /\s/) {
            $original .= $next_char;
        }

        # Handle word breaks: non-quote chars
        elsif (not defined $quote_mark and $original  =~ /\S\s+/ 
                                       and $next_char =~ /\S/) {

            push @args, Bot::Backbone::Message::Arg->new(
                text     => $current,
                original => $original,
            );

            $original = $next_char;
            if ($next_char =~ /['"\(\[\{]/) {
                $current    = '';
                $quote_mark = $next_char;
            }
            else {
                $current = $next_char;
                undef $quote_mark;
            }

        }

        # Handle letters belonging to the current word
        else {
            $original .= $next_char;
            $current  .= $next_char;
        }
    }

    # Tack on any trailing whitespace we've missed
    if (@args and $original =~ /^\s+$/) {
        $args[-1]->text($args[-1] . $original);
    }

    # Tack on any trailing word that needs be appended
    else {
        push @args, Bot::Backbone::Message::Arg->new(
            text     => $current,
            original => $original,
        );
    }

    return \@args;
}


has flags => (
    is          => 'ro',
    isa         => 'HashRef[Bool]',
    required    => 1,
    default     => sub { +{} },
);


has bookmarks => (
    is          => 'ro',
    isa         => 'ArrayRef[Bot::Backbone::Message]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        _set_bookmark     => 'push',
        _restore_bookmark => 'pop',
    },
);


has parameters => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        set_parameter    => 'set',
        get_parameter    => 'get',
    },
);


sub is_group  { defined shift->group }
sub is_direct { defined shift->to }


sub add_flag     { my $self = shift; $self->flags->{$_} = 1 for @_ } 
sub add_flags    { my $self = shift; $self->flags->{$_} = 1 for @_ }
sub remove_flag  { my $self = shift; delete $self->flags->{$_} for @_ }
sub remove_flags { my $self = shift; delete $self->flags->{$_} for @_ }
sub has_flag     { my $self = shift; all { $self->flags->{$_} } @_ }
sub has_flags    { my $self = shift; all { $self->flags->{$_} } @_ }


sub is_to_me {
    my $self = shift;
    return '' unless $self->is_direct;
    return $self->to->is_me;
}


sub set_bookmark {
    my $self = shift;
    my $bookmark = Bot::Backbone::Message->new(
        chat       => $self->chat,
        to         => $self->to,
        from       => $self->from,
        group      => $self->group,
        text       => $self->text,
        parameters => { %{ $self->parameters } },
    );
    $bookmark->args([ map { $_->clone } @{ $self->args } ]) 
        if $self->has_args;
    $self->_set_bookmark($bookmark);
    return;
}


sub restore_bookmark {
    my $self = shift;
    my $bookmark = $self->_restore_bookmark;
    $self->to($bookmark->to);
    $self->from($bookmark->from);
    $self->group($bookmark->group);
    $self->text($bookmark->text);
    $self->args($bookmark->args) 
        if $self->has_args or $bookmark->has_args;
    $self->parameters({ %{ $bookmark->parameters } });
    return;
}


sub set_bookmark_do {
    my ($self, $code) = @_;
    $self->set_bookmark;
    my $result = $code->();
    $self->restore_bookmark;
    return $result;
}


sub match_next {
    my ($self, $match) = @_;

    $match = quotemeta $match unless ref $match;

    if ($self->has_more_args and $self->args->[0]->text =~ /^$match$/) {
        my $arg = $self->shift_args;
        $self->text(substr $self->text, length $arg->original);
        return $arg->text;
    }

    return;
}


sub match_next_original {
    my ($self, $match) = @_;

    my $text = $self->text;
    if ($text =~ s/^($match)//) {
        my $value = $1;
        $self->text($text);
        $self->args($self->_build_args) if $self->has_args; # reinit args
        return $value;
    }

    return;
}


sub reply {
    my ($self, $sender, $text) = @_;

    if (defined $sender and blessed $sender 
           and $sender->does('Bot::Backbone::Service::Role::Sender')) {

        $sender->send_reply($self, { text => $text });
    }
    elsif (defined $sender and blessed $sender 
            and $sender->isa('Bot::Backbone::Bot')) {

        # No warning... hmm...
        $self->chat->send_reply($self, { text => $text });
    }
    else {
        warn "Sender given is not a sender service or a bot: $sender\n";
        $self->chat->send_reply($self, { text => $text });
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Message - Describes a message or response

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  # E.g., passed in to dispatcher predicates
  my $message = ...;

  say $message->from->nickname, ' says, "', $message->text, '"';

  my $chatroom = $message->group;

=head1 ATTRIBUTES

=head2 chat

This is the L<Bot::Backbone::Service::Role::Chat> chat engine where the message
originated.

=head2 from

This is the L<Bot::Backbone::Identity> representing the user sending the
message.

=head2 to

This is C<undef> or the L<Bot::Backbone::Identity> representing hte user the
message is directed toward. If sent to a room or if this is a broadcast message,
this will be C<undef>.

A message to a room may also be to a specific person, this may show that as
well.

=head2 group

This is the name of the chat room.

=head2 volume

This is the volume of the message. It must be one of the following values:

=over

=item shout

This is a message sent across multiple chats and channels, typically a system message or administrator alert.

=item spoken

This is a message stated to all the users within the chat. This is the normal volume level.

=item whisper

This is a message stated to only a few users within the chat, usually just one, the recipient.

=back

=head2 text

This is the message that was sent.

=head2 args

This is a list of "arguments" passed into the bot. Each arg is a C<Bot::Backbone::Message:Arg> object, which is a simple Moose object with only two attributes: C<text> and C<original>. The C<text> is the value of the argument and the C<original> is the original piece of the message L</text> for that value, which contains whitespace, quotation marks, etc.

=head2 flags

These are flags associated with the message. These may be used by dispatcher to
make notes about how the message has been dispatched or identifying features of
the message.

See L<add_flag>, L<add_flags>, L<remove_flag>, L<remove_flags>, L<has_flag>, and
L<has_flags>.

=head2 bookmarks

When processing a dispatcher, the predicates consume parts of the message in the
process. This allows us to keep a stack of pass message parts in case the
predicate ultimately fails.

=head2 parameters

These are parameters assoeciated with the message created by the dispatcher
predicates while processing the message.

=head2 is_group

Returns true if this message happened in a chat group/room/channel.

=head2 is_direct

Returns true if this message was sent directly to the receipient.

=head2 add_flag

=head2 add_flags

  $message->add_flag('foo');
  $message->add_flags(qw( bar baz ));

Set a flag on this message.

=head2 remove_flag

=head2 remove_flags

  $message->remove_flag('foo');
  $message->remove_flags(qw( bar baz ));

Unsets a flag on this message.

=head2 has_flag

=head2 has_flags

  $message->has_flag('foo');
  $message->has_flags(qw( bar baz ));

Returns true if all the flags passed are set. Returns false if any of the flags
named are not set.

=head2 is_to_me

Returns true of the message is to me.

=head2 set_bookmark

  $message->set_bookmark;

Avoid using this method. See L</set_bookmark_do>.

Saves the current message in the bookmarks stack.

=head2 restore_bookmark

  $mesage->restore_bookmark;

Avoid using this method. See L</set_bookmark_do>.

Restores the bookmark on the top of the bookmarks stack. The L</to>,
L</from>, L</group>, L</text>, L</parameters>, and L</args> are restored. All
other attribute modifications will stick.

=head2 set_bookmark_do

  $message->set_bookmark_do(sub {
      ...
  });

Saves the current message on the top of the stack using L</set_bookmark>. Then,
it runs the given code. Afterwards, any modifications to the message will be
restored to the original using L</restore_bookmark>.

=head2 match_next

  my $value = $message->match_next('!command');
  my $value = $message->metch_next(qr{!(?:this|that)});

Given a regular expression or string, matches that against the next argument in
the L</args> and strips off the match. It returns the match if the match is
successful or returns C<undef>. If given a regular express, the match will not
succeed unless it matches the entire argument (i.e., a C<^> is added to the
front and C<$> is added to the end).

=head2 match_next_original

  my $value = $message->match_next_original(qr{.+});

Given a regular expression, this will match that against the remaining unmatched
text (not via L</args>, but via the unparsed L</text>). A C<^> at the front of
the regex will be added to match against L</text>.

If there's a match, the matching text is returned.

=head2 reply

  $message->reply($sender, 'blah blah blah');

Sends a reply back to the entity sending the message or the group that sent it,
using the chat service that created the message.

The first argument must be a L<Bot::Backbone::Service::Role::Sender> or
L<Bot::Backbone::Bot>, which should be the service or bot sending the reply. The
send policy set for that sender will be applied. You may pass C<undef> or
anything else as the sender, but a warning will be issued.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

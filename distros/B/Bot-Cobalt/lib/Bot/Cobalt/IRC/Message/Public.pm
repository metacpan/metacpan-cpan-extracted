package Bot::Cobalt::IRC::Message::Public;
$Bot::Cobalt::IRC::Message::Public::VERSION = '0.021003';
use v5.10;
use strictures 2;
use Scalar::Util 'blessed';

use Bot::Cobalt;
use Bot::Cobalt::Common;

require Bot::Cobalt::Core;

use Moo;
extends 'Bot::Cobalt::IRC::Message';

has cmd => (
  lazy      => 1,
  is        => 'rw',
  isa       => Any,
  predicate => 'has_cmd',
  builder   => '_build_cmd',
);

has highlight => (
  lazy      => 1,
  is        => 'rw',
  isa       => Bool,
  predicate => 'has_highlight',
  builder   => '_build_highlight',
);

has myself => (
  lazy      => 1,
  is        => 'rw',
  isa       => Str,
  builder   => sub {
    my ($self) = @_;
    my $irc;
    return ''
      unless Bot::Cobalt::Core->has_instance
      and $irc = irc_object($self->context);
    $irc->nick_name || ''
  },
);

after message => sub {
  my ($self, $value) = @_;
  return unless defined $value;
  
  if ($self->has_highlight) {
    $self->highlight( $self->_build_highlight );
  }

  if ($self->has_cmd) {
    $self->cmd( $self->_build_cmd );
  }
};

sub _build_highlight {
  my ($self) = @_;
  my $me  = $self->myself || return 0;
  my $txt = $self->stripped;
  $txt =~ /^${me}[,:;!-]?\s+/i
}

sub _build_cmd {
  my ($self) = @_;

  my $cmdchar = Bot::Cobalt::Core->has_instance ?
    (core->get_core_cfg->opts->{CmdChar} // '!') : '!'
  ;

  if ($self->stripped =~ /^${cmdchar}([^\s]+)/) {
    my $message = $self->message_array;
    shift @$message;
    # shift above modifies the ref, but intentionally hit trigger:
    $self->message_array($message);
    return lc($1)
  }
  undef
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::IRC::Message::Public - Public message subclass

=head1 SYNOPSIS

  sub Bot_public_msg {
    my ($self, $core) = splice @_, 0, 2;
    my $msg = ${ $_[0] };

    if ($msg->highlight) {
      . . .
    }
  }

=head1 DESCRIPTION

This is a subclass of L<Bot::Cobalt::IRC::Message> -- most methods are
documented there.

When an incoming message is a public (channel) message, the provided
C<$msg> object has the following extra methods available:

=head2 myself

The 'myself' attribute can be tweaked to change how L</highlight>
behaves. By default it will query the L<Bot::Cobalt::Core> instance for
an IRC object that can return the bot's current nickname.

=head2 highlight

If the bot appears to have been highlighted (ie, the message is prefixed
with L</myself>), this method will return boolean true.

Used to see if someone is "talking to" the bot.

=head2 cmd

If the message appears to actually be a command and some arguments,
B<cmd> will return the specified command and automatically shift
the B<message_array> leftwards to drop the command from
B<message_array>.

Normally this isn't used directly by plugins other
than L<Bot::Cobalt::IRC>; a Message object handed off by a Bot_public_cmd_*
event has this done for you already, for example.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut

package Bot::BasicBot::Pluggable::Module;
$Bot::BasicBot::Pluggable::Module::VERSION = '1.20';
use warnings;
use strict;

sub new {
    my $class = shift;
    my %param = @_;

    my $name = ref($class) || $class;
    $name =~ s/^.*:://;
    $param{Name} ||= $name;

    my $self = \%param;
    bless $self, $class;

    $self->init();

    return $self;
}

sub config {
    my ( $self, $config ) = @_;
    for my $var ( keys %{$config} ) {
        $self->set( $var, $config->{$var} ) unless defined( $self->get($var) );
    }
}

sub bot {
    my $self = shift;
    return $self->{Bot};
}

sub store {
    my $self = shift;
    die "module has no bot" unless $self->bot;
    return $self->bot->store;
}

sub get {
    my $self = shift;
    $self->store->get( $self->{Name}, @_ );
}

sub set {
    my $self = shift;
    $self->store->set( $self->{Name}, @_ );
}

sub unset {
    my $self = shift;
    $self->store->unset( $self->{Name}, @_ );
}

sub var {
    my $self = shift;
    my $name = shift;
    if (@_) {
        return $self->set( $name, shift );
    }
    else {
        return $self->get($name);
    }
}

sub store_keys {
    my $self  = shift;
    my $store = $self->store;

    die "No store set up"   unless defined $store;
    die "Store isn't a ref" unless ref($store);

    $store->keys( $self->{Name}, @_ );
}

sub help {
    my ( $self, $mess ) = @_;
    return "No help for module '$self->{Name}'. This is a bug.";
}

sub say {
    my $self = shift;
    return $self->bot->say(@_);
}

sub reply {
    my $self = shift;
    return $self->bot->reply(@_);
}

sub tell {
    my ( $self, $target, $body ) = @_;
    if ( $target =~ /^#/ ) {
        $self->say( { channel => $target, body => $body } );
    }
    else {
        $self->say( { channel => 'msg', body => $body, who => $target } );
    }
}

sub said {
    my ( $self, $mess, $pri ) = @_;
    $mess->{body} =~ s/(^\s*|\s*$)//g if defined $mess->{body};

    my $handler = (qw/ seen admin told fallback /)[$pri];

    return $self->$handler($mess);
}

sub authed {
    my ( $self, $who ) = @_;
    if ( $self->bot->module('Auth') ) {
        return $self->bot->module('Auth')->authed($who);
    }
    return 0;
}

sub init      { undef }
sub connected { undef }
sub chanjoin  { undef }
sub chanpart  { undef }
sub seen      { undef }
sub admin     { undef }
sub told      { undef }
sub fallback  { undef }
sub emoted    { undef }
sub tick      { undef }
sub stop      { undef }

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module - base module for all BasicBot plugins

=head1 VERSION

version 1.20

=head1 SYNOPSIS

You MUST override C<help()>, which MUST return help text for the module.

You MUST override at least C<said()>, though it is preferred that you
override the more specific C<seen()>, C<admin()>, C<told()> and C<fallback()>
for cleaner code without relying on checks against C<$pri>.

You MAY override C<chanjoin()>, C<chanpart()>, C<userquit>,
C<nick_change>, C<topic>, C<kicked> and C<tick()>.

You MAY return a response from C<said()> to the event.

=head1 DESCRIPTION

=head2 Object Store

Every pluggable module gets an object store to save variables in. Access
this store using the C<get()> and C<set()> accessors. Do not access the store
through any other means - the location of the store, and its method of storage,
may change at any time:

  my $count = $self->get("count");
  $self->set( count => $count + 1 );

Keys that begin "user_" are considered _USER_ variables, and can be changed by
administrators in the IRC channel using L<Bot::BasicBot::Pluggable::Module::Vars>.
Don't use them as unchecked input data.

=head1 METHODS

=over 4

=item new()

Standard C<new> method, blesses a hash into the right class and puts any
key/value pairs passed to it into the blessed hash. Calls C<init> to load
any internal or user variables you may have set in your module.

=item init()

Called as part of new class construction. May or may not be after
server connection. Override this to do things when your module is added
to the bot.

=item config($config)

Set every key in the hash reference $config to its default value
if it is not already defined in the module store. In that case the
value from the store is used to initialise the variable. Typically
called in the module's init functions.

=item start()

Indicates that the module is added to the bot, and that the bot is
connected to the IRC server. Do things here that need to be done after
you're connected.

TODO - this method not yet implemented.

=item stop()

Called just before your module is removed from the bot. Do cleanup here.

=item bot()

Returns the L<Bot::BasicBot::Pluggable> bot we're running under.

=item store

Returns L<Bot::BasicBot::Pluggable::Store> subclass used to store variables.

=item get($name)

Returns the value of a local variable from the object store.

=item set($name => $value)

Set a local variable into the object store.

=item unset($name)

Unsets a local variable - removes it from the store, not just C<undef>s it.

=item var($name, [$value])

C<get()> or C<set()> a local variable from the module store.

=item store_keys

Returns a list of all keys in the object store.

=item connected

Called when the bot connects to the server. The return value is meaningless.

=item chanjoin($message)

Called when a user joins a channel.

=item userquit($message)

Called when a user client quits. See L<Bot::BasicBot> for a description
of the arguments.

=item chanpart($message)

Called when a user leaves a channel.

=item topic($message)

Called when the topic of a channel is changed. See L<Bot::BasicBot> for a description
of the arguments.

=item kicked($message)

Called when a user is kicked from a channel. See L<Bot::BasicBot> for a description
of the arguments.

=item nick_change($message)

When a user changes nicks, this will be called. See L<Bot::BasicBot> for a description
of the arguments.

=item help

Called when a user asks for help on a topic and thus should return some useful
help text. For L<Bot::BasicBot::Pluggable>, when a user asks the bot 'help',
the bot will return a list of modules. Asking the bot 'help <modulename>' will
call the C<help> function of that module, passing in the first parameter the
message object that represents the question.

=item say($message)

Passing through L<Bot::BasicBot>, send messages without replying to a C<said()>:

  $self->say({ who => 'tom', body => 'boo', channel => 'msg' });

=item reply($message, $body)

Replies to the given message with the given text. Another passthrough to
C<Bot::BasicBot>. The message is used to pre-populate the reply, so it'll
be in the same channel as the question, directed to the right user, etc.

=item tell($nick | $channel, $message)

Convenience method to send message to nick (privmsg) or channel (public):

  $self->tell('tom', "hello there, fool");
  $self->tell('#sailors', "hello there, sailor");

=item said($message, $priority)

This method is called whenever the bot sees something said. The first parameter
is a L<Bot::BasicBot> 'message' object, as passed to it's 'said' function - see
those docs for further details. The second parameter is the priority of the
message - all modules will have the 'said' function called up to 4 times, with
priorities of 0, 1, 2, and 3. The first module to return a non-null value
'claims' the message, and the bot will reply to it with the value returned -
unless the value is "1", in which case the message is considered claimed (no
other module will see it) but no reply will be issued.

The exception to this is the 0 priority, which a module MUST NOT respond to 
(any response will be ignored).
This is so that all modules will at least see all messages. I suggest:

  sub said {
    my ($self, $mess, $pri) = @_;
    my $body = $mess->{body};

    return unless ($pri == 2); # most common

    my ($command, $param) = split(/\s+/, $body, 2);
    $command = lc($command);

    # do something here

    return;       # allows other modules to see this message, or:
    return 1;     # "eat" the message, no other module sees it, no reply, or:
    return "OK!"; # "eat" the message and send a reply back to the user
  }

The preferred way, however, is to override one of the separate C<seen()>, C<admin()>,
C<told()> and C<fallback()> methods, corresponding to priorities 0, 1, 2 and 3
in order - this will lead to nicer code. This approach is new, though, which
is why it's not yet used in most of the shipped modules yet. It will eventually
become the only thing to do, and I will deprecate C<said()>.

=item replied($message,$reply)

This method is called every time a module returns an reply. The first
argument is the original message and the second is the returned
string. The return value of this method is actually discarded, so
you can't do anything to prevent the message from being sent. This
is mainly meant to log the bots activity.

=item seen($message)

Like C<said()>; called if you don't override C<said()>, but only for priority 0.

As it is called at priority 0, you cannot return a reply from this method.

=item admin($message)

Like C<said()>; called if you don't override C<said()>, but only for priority 1.

=item told($message)

Like C<said()>; called if you don't override C<said()>, but only for priority 2.

=item fallback($message)

Like C<said()>; called if you don't override C<said()>, but only for priority 3.

=item emoted($message, $priority)

Called when a user emotes something in channel.

=item tick

Called every five seconds. It is probably worth having a counter and not
responding to every single one, assuming you want to respond at all. The
return value is ignored.

=item authed($who)

This is a convenient method that tries to check for the users
authentication level via Auth.pm. It is exactly equivalent to

    $self->bot->module('Auth')
      and $self->bot->module('Auth')->authed($who);

=back

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

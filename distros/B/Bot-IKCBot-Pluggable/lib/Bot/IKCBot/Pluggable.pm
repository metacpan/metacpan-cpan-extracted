package Bot::IKCBot::Pluggable;

use warnings;
use strict;

our $VERSION = '0.02';

use base qw( Bot::BasicBot::Pluggable );
use POE;
use POE::Session;
use POE::Component::IKC::Server;

our $STATE_TABLE = {
    say    => 'hearsay',
    notice => 'hearnotice',
};

sub run {
    my $self = shift;

    POE::Component::IKC::Server::create_ikc_server(
        ip   => $self->{ikc_ip},
        port => $self->{ikc_port},
        name => 'IKC',
       );

    POE::Session->create(
        object_states => [
            $self => {
                _start => 'start_state_ikc',
                %$STATE_TABLE,
            }
           ]
       );

    $self->SUPER::run($self);
}

sub start_state_ikc {
    my($self, $kernel, $session) = @_[ OBJECT, KERNEL, SESSION ];
    $self->{kernel}  = $kernel;
    $self->{session} = $session;

    $kernel->alias_set($self->{ALIASNAME}."_IKC");

    $kernel->call( IKC => publish => $self->{ALIASNAME}."_IKC" => [keys %$STATE_TABLE] );
}

sub hearsay {
    my($self, $arg) = @_[ OBJECT, ARG0 ];
    $self->say($arg);
}

sub hearnotice {
    my($self, $arg) = @_[ OBJECT, ARG0 ];
    $self->notice($arg);
}

# just Bot::BasicBot::say =~ s/privmsg/notice/g
sub notice {
    # If we're called without an object ref, then we're handling saying
    # stuff from inside a forked subroutine, so we'll freeze it, and toss
    # it out on STDOUT so that POE::Wheel::Run's handler can pick it up.
    if ( !ref( $_[0] ) ) {
        print $_[0] . "\n";
        return 1;
    }

    # Otherwise, this is a standard object method

    my $self = shift;
    my $args;
    if (ref($_[0])) {
        $args = shift;
    } else {
        my %args = @_;
        $args = \%args;
    }

    my $body = $args->{body};

    # add the "Foo: bar" at the start
    $body = "$args->{who}: $body"
        if ( $args->{channel} ne "msg" and $args->{address} );

    # work out who we're going to send the message to
    my $who = ( $args->{channel} eq "msg" ) ? $args->{who} : $args->{channel};

    unless ( $who && $body ) {
        print STDERR "Can't NOTICE without target and body\n";
        print STDERR " called from ".([caller]->[0])." line ".([caller]->[2])."\n";
        print STDERR " who = '$who'\n body = '$body'\n";
        return;
    }

    # if we have a long body, split it up..
    local $Text::Wrap::columns = 300;
    local $Text::Wrap::unexpand = 0;             # no tabs
    my $wrapped = Text::Wrap::wrap('', '..', $body); #  =~ m!(.{1,300})!g;
    # I think the Text::Wrap docs lie - it doesn't do anything special
    # in list context
    my @bodies = split(/\n+/, $wrapped);

    # post an event that will send the message
    for my $body (@bodies) {
        my ($who, $body) = $self->charset_encode($who, $body);
        #warn "$who => $body\n";
        $poe_kernel->post( $self->{IRCNAME}, 'notice', $who, $body );
    }
}

# use notice instead of say (privmsg) when bot's reply
sub reply {
    my $self = shift;
    my ($mess, $body) = @_;
    my %hash = %$mess;
    $hash{body} = $body;
    return $self->notice(%hash);
}

1;

__END__

=head1 NAME

Bot::IKCBot::Pluggable - extended Bot::BasicBot::Pluggable for IKC

=head1 SYNOPSIS

run IKCBot server.

  use Bot::IKCBot::Pluggable;
  
  my $bot = Bot::IKCBot::Pluggable->new(
      ...
      ALIASNAME => 'ikchan',
      ikc_ip    => '127.0.0.1',
      ikc_port  => 1919,
     );
  $bot->load("Karma"); # you can load any
                       # Bot::BasicBot::Pluggable::Module::*
  $bot->run;

and you can talk to IKCBot by IKC. IKC specifier is
I<ALIASNAME>_IKC/I<PUBLISHED_STATE>.

  use POE::Component::IKC::ClientLite;
  
  my $msg      = "hello!";
  my $channel  = "#test1919";
  my $bot_name = 'ikchan';
  
  my $ikc = POE::Component::IKC::ClientLite::create_ikc_client(
      ip      => '127.0.0.1',
      port    => 1919,
      name    => 'notify-irc',
     );
  $ikc->post($bot_name.'_IKC/say', { body => $msg, channel => $channel });

=head1 DESCRIPTION

Bot::IKCBot::Pluggable is IRC bot extends Bot::BasicBot::Pluggable for
IKC support. So you can use all Bot::BasicBot::Pluggable::Module::*,
Karma, Infobot, Title and so on.

In my case, for sending Nagios's alert message to IRC channel, run
IKCBot and define Nagios's command that invokes notify script to send
alert message to IKCBot.


If you want to add your own state of POE::Session, you can do it by
changing hashref $Bot::IKCBot::Pluggable::STATE_TABLE and define
handler function.

  use POE;
  use Bot::IKCBot::Pluggable;
  
  $Bot::IKCBot::Pluggable::STATE_TABLE->{important} = "say_2times";
  
  *Bot::IKCBot::Pluggable::say_2times = sub {
      my($self, $arg) = @_[ OBJECT, ARG0 ];
      $self->say($arg);
      $self->say($arg);
  };
  
  my $bot = Bot::IKCBot::Pluggable->new(
    ...
  );


Additionally, Bot::IKCBot::Pluggable has "notice" method and use
"notice" instead of "say"(=privmsg) when replying.

=head1 SEE ALSO

L<Bot::BasicBot::Pluggable>,
L<Bot::BasicBot>.
L<POE::Component::IKC::Server>,
L<POE::Component::IKC::ClientLite>,

=head1 AUTHOR

HIROSE Masaaki, C<< <hirose31 at gmail.com> >>

=head1 REPOSITORY

L<http://github.com/hirose31/p5-bot-ikcbot-pluggable/tree/master>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-ikcbot-pluggable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-IKCBot-Pluggable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 :

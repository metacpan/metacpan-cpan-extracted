#!/usr/bin/perl
package AsyncBot;
use Moses;
use namespace::autoclean;

server 'irc.perl.org';
nickname 'adam-async-bot';
channels '#ai';

event irc_join => sub {
    my ( $self, $nickstr, $channel ) = @_[ OBJECT, ARG0, ARG1 ];
    my ($nick) = split /!/, $nickstr;
    return unless $nick eq $self->get_nickname;
    $self->privmsg( $channel => "Hello, artificial humans!" );
    POE::Kernel->delay( _quit_now => 3 );
};

event _quit_now => sub {
    my ($self) = $_[OBJECT];
    $self->irc->plugin_del('Core_Connector');
    $self->irc->yield( quit => "Yes! That happened!" );
};

event irc_disconnected => sub {
    my ($self) = $_[OBJECT];
    $self->stop;
};

__PACKAGE__->async unless caller;

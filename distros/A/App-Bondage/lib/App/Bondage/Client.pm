package App::Bondage::Client;
BEGIN {
  $App::Bondage::Client::AUTHORITY = 'cpan:HINRIK';
}

use strict;
use warnings FATAL => 'all';
use Carp;
use POE qw(Filter::Line Filter::Stackable);
use POE::Component::IRC::Common qw( u_irc );
use POE::Component::IRC::Plugin qw( :ALL );
use POE::Filter::IRCD;

our $VERSION = '1.3';

sub new {
    my ($package, %self) = @_;
    if (!$self{Socket}) {
        croak "$package requires a Socket";
    }
    return bless \%self, $package;
}

sub PCI_register {
    my ($self, $irc) = @_;
    
    if (!$irc->isa('POE::Component::IRC::State')) {
        die __PACKAGE__ . " requires PoCo::IRC::State or a subclass thereof\n";
    }
    
    if (!grep { $_->isa('App::Bondage::Recall') } values %{ $irc->plugin_list() } ) {
        die __PACKAGE__ . " requires App::Bondage::Recall\n";
    }
   
    $self->{filter} = POE::Filter::IRCD->new(); 
    $self->{stacked} = POE::Filter::Stackable->new(
        Filters => [
            POE::Filter::Line->new(),
            POE::Filter::IRCD->new(),
        ]
    );
    
    ($self->{state}) = grep { $_->isa('App::Bondage::State') } values %{ $irc->plugin_list() };
    $self->{irc} = $irc;
    $irc->raw_events(1);
    $irc->plugin_register($self, 'SERVER', qw(raw));
    
    POE::Session->create(
        object_states => [
            $self => [ qw(_start _client_error _client_input) ],
        ],
    );

    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;

    $poe_kernel->call("$self", '_client_error');
    return 1;
}

sub _start {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    $kernel->alias_set("$self");

    $self->{wheel} = POE::Wheel::ReadWrite->new(
        Handle       => $self->{Socket},
        InputFilter  => $self->{stacked},
        OutputFilter => POE::Filter::Line->new(),
        InputEvent   => '_client_input',
        ErrorEvent   => '_client_error',
    );
    delete $self->{Socket};
    $self->{wheel_id} = $self->{wheel}->ID();

    my ($recall_plug) = grep { $_->isa('App::Bondage::Recall') } values %{ $self->{irc}->plugin_list() };
    $self->{wheel}->put($recall_plug->recall());
    
    return;
}

sub _client_error {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    my $irc = $self->{irc};
    
    if ($self->{wheel}) {
        # causes deep recursion somehow
        #$self->{wheel}->put('ERROR :Closing link (Caught interrupt)'); 
        #$self->{wheel}->flush();
        delete $self->{wheel};
        $irc->send_event(irc_proxy_close => $self->{wheel_id});
        $kernel->alias_remove("$self");
        $irc->plugin_del($self) if grep { $_ == $self } values %{ $irc->plugin_list() };
    }
    return;
}

sub _client_input {
    my ($self, $input) = @_[OBJECT, ARG0];
    my $irc = $self->{irc};
    my $state = $self->{state};
    
    if ($input->{command} eq 'QUIT') {
        $irc->plugin_del($self);
        return;
    }
    elsif ($input->{command} eq 'PING') {
        $self->{wheel}->put('PONG ' . $input->{params}[0] || '');
        return;
    }
    elsif ($input->{command} eq 'PRIVMSG') {
        my ($recipient, $msg) = @{ $input->{params} }[0..1];
        if ($recipient =~ /^[#&+!]/) {
            # recreate channel messages from this client for
            # other clients to see
            my $line = ':' . $irc->nick_long_form($irc->nick_name()) . " PRIVMSG $recipient :$msg";
            
            for my $client (grep { $_->isa('App::Bondage::Client') } values %{ $irc->plugin_list() } ) {
                $client->put($line) if $client != $self;
            }
        }
    }
    elsif ($input->{command} eq 'WHO') {
        if ($input->{params}[0] && $input->{params}[0] !~ tr/*//) {
            if (!defined $input->{params}[1]) {
                if ($input->{params}[0] !~ /^[#&+!]/ || $irc->channel_list($input->{params}[0])) {
                    $state->enqueue(sub { $self->put($_[0]) }, 'who_reply', $input->{params}[0]);
                    return;
                }
            }
        }
    }
    elsif ($input->{command} eq 'MODE') {
        if ($input->{params}[0]) {
            my $mapping = $irc->isupport('CASEMAPPING');
            if (u_irc($input->{params}[0], $mapping) eq u_irc($irc->nick_name(), $mapping)) {
                if (!defined $input->{params}[1]) {
                    $self->put($state->mode_reply($input->{params}[0]));
                    return;
                }
            }
            elsif ($input->{params}[0] =~ /^[#&+!]/ && $irc->channel_list($input->{params}[0])) {
                if (!defined $input->{params}[1] || $input->{params}[1] =~ /^[eIb]$/) {
                    $state->enqueue(sub { $self->put($_[0]) }, 'mode_reply', @{ $input->{params} }[0,1]);
                    return;
                }
            }
        }
    }
    elsif ($input->{command} eq 'NAMES') {
        if ($irc->channel_list($input->{params}[0]) && !defined $input->{params}[1]) {
            $state->enqueue(sub { $self->put($_[0]) }, 'names_reply', $input->{params}[0]);
            return;
        }
    }
    elsif ($input->{command} eq 'TOPIC') {
        if ($irc->channel_list($input->{params}[0]) && !defined $input->{params}[1]) {
            $state->enqueue(sub { $self->put($_[0]) }, 'topic_reply', $input->{params}[0]);
            return;
        }
    }
    
    $irc->yield(quote => $input->{raw_line});
    
    return;
}

sub S_raw {
    my ($self, $irc) = splice @_, 0, 2;
    my $raw_line = ${ $_[0] };
    return PCI_EAT_NONE if !defined $self->{wheel};

    my $input = $self->{filter}->get( [ $raw_line ] )->[0]; 
    $self->{wheel}->put($raw_line) if $input->{command} !~ /^(?:PING|PONG)/;
    return PCI_EAT_NONE;
}

sub put {
    my ($self, $raw_line) = @_;
    $self->{wheel}->put($raw_line) if defined $self->{wheel};
    return;
}

1;

=encoding utf8

=head1 NAME

App::Bondage::Client - A PoCo-IRC plugin which handles a proxy client.

=head1 SYNOPSIS

 use App::Bondage::Client;

 $irc->plugin_add('Client_1', App::Bondage::Client->new(Socket => $socket));

=head1 DESCRIPTION

App::Bondage::Client is a L<POE::Component::IRC|POE::Component::IRC> plugin.
It handles a input/output and disconnects from a proxy client.

This plugin requires the IRC component to be
L<POE::Component::IRC::State|POE::Component::IRC::State> or a subclass thereof.

=head1 METHODS

=head2 C<new>

One argument:

B<'Socket'>, the socket of the proxy client.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add()> method.

=head2 C<put>

One argument:

An IRC protocol line

Sends an IRC protocol line to the client

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut

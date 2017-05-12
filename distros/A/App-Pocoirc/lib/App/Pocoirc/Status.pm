package App::Pocoirc::Status;
BEGIN {
  $App::Pocoirc::Status::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Pocoirc::Status::VERSION = '0.47';
}

use strict;
use warnings FATAL => 'all';
use Carp;
use IRC::Utils qw(decode_irc strip_color strip_formatting numeric_to_name);
use POE::Component::IRC::Plugin qw(PCI_EAT_NONE);
use Scalar::Util qw(looks_like_number);

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    return bless { @_ }, $package;
}

sub PCI_register {
    my ($self, $irc, %args) = @_;

    $irc->raw_events(1);
    $irc->plugin_register($self, 'SERVER', 'all');
    $irc->plugin_register($self, 'USER', 'all');
    return 1;
}

sub PCI_unregister {
    return 1;
}

sub verbose {
    my ($self, $value) = @_;
    $self->{Verbose} = $value;
    return;
}

sub trace {
    my ($self, $value) = @_;
    $self->{Trace} = $value;
    return;
}

sub _normalize {
    my ($line) = @_;
    $line = decode_irc($line);
    $line = strip_color($line);
    $line = strip_formatting($line);
    return $line;
}

sub _dump {
    my ($arg) = @_;

    if (ref $arg eq 'ARRAY') {
        my @elems;
        for my $elem (@$arg) {
            push @elems, _dump($elem);
        }
        return '['. join(', ', @elems) .']';
    }
    elsif (ref $arg eq 'HASH') {
        my @pairs;
        for my $key (keys %$arg) {
            push @pairs, [$key, _dump($arg->{$key})];
        }
        return '{'. join(', ', map { "$_->[0] => $_->[1]" } @pairs) .'}';
    }
    elsif (ref $arg) {
        require overload;
        return overload::StrVal($arg);
    }
    elsif (defined $arg) {
        return $arg if looks_like_number($arg);
        return "'".decode_irc($arg)."'";
    }
    else {
        return 'undef';
    }
}

sub _event_debug {
    my ($self, $irc, $args, $event) = @_;

    if (!defined $event) {
        $event = (caller(1))[3];
        $event =~ s/.*:://;
    }

    pop @$args;
    my @output;
    for my $i (0..$#{ $args }) {
       push @output, "ARG$i: " . _dump(${ $args->[$i] });
    }

    $irc->send_event_next('irc_plugin_status', $self, 'debug', "$event: ".join(', ', @output));
    return;
}

sub S_connected {
    my ($self, $irc) = splice @_, 0, 2;
    my $address = ${ $_[0] };
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Connected to server $address");
    return PCI_EAT_NONE;
}

sub S_disconnected {
    my ($self, $irc) = splice @_, 0, 2;
    my $server = ${ $_[0] };
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Disconnected from server $server");
    return PCI_EAT_NONE;
}

sub S_snotice {
    my ($self, $irc) = splice @_, 0, 2;
    my $notice = _normalize(${ $_[0] });
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Server notice: $notice");
    return PCI_EAT_NONE;
}

sub S_notice {
    my ($self, $irc) = splice @_, 0, 2;
    my $sender = _normalize(${ $_[0] });
    my $notice = _normalize(${ $_[2] });

    $self->_event_debug($irc, \@_) if $self->{Trace};
    if (defined $irc->server_name() && $sender ne $irc->server_name()) {
        return PCI_EAT_NONE;
    }

    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Server notice: $notice");
    return PCI_EAT_NONE;
}

sub S_001 {
    my ($self, $irc) = splice @_, 0, 2;
    my $server = ${ $_[0] };
    my $nick = $irc->nick_name();
    my $event = 'S_001 ('.numeric_to_name('001').')';
    $self->_event_debug($irc, \@_, $event) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Logged in to server $server with nick $nick");
    return PCI_EAT_NONE;
}

sub S_identified {
    my ($self, $irc) = splice @_, 0, 2;
    my $nick = $irc->nick_name();
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Identified with NickServ as $nick");
    return PCI_EAT_NONE;
}

sub S_isupport {
    my ($self, $irc) = splice @_, 0, 2;
    my $isupport = ${ $_[0] };
    my $network  = $isupport->isupport('NETWORK');
    $self->_event_debug($irc, \@_) if $self->{Trace};

    if (!$self->{Dynamic} && defined $network && length $network) {
        $irc->send_event_next('irc_network', $network);
    }
    return PCI_EAT_NONE;
}

sub S_nick {
    my ($self, $irc) = splice @_, 0, 2;
    my $user    = _normalize(${ $_[0] });
    my $newnick = _normalize(${ $_[1] });
    my $oldnick = (split /!/, $user)[0];

    $self->_event_debug($irc, \@_) if $self->{Trace};
    return PCI_EAT_NONE if $newnick ne $irc->nick_name();
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Nickname changed from $oldnick to $newnick");
    return PCI_EAT_NONE;
}

sub S_join {
    my ($self, $irc) = splice @_, 0, 2;
    my $user = _normalize(${ $_[0] });
    my $chan = _normalize(${ $_[1] });
    my $nick = (split /!/, $user)[0];

    $self->_event_debug($irc, \@_) if $self->{Trace};
    return PCI_EAT_NONE if $nick ne $irc->nick_name();
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Joined channel $chan");
    return PCI_EAT_NONE;
}

sub S_part {
    my ($self, $irc) = splice @_, 0, 2;
    my $user   = _normalize(${ $_[0] });
    my $chan   = _normalize(${ $_[1] });
    my $reason = ref $_[2] eq 'SCALAR' ? _normalize(${ $_[2] }) : '';
    my $nick   = (split /!/, $user)[0];

    $self->_event_debug($irc, \@_) if $self->{Trace};
    return PCI_EAT_NONE if $nick ne $irc->nick_name();
    my $msg = "Parted channel $chan";
    $msg .= " ($reason)" if $reason ne '';
    $irc->send_event_next('irc_plugin_status', $self, 'normal', $msg);
    return PCI_EAT_NONE;
}

sub S_kick {
    my ($self, $irc) = splice @_, 0, 2;
    my $kicker = _normalize(${ $_[0] });
    my $chan   = _normalize(${ $_[1] });
    my $victim = _normalize(${ $_[2] });
    my $reason = _normalize(${ $_[3] });
    $kicker    = (split /!/, $kicker)[0];

    $self->_event_debug($irc, \@_) if $self->{Trace};
    return PCI_EAT_NONE if $victim ne $irc->nick_name();
    my $msg = "Kicked from $chan by $kicker";
    $msg .= " ($reason)" if length $reason;
    $irc->send_event_next('irc_plugin_status', $self, 'normal', $msg);
    return PCI_EAT_NONE;
}

sub S_error {
    my ($self, $irc) = splice @_, 0, 2;
    my $error = _normalize(${ $_[0] });
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Error from IRC server: $error");
    return PCI_EAT_NONE;
}

sub S_quit {
    my ($self, $irc) = splice @_, 0, 2;
    my $user   = _normalize(${ $_[0] });
    my $reason = _normalize(${ $_[1] });
    my $nick   = (split /!/, $user)[0];

    $self->_event_debug($irc, \@_) if $self->{Trace};
    return PCI_EAT_NONE if $nick ne $irc->nick_name();
    my $msg = 'Quit from IRC';
    $msg .= " ($reason)" if length $reason;
    $irc->send_event_next('irc_plugin_status', $self, 'normal', $msg);
    return PCI_EAT_NONE;
}

sub S_socketerr {
    my ($self, $irc) = splice @_, 0, 2;
    my $reason = _normalize(${ $_[0] });
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Failed to connect to server: $reason");
    return PCI_EAT_NONE;
}

sub S_socks_failed {
    my ($self, $irc) = splice @_, 0, 2;
    my $reason = _normalize(${ $_[0] });
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Failed to connect to SOCKS server: $reason");
    return PCI_EAT_NONE;
}

sub S_socks_rejected {
    my ($self, $irc) = splice @_, 0, 2;
    my $code = ${ $_[0] };
    $self->_event_debug($irc, \@_) if $self->{Trace};
    $irc->send_event_next('irc_plugin_status', $self, 'normal', "Connection rejected by SOCKS server (code $code)");
    return PCI_EAT_NONE;
}

sub S_raw {
    my ($self, $irc) = splice @_, 0, 2;
    my $raw = _normalize(${ $_[0] });
    return PCI_EAT_NONE if !$self->{Verbose};
    $irc->send_event_next('irc_plugin_status', $self, 'debug', "<<< $raw");
    return PCI_EAT_NONE;
}

sub S_raw_out {
    my ($self, $irc) = splice @_, 0, 2;
    my $raw = _normalize(${ $_[0] });
    return PCI_EAT_NONE if !$self->{Verbose};
    $irc->send_event_next('irc_plugin_status', $self, 'debug', ">>> $raw");
    return PCI_EAT_NONE;
}

sub _default {
    my ($self, $irc, $event) = splice @_, 0, 3;
    return PCI_EAT_NONE if !$self->{Trace};
    return PCI_EAT_NONE if $event =~ /^S_plugin_/;

    if (my ($numeric) = $event =~ /^[SU]_(\d+)$/) {
        my $name = numeric_to_name($numeric);
        $event .= " ($name)" if defined $name;
    }

    $self->_event_debug($irc, \@_, $event) if $self->{Trace};
    return PCI_EAT_NONE;
}

1;

=encoding utf8

=head1 NAME

App::Pocoirc::Status - A PoCo-IRC plugin which logs IRC status

=head1 DESCRIPTION

This plugin is used internally by L<App::Pocoirc|App::Pocoirc>. No need for
you to use it.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut

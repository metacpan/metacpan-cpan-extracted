package App::Pocosi::Status;
BEGIN {
  $App::Pocosi::Status::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::Pocosi::Status::VERSION = '0.03';
}

use strict;
use warnings FATAL => 'all';
use Carp;
use IRC::Utils qw(decode_irc strip_color strip_formatting numeric_to_name);
use POE::Component::Server::IRC::Plugin qw(PCSI_EAT_NONE);
use Scalar::Util qw(looks_like_number);

sub new {
    my ($package) = shift;
    croak "$package requires an even number of arguments" if @_ & 1;
    return bless { @_ }, $package;
}

sub PCSI_register {
    my ($self, $ircd, %args) = @_;
    $ircd->raw_events(1);
    $ircd->plugin_register($self, 'SERVER', 'all');
    return 1;
}

sub PCSI_unregister {
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
    my ($self, $ircd, $args, $event) = @_;

    if (!defined $event) {
        $event = (caller(1))[3];
        $event =~ s/.*:://;
    }

    pop @$args;
    my @output;
    for my $i (0..$#{ $args }) {
       push @output, "ARG$i: " . _dump(${ $args->[$i] });
    }

    $ircd->send_event_next(
        'ircd_plugin_status',
        $self,
        'debug',
        "$event: ".join(', ', @output),
    );
    return;
}

sub IRCD_connected {
    my ($self, $ircd) = splice @_, 0, 2;
    my $addr = ${ $_[1] };
    my $port = ${ $_[2] };
    my $peer = ${ $_[5] };

    my $msg = "Connected to peer $peer on $addr:$port";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_socketerr {
    my ($self, $ircd) = splice @_, 0, 2;
    my $args  = ${ $_[0] };
    my $op    = ${ $_[1] };
    my $error = ${ $_[3] };
    my $addr  = $args->{remoteaddress};
    my $port  = $args->{remoteport};
    my $peer  = $args->{name};

    my $msg = "Failed to connect to peer $peer on $addr:$port. Operation $op failed: $error";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_listener_add {
    my ($self, $ircd) = splice @_, 0, 2;
    my $port = ${ $_[0] };
    my $addr = ${ $_[2] };

    my $msg = "Started listening on $addr:$port";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_listener_del {
    my ($self, $ircd) = splice @_, 0, 2;
    my $port  = ${ $_[0] };
    my $addr  = ${ $_[2] };

    my $msg = "Stopped listening on $addr:$port";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_listener_failure {
    my ($self, $ircd) = splice @_, 0, 2;
    my $op    = ${ $_[1] };
    my $error = ${ $_[3] };
    my $port  = ${ $_[4] };
    my $addr  = ${ $_[5] };

    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $self->{Pocosi}->shutdown("Failed to listen on $addr:$port. Operation $op failed: $error");
    return PCSI_EAT_NONE;
}

sub IRCD_compressed_conn {
    my ($self, $ircd) = splice @_, 0, 2;
    my $id            = ${ $_[0] };
    my ($addr, $port) = $ircd->connection_info($id);

    my $msg = "Compressed connection to peer $addr:$port";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_error {
    my ($self, $ircd) = splice @_, 0, 2;
    my $peer   = ${ $_[1] };
    my $reason = ${ $_[2] };

    my $msg = "Failed to register with peer $peer: $reason";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_server {
    my ($self, $ircd) = splice @_, 0, 2;
    my $new_server = ${ $_[0] };
    my $by_server  = ${ $_[1] };
    my $hops       = ${ $_[2] };

    my $msg = "Server $new_server (hops: $hops) introduced to the network by $by_server";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_squit {
    my ($self, $ircd) = splice @_, 0, 2;
    my $server = ${ $_[0] };

    my $msg = "Server $server quit from the network";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_rehash {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper = ${ $_[0] };

    my $msg = "Operator $oper issued a REHASH";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_die {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper = ${ $_[0] };

    my $msg = "Operator $oper issued a DIE";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_gline {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper   = ${ $_[0] };
    my $u_mask = ${ $_[1] };
    my $h_mask = ${ $_[2] };
    my $reason = _normalize(${ $_[3] });

    my $msg = "Operator $oper set a GLINE on $u_mask\@$h_mask because: $reason";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_kline {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper   = ${ $_[0] };
    my $target = ${ $_[1] };
    my $secs   = ${ $_[2] };
    my $u_mask = ${ $_[3] };
    my $h_mask = ${ $_[4] };
    my $reason = _normalize(${ $_[5] });

    my $msg = "Operator $oper set a KLINE on $target ($u_mask\@$h_mask) for $secs seconds because: $reason";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_rkline {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper   = ${ $_[0] };
    my $target = ${ $_[1] };
    my $secs   = ${ $_[2] };
    my $u_mask = ${ $_[3] };
    my $h_mask = ${ $_[4] };
    my $reason = _normalize(${ $_[5] });

    my $msg = "Operator $oper set an RKLINE on $target ($u_mask\@$h_mask) for $secs seconds because: $reason";
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_unkline {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper   = ${ $_[0] };
    my $target = ${ $_[1] };
    my $u_mask = ${ $_[2] };
    my $h_mask = ${ $_[3] };

    my $msg = "Operator $oper removed KLINE on $target ($u_mask\@$h_mask)";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_locops {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper    = ${ $_[0] };
    my $message = _normalize(${ $_[0] });

    my $msg = "LOCOPS message from $oper: $message";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_operwall {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper    = ${ $_[0] };
    my $message = _normalize(${ $_[0] });

    my $msg = "OPERWALL message from $oper: $message";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_daemon_wallops {
    my ($self, $ircd) = splice @_, 0, 2;
    my $oper    = ${ $_[0] };
    my $message = _normalize(${ $_[0] });

    my $msg = "WALLOPS message from $oper: $message";
    $self->_event_debug($ircd, \@_) if $self->{Trace};
    $ircd->send_event_next('ircd_plugin_status', $self, 'normal', $msg);
    return PCSI_EAT_NONE;
}

sub IRCD_raw_input {
    my ($self, $ircd) = splice @_, 0, 2;
    return PCSI_EAT_NONE if !$self->{Verbose};
    my $id  = ${ $_[0] };
    my $raw = _normalize(${ $_[1] });
    $ircd->send_event_next('ircd_plugin_status', $self, 'debug', "<<< $id: $raw");
    return PCSI_EAT_NONE;
}

sub IRCD_raw_output {
    my ($self, $ircd) = splice @_, 0, 2;
    return PCSI_EAT_NONE if !$self->{Verbose};
    my $id  = ${ $_[0] };
    my $raw = _normalize(${ $_[1] });
    $ircd->send_event_next('ircd_plugin_status', $self, 'debug', ">>> $id: $raw");
    return PCSI_EAT_NONE;
}

sub _default {
    my ($self, $ircd, $event) = splice @_, 0, 3;
    return PCSI_EAT_NONE if !$self->{Trace};
    return PCSI_EAT_NONE if $event =~ /^IRCD_plugin_/;

    if (my ($numeric) = $event =~ /^IRCD_cmd_(\d+)$/) {
        my $name = numeric_to_name($numeric);
        $event .= " ($name)" if defined $name;
    }

    $self->_event_debug($ircd, \@_, $event) if $self->{Trace};
    return PCSI_EAT_NONE;
}

1;

=encoding utf8

=head1 NAME

App::Pocosi::Status - A PoCo-Server-IRC plugin which logs IRC status

=head1 DESCRIPTION

This plugin is used internally by L<App::Pocosi|App::Pocosi>. No need for
you to use it.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=cut

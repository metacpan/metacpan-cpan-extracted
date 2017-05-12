package App::MadEye::Plugin::Notify::XMPP;
use strict;
use warnings;
use base qw/App::MadEye::Plugin::Base/;
use Text::Truncate qw/truncstr/;
use Net::XMPP;
use Carp;
use Data::Dumper;
use Encode;
use XML::Stream;

sub notify : Hook {
    my ( $self, $context, $args ) = @_;

    my $config = $self->config->{config};

    my ( $username, $componentname ) = split /@/, $config->{jid};
    $config->{host} ||= $componentname;
    my $client = Net::XMPP::Client->new( debuglevel => 0 );
    my $connectattempts = 3;
    my $connectsleep    = 1;
    my ($status, $error);
    while (--$connectattempts >= 0) {
        $status = $client->Connect(
            hostname       => $config->{host},
            port           => $config->{port} || 5222,
            tls            => $config->{tls}  || 0,
            componentname  => $componentname,
            connectiontype => 'http',
        );
        last if defined $status;
        sleep $connectsleep;
    }
    unless (defined $status) {
        carp "[FATAL] failed to connect ".join(':',$config->{host}, $config->{port}) . ' : ' . $client->GetErrorCode->{text};
        return;
    }

    {

        # quick hack to connect Google Talk
        # override XML::Stream-1.22 by hirose31++
        no warnings 'redefine';
        *XML::Stream::SASLClient = sub {
            my $self     = shift;
            my $sid      = shift;
            my $username = shift;
            my $password = shift;

            my $mechanisms = $self->GetStreamFeature( $sid, "xmpp-sasl" );

            return unless defined($mechanisms);

            my $sasl = new Authen::SASL(
                mechanism => join( " ", @{$mechanisms} ),
                callback  => {
                    authname => $username . "@"
                      . (
                             $self->{SIDS}->{$sid}->{to}
                          or $self->{SIDS}->{$sid}->{hostname}
                      ),
                    user => $username,
                    pass => $password
                }
            );

            $self->{SIDS}->{$sid}->{sasl}->{client}   = $sasl->client_new();
            $self->{SIDS}->{$sid}->{sasl}->{username} = $username;
            $self->{SIDS}->{$sid}->{sasl}->{password} = $password;
            $self->{SIDS}->{$sid}->{sasl}->{authed}   = 0;
            $self->{SIDS}->{$sid}->{sasl}->{done}     = 0;

            $self->SASLAuth($sid);
        };
    }

    ( $status, $error ) = $client->AuthSend(
        username => $username,
        password => $config->{password},
        resource => 'MadEye',
    );
    unless ( $status and $status eq 'ok' ) {
        carp "[FATAL] authentication failure : $username, $status, $error";
        return;
    }

    for my $to (@{ $config->{recipients} }) {
        $client->MessageSend(
            to   => $to,
            body => encode('utf-8', _format( $args, $config->{cutoff_length} )),
        );
    }

    $client->Disconnect();
}

sub _format {
    my ( $args, $cutoff_length ) = @_;

    my $text = '';
    while ( my ( $module, $targets ) = each %$args ) {
        $module = _moniker($module);
        $text .= "= $module\n"
          . truncstr( _format_target($targets), $cutoff_length ) . "\n";
    }
    $text;
}

sub _format_target {
    my $targets = shift;

    my $text = '';
    for my $target (@$targets) {
        $text .= "- $target->{target}\n";
        $text .= "$target->{message}\n";
    }
    $text;
}

sub _moniker {
    my $module = shift;
    $module =~ s/.+:://;
    $module;
}

1;
__END__

=for stopwords XMPP hirose31

=head1 NAME

App::MadEye::Plugin::Notify::XMPP - notify with XMPP

=head1 SYNOPSIS

  - module: Notify::XMPP
    config:
      jid: example@gmail.com
      password: YOUR PASSWORD
      host: talk.google.com
      cutoff_length: 1000
      tls: 1
      recipients:
        - example@gmail.com

=head1 SCHEMA

    type: map
    mapping:
        port:
            type: int
            required: no
        jid:
            type: str
            required: yes
        password:
            required: yes
            type: str
        host:
            required: no
            type: str
        cutoff_length:
            required: yes
            type: int
        recipients:
            type: any
            required: yes
        tls:
            type: int
            required: no

=head1 AUTHOR

Tokuhiro Matsuno

=head1 THANKS TO

hirose31++ # a lot of code stolen from http://d.hatena.ne.jp/hirose31/20060817/1155821365

=head1 SEE ALSO

L<App::MadEye>, L<Net::XMPP>


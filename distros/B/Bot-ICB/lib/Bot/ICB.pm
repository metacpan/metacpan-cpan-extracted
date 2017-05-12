# -*- Mode: Perl; indent-tabs-mode: nil -*-

package Bot::ICB;

use strict;
use Net::ICB qw/:client/;

{
  no strict;
  $VERSION = 0.12;
}

sub newconn
  {
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;

    my $self = bless {}, $class;
    $self->conn(new Net::ICB());

    $self->login(@_) if @_;

    return $self;
  }

sub conn
  {
    my $self = shift;

    $self->{conn} = shift if @_;

    return $self->{conn};
  }

sub handler
  {
    my $self = shift;
    my ($name) = @_;
    $name or
      return undef;

    $self->{handlers} or
      return undef;

    return $self->{handlers}->{$name};
  }

sub login
  {
    my $self = shift;
    my %args = @_;

    my $c = $self->conn;
    $c->connect(%args) or
      die $c->error;

    my $type = "";
    my $err = "";

    ($type, $err) = $c->readmsg;
    $type eq $M_ERROR and
      die "Server error when receiving protocol packet: $err\n";
    $type eq $M_PROTO or
      die "Expected protocol packet [$M_PROTO] but received [$type]\n";

    ($type, $err) = $c->readmsg;
    $type eq $M_ERROR and
      die "Server error when receiving loginok packet: $err\n";
    $type eq $M_LOGINOK or
      die "Expected loginok packet [$M_LOGINOK] but received [$type]\n";

    my $handler = $self->handler('connect');
    &$handler($self) if $handler;

    return 1;
  }

sub add_handler
  {
    my $self = shift;
    my ($name, $handler) = @_;
    $name && $handler or
      return undef;

    $self->{handlers} = {} unless $self->{handlers};

    $name = $M_OPEN     if $name eq 'public';
    $name = $M_PERSONAL if $name eq 'msg';
    $name = $M_STATUS   if $name eq 'status';
    $name = $M_EXIT     if $name eq 'exit';

    $self->{handlers}->{$name} = $handler;

    return 1;
  }

sub start
  {
    my $self = shift;

    my $type = "";
    my $event = "";
    my @msg;
    my $handler;
    my $str;

    while (1)
      {
        if (! $self->conn)
          {
            $handler = $self->handler($M_EXIT);
            &$handler($self) if $handler;
            exit;
          }

        ($type, $event, @msg) = $self->readmsg;

        for $str ($type, $event, 'default')
          {
            $handler = $self->handler(lc $str);
            &$handler($self, $event, @msg) if $handler;
          }
      }

    return 1;
  }

sub disconnect
  {
    my $self = shift;

    $self->conn(undef);

    return 1;
  }

sub debug
  {
    my $self = shift;
    return $self->conn->debug(@_);
  }

sub error
  {
    my $self = shift;
    return $self->conn->error(@_);
  }

sub readmsg
  {
    my $self = shift;
    return $self->conn->readmsg(@_);
  }

sub sendopen
  {
    my $self = shift;
    return $self->conn->sendopen(@_);
  }

sub sendpriv
  {
    my $self = shift;
    return $self->conn->sendpriv(@_);
  }

sub sendraw
  {
    my $self = shift;
    return $self->conn->sendraw(@_);
  }

sub sendcmd
  {
    my $self = shift;
    return $self->conn->sendcmd(@_);
  }

1;
__END__

=head1 NAME

Bot::ICB - Provides a simple Net::IRC-like interface to ICB

=head1 SYNOPSIS

  use Bot::ICB;

  my $bot = Bot::ICB->newconn();

  my $on_connect = sub {
    my $bot = shift;
    $bot->sendcmd("g", "unga");    
  };

  $bot->add_handler('connect', $on_connect);

  $bot->login(user => 'dum');
  $bot->start();

=head1 DESCRIPTION

This module provides a simple Net::IRC-like interface to the ICB chat
protocol.

Sorry for the lack of documentation. See C<eg/samplebot.pl> for a
trivial example of usage.

=head1 AUTHOR

Brian Moseley E<lt>bcm-nospam@maz.org<gt>

=head1 SEE ALSO

L<Net::ICB>,
L<perl>.

=cut

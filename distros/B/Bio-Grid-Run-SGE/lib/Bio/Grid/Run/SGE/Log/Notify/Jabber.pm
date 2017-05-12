package Bio::Grid::Run::SGE::Log::Notify::Jabber;

use Mouse;
use AnyEvent;
use AnyEvent::XMPP::IM::Connection;
use Bio::Grid::Run::SGE::Util qw/my_glob MSG/;

use warnings;
use strict;
use Carp;

use 5.010;

our $VERSION = '0.042'; # VERSION

has jid       => ( is => 'rw', required => 1 );
has password  => ( is => 'rw', required => 1 );
has dest      => ( is => 'rw', required => 1 );
has type      => ( is => 'rw', default  => 'normal' );
has wait_time => ( is => 'rw', default  => 7 );

sub notify {
  my $self = shift;
  my $info = shift;
  my $dest = $self->dest;

  my $j = AnyEvent->condvar;
  my $msg_send_failed;

  my $con = AnyEvent::XMPP::IM::Connection->new(
    jid              => $self->jid,
    password         => $self->password,
    initial_presence => -10,
  );
  $con->reg_cb(
    session_ready => sub {
      my ($con) = @_;
      MSG( "Connected as " . $con->jid );
      MSG("Sending message to $dest");
      my $immsg = AnyEvent::XMPP::IM::Message->new(
        to => $dest,
        #subject => $info->{subject},
        body => $info->{message},
        type => $self->type,
      );
      $immsg->send($con);
    },
    error => sub {
      my ( $con, $error ) = @_;
      warn "Error: " . $error->string . "\n";
      $msg_send_failed = 1;
      $j->broadcast;
    },
  );

  $con->connect;
  my $timer = AnyEvent->timer( after => $self->wait_time, cb => sub { MSG "close"; $j->broadcast; } );

  $j->wait;
  $con->disconnect;
  return $msg_send_failed;
}

__PACKAGE__->meta->make_immutable();

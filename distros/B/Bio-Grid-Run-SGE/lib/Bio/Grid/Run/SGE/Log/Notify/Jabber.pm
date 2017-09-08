package Bio::Grid::Run::SGE::Log::Notify::Jabber;

use Mouse;
use AnyEvent;
use AnyEvent::XMPP::IM::Connection;
use Bio::Grid::Run::SGE::Util qw/my_glob/;

use warnings;
use strict;
use Carp;

use 5.010;

our $VERSION = '0.060'; # VERSION

has jid       => ( is => 'rw', required   => 1 );
has password  => ( is => 'rw', required   => 1 );
has type      => ( is => 'rw', default    => 'chat' );
has wait_time => ( is => 'rw', default    => 7 );
has 'to'      => ( is => 'rw', required   => 1 );
has log       => ( is => 'rw', 'required' => 1 );

sub notify {
  my $self = shift;
  my $info = shift;
  my $dest = ref $self->to eq 'ARRAY' ? $self->to : [ $self->to ];

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
      $self->log->info( "Connected as " . $con->jid );
      for my $d (@$dest) {
        $self->log->info("Sending message to $d");
        my $immsg = AnyEvent::XMPP::IM::Message->new(
          to      => $d,
          subject => $info->{subject},
          body    => $info->{body},
          type    => $self->type,
        );
        $immsg->send($con);
      }
    },
    error => sub {
      my ( $con, $error ) = @_;
      warn "Error: " . $error->string . "\n";
      $msg_send_failed = 1;
      $j->broadcast;
    },
  );

  $con->connect;
  my $timer
    = AnyEvent->timer( after => $self->wait_time, cb => sub { $self->log->info("close"); $j->broadcast; } );

  $j->wait;
  $con->disconnect;
  return $msg_send_failed;
}

__PACKAGE__->meta->make_immutable();

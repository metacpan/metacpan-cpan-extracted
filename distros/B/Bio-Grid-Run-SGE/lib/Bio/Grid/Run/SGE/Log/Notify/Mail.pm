package Bio::Grid::Run::SGE::Log::Notify::Mail;

use Mouse;

use warnings;
use strict;
use Carp;

use 5.010;
use Bio::Grid::Run::SGE::Util qw/my_glob/;

our $VERSION = '0.065'; # VERSION
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP;
use Try::Tiny;

has server => ( is => 'rw', required   => 1 );
has 'to'   => ( is => 'rw', required   => 1 );
has 'from' => ( is => 'rw', required   => 1 );
has log    => ( is => 'rw', 'required' => 1 );

sub notify {
  my $self = shift;
  my $info = shift;

  #subject => ...
  #body => ...

  my $email = Email::Simple->create(
    header => [
      To      => $self->to,
      From    => $self->from,
      Subject => $info->{subject},
    ],
    body => $info->{body},
  );
  my $transport = Email::Sender::Transport::SMTP->new(
    {
      host => $self->server->{host},
      port => $self->server->{port} // 25,
    }
  );

  my $something_failed;
  $self->log->info( "Sending mail to " . $self->to . "." );
  try {
    sendmail( $email, { transport => $transport } );
  }
  catch {
    $something_failed = 1;
    $self->log->error("sendmail error: $_");
  };

  return $something_failed;
}

__PACKAGE__->meta->make_immutable();

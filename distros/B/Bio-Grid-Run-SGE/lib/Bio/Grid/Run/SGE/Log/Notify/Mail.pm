package Bio::Grid::Run::SGE::Log::Notify::Mail;

use Mouse;

use warnings;
use strict;
use Carp;

use 5.010;
use Bio::Grid::Run::SGE::Util qw/my_glob MSG/;

our $VERSION = '0.042'; # VERSION
use Mail::Sendmail;

has smtp_server => ( is => 'rw' );
has 'dest'      => ( is => 'rw' );

sub notify {
  my $self = shift;
  my $info = shift;

  my ( $mail, $smtp_server ) = ( $self->dest, $self->smtp_server );

  unshift @{ $Mail::Sendmail::mailcfg{'smtp'} }, $smtp_server if ($smtp_server);
  my %mail = (
    to => $mail,
    %$info
  );

  my $something_failed;
  MSG("Sending mail to $mail.");
  unless ( sendmail(%mail) ) {
    $something_failed = 1;
    MSG($Mail::Sendmail::error);
  }

  MSG( "Mail log says:\n", $Mail::Sendmail::log );

  return $something_failed;
}

__PACKAGE__->meta->make_immutable();

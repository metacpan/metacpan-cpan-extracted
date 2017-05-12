package t::view::response;
use strict;
use warnings;
use base qw(ClearPress::view);
use Carp;
use HTTP::Status qw(:constants);

*create = \&read;
*update = \&read;
*delete = \&read;

sub read {
  my $self  = shift;
  my $model = $self->model;
  my $code  = $model->code;
  my $util  = $self->util;
  my $cgi   = $util->cgi;

  $self->{redirect_code} = scalar $cgi->param('redirect_code');

  my $headers = $self->headers;

  if($code == HTTP_MOVED_PERMANENTLY || $code == HTTP_FOUND) {
    $headers->header('Location', "$ENV{SCRIPT_NAME}/response/200?redirect_code=$code");
  }

  if($code == 999) {
    croak qq[Application Error];
  }

  if($code !~ /^\d+$/) {
    $code = HTTP_NOT_FOUND;
  }
  $headers->header('Status', $code);

  return;
}

1;

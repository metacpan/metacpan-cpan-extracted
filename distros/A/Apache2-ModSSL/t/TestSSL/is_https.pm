package TestSSL::is_https;

BEGIN {local $"="\n    "; warn "INC=@INC\n";}

use strict;
use warnings FATAL => 'all';
no warnings 'uninitialized';

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();

use Apache2::Const -compile => qw(OK DECLINED);

sub handler {
  my $r = shift;

  eval "require Apache2::ModSSL;";
  $r->content_type('text/plain');
  my $is_https=$r->connection->is_https;
  $is_https="UNDEF" unless( defined $is_https );
  $r->print('HAVE_SSL='.$r->dir_config('HAVE_SSL').' is_https: '.$is_https."\n");

  Apache2::Const::OK;
}

1;

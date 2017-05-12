package TestSSL::lookup;

use strict;
use warnings FATAL => 'all';

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();

use Apache2::Const -compile => qw(OK DECLINED);

sub handler {
  my $r = shift;

  eval "require Apache2::ModSSL;";
  $r->content_type('text/plain');
  my $rc;
  if( $r->uri=~m!/ext$! ) {
    $rc=$r->connection->ssl_ext_lookup(0, $r->args);
  } else {
    $rc=$r->connection->ssl_var_lookup($r->args);
  }
  $rc="UNDEF" unless( defined $rc );
  $r->print($rc."\n");

  Apache2::Const::OK;
}

1;

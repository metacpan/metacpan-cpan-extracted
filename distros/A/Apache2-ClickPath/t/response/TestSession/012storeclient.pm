package TestSession::012storeclient;

use strict;
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use Apache2::ClickPath::StoreClient;

my $bigvalue='x'x(1024*1024);

sub handler {
  my $r=shift;

  Apache2::RequestUtil->request( $r );

  my $ctx=Apache2::ClickPath::StoreClient->new;

  if( $r->args eq 'big' ) {
    my $rc=$ctx->set( blob=>$bigvalue ) && $ctx->get( 'blob' ) eq $bigvalue;
    $r->content_type( 'text/plain' );
    $r->print( $rc );

    return Apache2::Const::OK;
  }

  my $v=$ctx->get( 'value' );

  if( $r->args eq 'add' ) {
    $v++;
    $ctx->set( value=>$v );
  }
  $r->content_type( 'text/plain' );
  $r->print( defined( $v )?$v:"<UNDEF>" );

  return Apache2::Const::OK;
}

1;

__DATA__

SetHandler modperl
PerlModule TestSession::012storeclient
PerlResponseHandler TestSession::012storeclient

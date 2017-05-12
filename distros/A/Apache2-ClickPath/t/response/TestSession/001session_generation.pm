package TestSession::001session_generation;

use strict;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

sub handler {
  my $r=shift;

  my $what=$r->args;
  $r->content_type('text/plain');
  $r->print( $what."=".$r->subprocess_env($what)."\n" );

  return Apache2::Const::OK;
}

1;

__DATA__

SetHandler modperl
PerlResponseHandler TestSession::001session_generation

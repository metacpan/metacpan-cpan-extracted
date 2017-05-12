package TestSession::007uaexceptionfile;

use strict;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

sub handler {
  my $r=shift;

  my $what=$r->args;
  $what="UAExceptions" unless( length $what );
  $r->content_type('text/plain');
  $r->print( Apache2::Module::get_config('Apache2::ClickPath', $r->server)
	     ->{"ClickPath${what}File_read_time"} );

  return Apache2::Const::OK;
}

1;

__DATA__

SetHandler modperl
PerlResponseHandler TestSession::007uaexceptionfile

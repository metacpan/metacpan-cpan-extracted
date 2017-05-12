package TestConfig;

use strict;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::RequestUtil;
use Apache2::CmdParms;
use Apache2::Directive;
use Apache2::Module;
use Apache2::Const -compile=>qw{OK};

Apache2::Module::add( __PACKAGE__,
		      [
		       {
			name=>'TestHandlerConfig',
		       },
		      ] );

sub TestHandlerConfig {
  my($I, $parms, $arg)=@_;
  $I=Apache2::Module::get_config(__PACKAGE__, $parms->server);
  $I->{config}=$parms->path;
}

sub handler {
  my $r=shift;
  $r->content_type('text/plain');

  my $cf=Apache2::Module::get_config(__PACKAGE__, $r->server);
  #my $cf=Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
  $cf=$cf->{config};
  $r->print( defined $cf ? $cf : 'UNDEF' );

  return Apache2::Const::OK;
}

1;

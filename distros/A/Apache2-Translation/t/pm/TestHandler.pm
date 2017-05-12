package TestHandler;

use strict;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::RequestUtil;
use Apache2::Const -compile=>qw{OK};

sub handler : method {
  my ($c,$r)=@_;

  $r->content_type('text/plain');

  $r->print( $c );

  return Apache2::Const::OK;
}

sub pathinfo {
  my $r=shift;
  $r->content_type('text/plain');

  $r->print( $r->path_info );

  return Apache2::Const::OK;
}

sub meminfo {
  require Linux::Smaps;
  my $r=shift;
  $r->content_type('text/plain');

  my $m=Linux::Smaps->new($$);

  my @v=(qw/size rss shared_clean shared_dirty private_clean private_dirty/);
  $r->print( "$_: ".$m->$_."\n" ) for @v;

  return Apache2::Const::OK;
}

1;

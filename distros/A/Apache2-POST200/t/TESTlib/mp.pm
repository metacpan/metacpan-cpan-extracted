package TESTlib::mp;

use strict;
use Apache2::Const -compile=>qw{OK DECLINED};
use Apache2::ServerRec;
use Apache2::ServerUtil;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Connection;

sub method {
  my $r=shift;

  $r->content_type('text/slain');
  $r->headers_out->{'X-My-Header'}='hallo opi';
  $r->err_headers_out->{'X-My-Error'}='error';
  $r->print($r->method.':'.$r->args);

  return Apache2::Const::OK;
}

sub chunks {
  my $r=shift;

  $r->content_type('text/slain');
  $r->print('x' x 1);
  $r->rflush;
  $r->print('x' x 2);
  $r->rflush;
  $r->print('x' x 3);

  return Apache2::Const::OK;
}

sub big {
  my $r=shift;

  $r->content_type('text/slain');
  for( 1..1024 ) {
    $r->print('y' x 10240);
    $r->rflush;
  }

  return Apache2::Const::OK;
}

sub proxy {
  my $r=shift;

  my $backend=Apache2::ServerUtil->server->next;
  $backend=$backend->server_hostname.':'.$backend->port;
  my $url=$r->uri;
  $url=~s!^/+[^/]+!!;
  $url="http://$backend$url";
  $r->proxyreq(2);
  $r->filename("proxy:$url");
  $r->handler('proxy-server');

  return Apache2::Const::DECLINED;
}

sub setip {
  my $r=shift;

  $r->connection->remote_ip('85.25.96.79');

  return Apache2::Const::DECLINED;
}

1;

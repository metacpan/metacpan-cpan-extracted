#!perl -T

use lib '.';

use Test::More tests => 65;

use Authen::CAS::Client::Response;


# inheritance and is_* checking
{
  my %r = (
    ''           => { e => 1, f => 0, s => 0, i => [ ] },
    Error        => { e => 1, f => 0, s => 0, i => [ '' ] },
    Failure      => { e => 0, f => 1, s => 0, i => [ '' ] },
    AuthFailure  => { e => 0, f => 1, s => 0, i => [ '', 'Failure' ] },
    ProxyFailure => { e => 0, f => 1, s => 0, i => [ '', 'Failure' ] },
    Success      => { e => 0, f => 0, s => 1, i => [ '' ] },
    AuthSuccess  => { e => 0, f => 0, s => 1, i => [ '', 'Success' ] },
    ProxySuccess => { e => 0, f => 0, s => 1, i => [ '', 'Success' ] },
  );

  for my $n ( keys %r ) {
    my $t = _n( $n );
    my $o = $t->new;

    isa_ok( $o, _n( $_ ), $t )
      for @{ $r{$n}->{i} };
    isa_ok( $o, $t, $t );

    ok( _tf( $o->$_ ) == _tf( $r{$n}->{ substr $_, 3, 1 } ), "$t->$_()" )
      for qw/ is_error is_failure is_success /;
  }
}


# error object checking
{
  my $o = Authen::CAS::Client::Response::Error->new;
  is( $o->error, 'An internal error occurred', 'Authen::CAS::Client::Response::Error: error' );
  ok( ! defined $o->doc, 'Authen::CAS::Client::Response::Error: doc' );
}

{
  my $o = Authen::CAS::Client::Response::Error->new( error => 'ERROR', doc => 'DOC' );
  is( $o->error, 'ERROR', 'Authen::CAS::Client::Response::Error: error' );
  is( $o->doc, 'DOC', 'Authen::CAS::Client::Response::Error: doc' );
}

# failure object checking
{
  my $o = Authen::CAS::Client::Response::Failure->new;
  ok( ! defined $o->code, 'Authen::CAS::Client::Response::Failure: code' );
  is( $o->message, '', 'Authen::CAS::Client::Response::Failure: message' );
  ok( ! defined $o->doc, 'Authen::CAS::Client::Response::Error: doc' );
}

{
  my $o = Authen::CAS::Client::Response::Failure->new( code => 'CODE', message => 'MESSAGE', doc => 'DOC' );
  is( $o->code, 'CODE', 'Authen::CAS::Client::Response::Failure: code' );
  is( $o->message, 'MESSAGE', 'Authen::CAS::Client::Response::Failure: message' );
  is( $o->doc, 'DOC', 'Authen::CAS::Client::Response::Failure: doc' );
}

# success object checking
{
  my $o = Authen::CAS::Client::Response::AuthSuccess->new;
  ok( ! defined $o->user, 'Authen::CAS::Client::Response::AuthSuccess: user' );
  ok( ! defined $o->iou, 'Authen::CAS::Client::Response::AuthSuccess: iou' );
  ok( scalar @{ $o->proxies } == 0, 'Authen::CAS::Client::Response::AuthSuccess: proxies' );
  ok( ! defined $o->doc, 'Authen::CAS::Client::Response::AuthSuccess: doc' );
}

{
  my $o = Authen::CAS::Client::Response::AuthSuccess->new( user => 'USER', iou => 'IOU', proxies => [qw/ foo bar baz /], doc => 'DOC' );
  is( $o->user, 'USER', 'Authen::CAS::Client::Response::AuthSuccess: user' );
  is( $o->iou, 'IOU', 'Authen::CAS::Client::Response::AuthSuccess: iou' );
  is( join( ':', @{ $o->proxies } ), join( ':', qw/ foo bar baz / ), 'Authen::CAS::Client::Response::AuthSuccess: proxies' );
  is( $o->doc, 'DOC', 'Authen::CAS::Client::Response::AuthSuccess: doc' );
}

{
  my $o = Authen::CAS::Client::Response::ProxySuccess->new;
  ok( ! defined $o->proxy_ticket, 'Authen::CAS::Client::Response::ProxySuccess: proxy_ticket' );
  ok( ! defined $o->doc, 'Authen::CAS::Client::Response::ProxySuccess: doc' );
}

{
  my $o = Authen::CAS::Client::Response::ProxySuccess->new( proxy_ticket => 'PT', doc => 'DOC' );
  is( $o->proxy_ticket, 'PT', 'Authen::CAS::Client::Response::ProxySuccess: proxy_ticket' );
  is( $o->doc, 'DOC', 'Authen::CAS::Client::Response::ProxySuccess: doc' );
}


sub _n { join( '::', split( '::', "Authen::CAS::Client::Response::" . shift() ) ) }
sub _tf { shift() ? 1 : 0 }

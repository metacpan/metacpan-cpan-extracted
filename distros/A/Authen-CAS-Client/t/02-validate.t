#!perl -T

use lib '.';

use Test::More tests => 93;
use t::MockUserAgent;

use Authen::CAS::Client;

my $mock = Test::MockUserAgent->new;
my $cas  = Authen::CAS::Client->new( 'https://example.com/cas' );

my %t = (
  validate => {
    success => {
      r => [ 200, "yes\nUSER\n" ],
      v => [ 'S', 'USER', undef, undef ],
    },

    failure => {
      r => [ 200, "no\n\n" ],
      v => [ 'F', 'V10_AUTH_FAILURE', '' ],
    },

    invalid => {
      r => [ 200, "fake" ],
      v => [ 'E', qr/^Invalid CAS response\z/ ],
    },

    error => {
      r => [ 404, "fake" ],
      v => [ 'E', qr/^HTTP request failed: \d+: / ],
    },
  },

  service_validate => {
    success1 => {
      r => [ 200, _xml_success( 'USER' ) ],
      v => [ 'S', 'USER', undef, undef ],
    },

    success2 => {
      r => [ 200, _xml_success( 'USER', 'PGTIOU' ) ],
      v => [ 'S', 'USER', 'PGTIOU', undef ],
    },

    success3 => {
      r => [ 200, _xml_success( 'USER', undef, [ qw/ p1 p2 / ] ) ],
      v => [ 'S', 'USER', undef, [ qw/ p1 p2 / ] ],
    },

    success4 => {
      r => [ 200, _xml_success( 'USER', 'PGTIOU', [ qw/ p1 p2 / ] ) ],
      v => [ 'S', 'USER', 'PGTIOU', [ qw/ p1 p2 / ] ],
    },

    success5 => {
      r => [ 200, _xml_success( 'USER', undef, [ ] ) ],
      v => [ 'S', 'USER', undef, [ ] ],
    },

    failure1 => {
      r => [ 200, _xml_failure( 'CODE', 'MESSAGE' ) ],
      v => [ 'F', 'CODE', 'MESSAGE' ],
    },

    failure2 => {
      r => [ 200, _xml_failure( 'CODE', '' ) ],
      v => [ 'F', 'CODE', '' ],
    },

    failure3 => {
      r => [ 200, _xml_failure( 'CODE', undef ) ],
      v => [ 'F', 'CODE', '' ],
    },

    error1 => {
      r => [ 200, _xml_success( undef, undef, undef ) ],
      v => [ 'E', qr/^Failed to parse authentication success response\z/ ],
    },

    error2 => {
      r => [ 200, _xml_failure( undef, undef ) ],
      v => [ 'E', qr/^Failed to parse authentication failure response\z/ ],
    },

    error3 => {
      r => [ 200, '<fake xmlns:cas="http://www.yale.edu/tp/cas" />' ],
      v => [ 'E', qr/^Invalid CAS response\z/ ],
    },

    error4 => {
      r => [ 200, '<fake />' ],
      v => [ 'E', qr/^Invalid CAS response\z/ ],
    },

    error5 => {
      r => [ 200, 'fake' ],
      v => [ 'E', qr/^Failed to parse XML\z/ ],
    },

    error6 => {
      r => [ 404, 'fake' ],
      v => [ 'E', qr/HTTP request failed: \d+: / ],
    },
  },
);

$t{proxy_validate} = $t{service_validate};


for my $m ( keys %t ) {
  for ( keys %{ $t{$m} } ) {
    $mock->_response( @{ $t{$m}->{$_}{r} } );

    my $r = $cas->$m( 'S', 'T' );
    _v_response( "$m: $_", $r, @{ $t{$m}->{$_}{v} } );
  }
}


sub _v_response {
  my ( $t, $r, $o, @a ) = @_;

  if( $o eq 'S' ) {
    my ( $u, $i, $p ) = @a;
    isa_ok( $r, 'Authen::CAS::Client::Response::AuthSuccess', $t );
    is( $r->user, $u, $t );
    if( defined $i ) {
      is( $r->iou, $i, $t );
    }
    else {
      ok( !defined $r->iou );
    }
    $p = [ ]
      unless defined $p;
    is( join( ',', $r->proxies ), join( ',', @$p ), $t );
  }
  elsif( $o eq 'F' ) {
    my ( $c, $m ) = @a;
    isa_ok( $r, 'Authen::CAS::Client::Response::AuthFailure', $t );
    is( $r->code, $c, $t );
    is( $r->message, $m, $t );
  }
  else {
    my ( $e ) = @a;
    isa_ok( $r, 'Authen::CAS::Client::Response::Error', $t );
    like( $r->error, $e, $t );
  }
}

sub _xml_success {
  my ( $u, $i, $p ) = @_;

  my $xml = q{
    <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
      <cas:authenticationSuccess>
  };

  $xml .= "<cas:user>$u</cas:user>"
    if defined $u;

  $xml .= "<cas:proxyGrantingTicket>$i</cas:proxyGrantingTicket>"
    if defined $i;

  if( defined $p ) {
    $xml .= "<cas:proxies>";
    $xml .= "<cas:proxy>$_</cas:proxy>"
      for @$p;
    $xml .= "</cas:proxies>";
  }

  $xml .= q{
        </cas:authenticationSuccess>
    </cas:serviceResponse>
  };

  return $xml;
}

sub _xml_failure {
  my ( $c, $m ) = @_;

  my $xml = q{
    <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
      <cas:authenticationFailure
  };

  $xml .= qq{ code="$c"}
    if defined $c;

  $xml .= ">";

  $xml .= "\n   $m   \n"
    if defined $m;

  $xml .= q{
        </cas:authenticationFailure>
    </cas:serviceResponse>
  };

  return $xml;
}


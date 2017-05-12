#!perl -T

use lib '.';

use Test::More tests => 23;
use t::MockUserAgent;

use Authen::CAS::Client;

my $mock = Test::MockUserAgent->new;
my $cas  = Authen::CAS::Client->new( 'https://example.com/cas' );

my %t = (
  proxy => {
    success => {
      r => [ 200, _xml_success( 'PT' ) ],
      v => [ 'S', 'PT' ],
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
      r => [ 200, _xml_success( undef ) ],
      v => [ 'E', qr/^Failed to parse proxy success response\z/ ],
    },

    error2 => {
      r => [ 200, _xml_failure( undef, undef ) ],
      v => [ 'E', qr/^Failed to parse proxy failure response\z/ ],
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


for my $m ( keys %t ) {
  for ( keys %{ $t{$m} } ) {
    $mock->_response( @{ $t{$m}->{$_}{r} } );

    my $r = $cas->$m( 'PGT', 'TARGET' );
    _v_response( "$m: $_", $r, @{ $t{$m}->{$_}{v} } );
  }
}


sub _v_response {
  my ( $t, $r, $o, @a ) = @_;

  if( $o eq 'S' ) {
    my ( $p ) = @a;
    isa_ok( $r, 'Authen::CAS::Client::Response::ProxySuccess', $t );
    is( $r->proxy_ticket, $p, $t );
  }
  elsif( $o eq 'F' ) {
    my ( $c, $m ) = @a;
    isa_ok( $r, 'Authen::CAS::Client::Response::ProxyFailure', $t );
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
  my ( $p ) = @_;

  my $xml = q{
    <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
      <cas:proxySuccess>
  };

  $xml .= "<cas:proxyTicket>$p</cas:proxyTicket>"
    if defined $p;

  $xml .= q{
        </cas:proxySuccess>
    </cas:serviceResponse>
  };

  return $xml;
}

sub _xml_failure {
  my ( $c, $m ) = @_;

  my $xml = q{
    <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
      <cas:proxyFailure
  };

  $xml .= qq{ code="$c"}
    if defined $c;

  $xml .= ">";

  $xml .= "\n   $m   \n"
    if defined $m;

  $xml .= q{
        </cas:proxyFailure>
    </cas:serviceResponse>
  };

  return $xml;
}


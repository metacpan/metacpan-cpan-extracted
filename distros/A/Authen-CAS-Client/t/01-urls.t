#!perl -T

use Test::More tests => 20;

use Authen::CAS::Client;
use URI;
use URI::QueryParam;

sub CAS_SERVER () { 'https://example.com/cas' }


my $cas = Authen::CAS::Client->new( CAS_SERVER );

my %t = (
  login_url => {
    m => [ 'SERVICE' ],
    u => [ '/login', service => 'SERVICE' ],
    t => [
      { m => [ ], u => [ ] },
      { m => [ renew => 1 ], u => [ renew => 'true' ] },
      { m => [ gateway => 1 ], u => [ gateway => 'true' ] },
      { m => [ renew => 1, gateway => 1 ], u => [ renew => 'true' ] },
    ],
  },

  logout_url => {
    m => [ ],
    u => [ '/logout' ],
    t => [
      { m => [ ], u => [ ] },
      { m => [ url => 'http://example.com/logout' ], u => [ url => 'http://example.com/logout' ] },
    ],
  },
);

for my $m ( keys %t ) {
  url_is( $cas->$m( @{ $t{$m}->{m} }, @{ $_->{m} } ), _url( @{ $t{$m}->{u} }, @{ $_->{u} } ), $m )
    for @{ $t{$m}->{t} };
}


sub url_is {
  my ( $x, $y, $test ) = @_;

  $x = URI->new( $x ); $y = URI->new( $y );

  is( $x->scheme . '://' . $x->authority . $x->path, $y->scheme . '://' . $y->authority . $y->path, $test );

  @x = $x->query_param; @y = $y->query_param;

  ok( @x == @y, $test );
  is( $x->query_param( $_ ), $y->query_param( $_ ), $test )
    for @y;
}

sub _url {
  my ( $path, %params ) = @_;

  my $url = URI->new( CAS_SERVER . $path );
  $url->query_param_append( $_ => $params{$_} )
    for keys %params;

  return $url->canonical;
}

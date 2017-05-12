use Test::More;
use strict;
use warnings;

use Articulate::TestEnv;
use Articulate::Validation;
use Articulate::Item;

my $app = app_from_config();

my $empty_v = Articulate::Validation->new(
  app        => $app,
  validators => []
);

ok(
  $empty_v->validate( item( {}, 'foo bar' ) ),
  'empty validator assumes everything validates ok'
);

my $v = Articulate::Validation->new(
  app        => $app,
  validators => 'Articulate::Validation::NoScript'
);

sub item {
  Articulate::Item->new(
    {
      meta    => ( shift // {} ),
      content => ( shift // '' )
    }
  );
}

ok( $v->validate( item( {}, 'foo bar' ) ), 'innocuous text validates ok' );
ok( !$v->validate( item( {}, 'foo <script>nasty_xss()</script> bar' ) ),
  'nasty script fails' );

done_testing;

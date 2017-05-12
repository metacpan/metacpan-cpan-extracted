
use strict;
use warnings;

use Test::More skip_all => 'Example alternative technique that doesn\'t work';

use lib "t/lib/";
use Data;

sub getfd {
  my $handle = do {
    no strict 'refs';
    \*{"Data::DATA"};
  };
  open my $dh, "<&=", $handle;
  return $dh;
}

my $x = getfd();
my $y = getfd();

local $/ = undef;

my $x_data = <$x>;
my $y_data = <$y>;

is( $x_data, $y_data, "Values are the same" );


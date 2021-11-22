#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use API::Mathpix;


if ($ENV{MATHPIX_APP_ID} && $ENV{MATHPIX_APP_KEY}) {

  plan tests => 2;

  my $mathpix = API::Mathpix->new({
    app_id  => $ENV{MATHPIX_APP_ID},
    app_key => $ENV{MATHPIX_APP_KEY},
  });

  my $response = $mathpix->process({
    src     => 'https://mathpix.com/examples/limit.jpg',
  });

  ok($response->text eq "\\( \\lim _{x \\rightarrow 3}\\left(\\frac{x^{2}+9}{x-3}\\right) \\)", "Ok !");

  $response = $mathpix->process({
    src     => 't/test.png',
  });

  ok($response->text eq '\\( \\sum_{i=1}^{m} q_{i}(n)=1 \\)', "Ok !");


}

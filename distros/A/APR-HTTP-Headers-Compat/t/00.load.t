use Test::More tests => 1;

BEGIN {
  use_ok( 'APR::HTTP::Headers::Compat' );
}

diag(
  "Testing APR::HTTP::Headers::Compat $APR::HTTP::Headers::Compat::VERSION"
);

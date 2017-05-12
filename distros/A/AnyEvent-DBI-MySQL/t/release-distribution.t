
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Test::More;

eval { require Test::Distribution };
plan( skip_all => 'Test::Distribution not installed' ) if $@;
Test::Distribution->import(
   podcoveropts => {
#        also_private    => [
#            qr/^(?:IMPORT)$/,
#        ],
#        pod_from        => 'MAIN PM FILE HERE',
   }
);

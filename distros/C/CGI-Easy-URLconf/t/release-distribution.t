
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
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

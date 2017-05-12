## no critic(RCS,VERSION,explicit,Module,eval)
use strict;
use warnings;

use Test::More;

if( ! $ENV{RELEASE_TESTING} ) {
  plan skip_all =>
    'Author only test: META.json tests run only if RELEASE_TESTING set.';
}
elsif ( ! eval 'use Test::CPAN::Meta::JSON; 1;' ) {
  plan skip_all =>
    'Author META.json test requires Test::CPAN::Meta::JSON.'
}
else {
  note 'Testing META.json';
}
  
meta_json_ok();

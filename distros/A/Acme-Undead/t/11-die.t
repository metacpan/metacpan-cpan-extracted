use strict;
use warnings;
use Test::More;
use Test::Exception;


subtest 'not die if use Acme::Undead' => sub {
  use Acme::Undead;
  lives_ok { die(1 ) } 'undead is not die';
  no Acme::Undead;
};

subtest 'not die if not use Acme::Undead' => sub {
  dies_ok { die(1 ) } 'is die';
};

done_testing();

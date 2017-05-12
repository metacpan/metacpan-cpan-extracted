#!perl
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 3;

use_ok('App::Addex');

my $addex = App::Addex->new({
  classes => {
    addressbook => 'App::Addex::AddressBook::Test',
    output      => [ 'App::Addex::Output::Procmail' ],
  },
  'App::Addex::Output::Procmail' => {
     filename => \(my $buffer),
  },
});

isa_ok($addex, 'App::Addex');

$addex->run;

my $expected_recipe = <<'END';
:0
* From:.*jcap@example.com
.co-workers.jcap/
END

ok(
  index($buffer, $expected_recipe) > -1,
  "found the expected recipe for jcap in the procmail output",
);


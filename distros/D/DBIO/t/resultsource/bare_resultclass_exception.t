use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

{
  package DBIO::Test::Foo;
  use base "DBIO::Core";
}

throws_ok { DBIO::Test::Foo->new("urgh") } qr/must be a hashref/;

done_testing;

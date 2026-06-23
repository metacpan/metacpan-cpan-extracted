use warnings;
use strict;

use Test::More;

use DBIO::Test;

{
  package AAA;

  use base "DBIO::Core";
}

{
  package BBB;

  use base 'AAA';

  #Injecting a direct parent.
  __PACKAGE__->inject_base( __PACKAGE__, 'AAA' );
}

{
  package CCC;

  use base 'AAA';

  #Injecting an indirect parent.
  __PACKAGE__->inject_base( __PACKAGE__, 'DBIO::Core' );
}

eval { mro::get_linear_isa('BBB'); };
ok (! $@, "Correctly skipped injecting a direct parent of class BBB");

eval { mro::get_linear_isa('CCC'); };
ok (! $@, "Correctly skipped injecting an indirect parent of class BBB");

# MSSQL-specific MRO tests moved to DBIO-MSSQL distribution

if ($] >= 5.010) {
  ok (! $INC{'Class/C3.pm'}, 'No Class::C3 loaded on perl 5.10+');
}

done_testing;

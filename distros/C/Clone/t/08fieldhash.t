# $Id: 07magic.t,v 1.8 2007/04/20 05:40:48 ray Exp $

use strict;
use warnings;

use Clone 'clone';

BEGIN {
  use Test::More;
  eval {
    require Hash::Util::FieldHash;
    Hash::Util::FieldHash->import('fieldhash');
  };
  if ($@) {
    plan skip_all => 'Hash::Util::FieldHash not available';
  }
  else {
    plan tests => 1;
  }
}

fieldhash my %hash;

my $var = {};

exists $hash{ \$var };

my $cloned = clone($var);
cmp_ok($cloned, '!=', $var);


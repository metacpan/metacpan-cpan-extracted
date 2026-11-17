use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBIO::SQLite::Test::Conformance;

# The deviation of bind-numeric-exact is recognised by the text of what was
# read back. That text is the output of this perl for the double the column
# holds: its NV and its C runtime write it (1.23456789012346e+15, or
# e+015 on an older Windows perl, or 1234567890123456.75 on a perl with a
# wider NV), so the expectation is computed here the same way, not spelled out.
my $fact = DBIO::SQLite::Test::Conformance->conformance_refusals
  ->{'bind-numeric-exact'}{fact};

my $real  = unpack 'd', pack 'd', '1234567890123456.7890';
my $tenfold = unpack 'd', pack 'd', '12345678901234567.890';

# Both outputs must differ on every perl for the unlike cases to mean anything.
isnt "$real", "$tenfold", 'the two values are written differently by this perl';

like "read back '$real'",  $fact, "declared fact matches $real";
like "read back '-$real'", $fact, "declared fact matches -$real";

unlike "read back '1234567890123456.7890'", $fact,
  'the exact decimal is not hidden behind the declaration';
unlike "read back '$tenfold'", $fact,
  'a value of another magnitude is not hidden behind the declaration';

done_testing;

package IRC::Schema::ResultSet::Channel;

use IRC::Schema::CandyRS;

sub test_experimental { eval <<'EVAL'
   sub ($a) { $a + 1}
EVAL
}

1;

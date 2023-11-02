use strict;
use warnings;

use CPAN::Changes;
use Test::More;

my $less = <<'EOF';
1.7.5 2013-08-01T09:48:11Z
 - Top Level Entry

 [Group]
 - Child Entry Line 1
 - Child Entry Line 2
EOF

my $more = <<'EOF';
1.7.5 2013-08-01T09:48:11Z
  - Top Level Entry

  [ Group ]
    - Child Entry Line 1
    - Child Entry Line 2
EOF

for my $text ($less, $more) {
  my $changes = CPAN::Changes->load_string( $text );
  my $serialize = $changes->serialize;
  is +CPAN::Changes->load_string( $serialize )->serialize, $serialize,
    'changes roundtrips correctly';
}

done_testing;

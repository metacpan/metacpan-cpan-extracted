use strict;
use Test;
use Apache::Htgroup;

BEGIN { plan tests => 4 }

# test 1
my $ht = Apache::Htgroup->load('t/test.acl');
ok( defined $ht );

# test 2
ok( $ht->ismember( 'them', 'group1' ));

# test 3
ok( $ht->ismember( 'tom', 'group2' ));

# test 4
ok( $ht->ismember( 'ralph', 'group3' ));


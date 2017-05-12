use strict;
use Test;
use Apache::Htgroup;

BEGIN { plan tests => 3 }

# test 1
my $ht = Apache::Htgroup->new();
ok( defined $ht );

# test 2
$ht->adduser( 'perl', 'language' );
ok( $ht->ismember( 'perl', 'language' ) );

# test 3
$ht->reload;
ok( !( $ht->ismember( 'perl', 'language' )));


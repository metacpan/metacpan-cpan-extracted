use strict;
use Test;
use Apache::Htgroup;

BEGIN { plan tests => 3 }

# test 1
my $ht = Apache::Htgroup->new();
ok(defined $ht);

# test 2
$ht->adduser( 'bob', 'admins' );
ok( $ht->{groups}->{admins}->{bob} == 1 );

# test 3
$ht->save( 't/test1.acl' );
ok( -e 't/test1.acl' );


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Archive-Heritrix.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 90;
BEGIN { use_ok('Archive::Heritrix') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $arc;

$arc = Archive::Heritrix->new( file => 'eg/a.arc.gz' );
ok( $arc );
while ( my $rec = $arc->next_record() ) {
  ok( $rec );
}

$arc = Archive::Heritrix->new( directory => 'eg' );
ok( $arc );
while ( my $rec = $arc->next_record() ) {
  ok( $rec );
}

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use BerkeleyDB::Locks;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use BerkeleyDB ;
use strict ;

mkdir 'db' unless -d 'db' ;

my $flag = 'ok' ;
my $e = new BerkeleyDB::Env
	-Flags => DB_CREATE | DB_INIT_MPOOL | DB_INIT_CDB,
	-Home => 'db',
	;

my $db = tie my %db, 'BerkeleyDB::Btree',
	-Env => $e,
	-Flags => DB_CREATE,
	-Filename => 'dbfoo',
	;

if ( fork ) {
	## read lock
	$db = tie my %db, 'BerkeleyDB::Btree',
		-Env => $e,
		-Flags => DB_CREATE,
		-Filename => 'dbfoo',
		;

	local $SIG{ALRM} = sub { $flag = undef } ;

	$db{test} = 'failed' ;

	print stderr "  attempting read lock...\n" ;
	my ( $k, $v ) ;
	my $c = $db->db_cursor ;
	$c->c_get( $k, $v, DB_FIRST ) ;

	alarm( 4 ) ;
	while ( $flag ) {
		sleep 1 ;
		}
	alarm( 0 ) ;

	## don't know how to get this to display correctly...
	ok( $db{test}, 'ok' ) ;
	exit ;
	}

if ( fork ) {
	## write lock
	$db = tie my %db, 'BerkeleyDB::Btree',
		-Env => $e,
		-Flags => DB_CREATE,
		-Filename => 'dbfoo',
		;

	sleep 1 ;
	print stderr "  attempting write lock...\n" ;
	## this statement blocks
	$db{test} = 'ok' ;
	exit ;
	}

sleep 2 ;
print stderr "  searching for locks...\n" ;
my $watch = new BerkeleyDB::Locks $e ;
my @locks = $watch->poll() ;

print stderr sprintf "  lock detected: %d\n", $locks[0] ;
ok( scalar @locks, 2 ) ;

$watch->monitor() ;
## comment out the next line to force a test failure
push @locks, $watch->monitor() ;
ok( $locks[0], $locks[2] ) ;
print stderr sprintf "  lock released: %d\n", $locks[2] ;

wait ;

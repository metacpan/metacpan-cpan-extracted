use Test::More 'no_plan';

use Digest::MD5 qw(md5_hex);
use File::Spec::Functions;
use File::Temp;
use Test::Output;

my $class  = 'CPAN::PackageDetails';
my $method = 'allow_packages_only_once';

use_ok( $class );
can_ok( $class, $method );
can_ok( $class, 'already_added' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with nothing given to new, and some entries added
# It should only allow one package name in the entries
{
my $basename = 'three_entries.gz';

my $package_details = $class->new;
ok( $package_details->$method, "$method is true by default" );

my @entries = (
	[ qw( Animal::Cat::Buster 1.23 ) ],
	[ qw( Animal::Cat::Mimi   5.67 ) ]
	);
	
foreach my $entry ( @entries )
	{
	my $rc = $package_details->add_entry( 
		package_name => $entry->[0],
		version      => $entry->[1],
		path         => 'a/b/c.tgz',
		);
		
	ok( $rc, "Added $entry->[0] without problems" );
	ok( $package_details->already_added( $entry->[0] ), 
		"Index is tracking $entry->[0]" );
	}

ok( $package_details->already_added( $entries[0][0] ), 
	"Already added $entries[0][0]" );

my $rc = eval {
	$package_details->add_entry(
		package_name => $entries[0][0],
		version      => $entries[0][1],
		path         => 'a/b/c.tgz',
		);
	};
my $at = $@;

ok( ! defined $rc, "Re-added $entries[0][0] had problems (good)" );
like( $at, qr/was already added/, "Error message notes that $entries[0][0] is already indexed" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with new set to allow duplicates, and some entries added
# It can show more than one package name in the entries
{
my $basename = 'three_entries.gz';

my $package_details = $class->new(
	allow_packages_only_once => 0
	);
ok( ! $package_details->$method, "allow_packages_only_once is turned off" );

my @entries = (
	[ qw( Animal::Cat::Buster 1.23 ) ],
	[ qw( Animal::Cat::Mimi   5.67 ) ]
	);
	
foreach my $entry ( @entries )
	{
	my $rc = $package_details->add_entry( 
		package_name => $entry->[0],
		version      => $entry->[1],
		path         => 'a/b/c.tgz',
		);
		
	ok( $rc, "Added $entry->[0] without problems" );
	ok( $package_details->already_added( $entry->[0] ), 
		"Index is tracking $entry->[0]" );
	}

ok( $package_details->already_added( $entries[0][0] ), 
	"Already added $entries[0][0]" );

my $rc = eval {
	$package_details->add_entry(
		package_name => $entries[0][0],
		version      => $entries[0][1],
		path         => 'a/b/c.tgz',
		);
	};

ok( defined $rc, "Re-added $entries[0][0] without a problem (good)" );
}

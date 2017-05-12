#!perl
use Test::More;
use strict;
use warnings;

plan eval "require DBM::Deep; 1" ? 
	(tests => 19) : (skip_all => 'You need DBM::Deep');

use File::Spec::Functions;
use File::Temp;
use Test::Output;
use Data::Dumper;

my $class  = 'CPAN::PackageDetails';
my $method = 'get_entries_by_package';

use_ok( $class );

my $dbmfile = catfile( qw(t packages.dbm) );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with nothing given to new, and some entries added
{
unlink $dbmfile;
ok( ! -e $dbmfile, "DBM::Deep file is not there at the start" );
my $package_details = $class->new( dbmdeep => $dbmfile );
isa_ok( $package_details, $class );
isa_ok( $package_details, 'DBM::Deep' );
can_ok( $package_details, $method );
ok( -e $dbmfile, 'The dbm file shows up on object creation' );

can_ok( $package_details->entries, $method );
	
my $rc = eval { $package_details->add_entry(
	'package name' => 'Buster::Bean',
	version        => 1.02,
	path           => 'B/BU/BUSTER/Bean-1.23.tgz',
	) };
	
ok( $rc, "Added entry for Buster::Bean" );

is( $package_details->count, 1, "Count is the same number as added entries" );

my @packages = $package_details->get_entries_by_package( 'Buster::Bean' );
is( scalar @packages, 1, "Found 1 package entry" );
is( $packages[0]{'package name'}, 'Buster::Bean', 'Got same package' );

my @distributions = $package_details->get_entries_by_distribution( 'Bean' );
is( scalar @distributions, 1, "Found 1 distribution entry" );
is( $distributions[0]{'path'}, 'B/BU/BUSTER/Bean-1.23.tgz', 'Got same distro' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with existing file
{
ok( -e $dbmfile, "DBM::Deep file is not there at the start" );

my $package_details = $class->new( dbmdeep => $dbmfile );
my $class = ref $package_details;
is( $package_details->count, 1, "Count is the same number as added entries" );

my @packages = $package_details->get_entries_by_package( 'Buster::Bean' );
is( scalar @packages, 1, "Found 1 package entry" );
is( $packages[0]{'package name'}, 'Buster::Bean', 'Got same package' );

my @distributions = $package_details->get_entries_by_distribution( 'Bean' );
is( scalar @distributions, 1, "Found 1 distribution entry" );
is( $distributions[0]{'path'}, 'B/BU/BUSTER/Bean-1.23.tgz', 'Got same distro' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with existing file
unless( $ENV{DEBUG} )
	{
	unlink $dbmfile;
	}
else
	{
	print "Keeping file $dbmfile for debugging";
	}


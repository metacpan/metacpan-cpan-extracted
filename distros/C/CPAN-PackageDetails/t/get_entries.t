use Test::More tests => 19;
use strict;
use warnings;

use File::Spec::Functions;
use File::Temp;
use Test::Output;

my $class  = 'CPAN::PackageDetails';
my $method = 'get_entries_by_package';

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with nothing given to new, and some entries added
{
my $package_details = $class->new( allow_packages_only_once => 0 );
isa_ok( $package_details, $class );
can_ok( $package_details, $method );

can_ok( $package_details->entries, $method );

my @entries_to_add = (
	[ 'Foo::Bar',  '1.03',    '/a/b/c/Foo-1.01.tgz'       ],
	[ 'Foo::Bart', '1.03',    '/a/b/c/Foo-1.01.tgz'       ],
	[ 'Foo::Bar',  '1.01',    '/a/b/c/Foo-1.01.tgz'       ],
	[ 'Foo::Bar',  '1.02',    '/a/b/c/Foo-1.02.tgz'       ],
	[ 'Foo::Baz',  '1.02',    '/a/b/c/Foo-Baz-1.02.tgz'   ],	
	[ 'Foo::Baz',  '1.02_01', '/a/b/c/Foo-Baz-1.02_01.tgz'],	
	[ 'Quux',      '2800',    '/a/b/c/Quux-2800.tgz'      ],	
	);
	
foreach my $tuple ( @entries_to_add )
	{
	my $rc = eval { $package_details->add_entry(
		'package name' => $tuple->[0],
		version        => $tuple->[1],
		path           => $tuple->[2],
		) };
		
	ok( $rc, "Added entry for $tuple->[0]" );
	}

is( $package_details->count, scalar @entries_to_add, 
		"Count is the same number as added entries" );

my @packages = (
	[ qw( Foo::Bar 3) ],
	[ qw( Quux     1) ],
	[ qw( Foo::Baz 2) ],
	);
	
foreach my $pair ( @packages )
	{
	my( $package, $count ) = @$pair;
	my @packages = $package_details->get_entries_by_package( $package );
	is( scalar @packages, $count, "Found $count $package entries" );
	}

my @distributions = (
	[ qw( Foo-Baz 2) ],
	[ qw( Quux    1) ],
	[ qw( Foo     4) ],
	[ qw( Foo-Bar 0) ],
	);
	
foreach my $distribution ( @distributions )
	{
	my( $distribution, $count ) = @$distribution;
	my @distributions = $package_details->get_entries_by_distribution( $distribution );
	is( scalar @distributions, $count, "Found $count $distribution entries" );
	}
	
}


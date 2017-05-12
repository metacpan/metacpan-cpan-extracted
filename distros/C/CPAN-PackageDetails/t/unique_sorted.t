use Test::More tests => 19;
use strict;
use warnings;

use File::Spec::Functions;
use File::Temp;
use Test::Output;

my $class  = 'CPAN::PackageDetails';
my $method = 'as_unique_sorted_list';

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Test with nothing given to new, and some entries added
{
my $basename = 'three_entries.gz';

my $package_details = $class->new( allow_packages_only_once => 0 );
isa_ok( $package_details, $class );
can_ok( $package_details, $method );

is( $package_details->allow_packages_only_once, 0, "allow_packages_only_once is false" );

can_ok( $package_details->entries, $method );


# dpan/authors/id/D/DR/DRW/DRW-Constants-v1.15.175254.build-0158.tar.gz
# dpan/authors/id/D/DR/DRW/DRW-Constants-v1.15.175254.build-0159.tar.gz
my @entries_to_add = (
	[ 'Foo::Bar', '1.03',    '/a/b/c/Foo-1.01.tgz'       ],
	[ 'Foo::Bar', '1.01',    '/a/b/c/Foo-1.01.tgz'       ],
	[ 'Foo::Bar', '1.02',    '/a/b/c/Foo-1.02.tgz'       ],
	[ 'Foo::Baz', '1.02',    '/a/b/c/Foo-Baz-1.02.tgz'   ],	
	[ 'Foo::Baz', '1.02_01', '/a/b/c/Foo-Baz-1.02_01.tgz'],	
	[ 'Quux',     '2800',    '/a/b/c/Quux-2800.tgz'      ],	
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

is( scalar $package_details->$method, 3,
	"There are only three unique packages" );
	
my( $list )= $package_details->$method;

is( $list->[0]{'package name'}, 'Foo::Bar', "Foo::Bar is the first one in the list" );
is( $list->[0]{version}, '1.03',     "Foo::Bar has latest version" );

is( $list->[1]{'package name'}, 'Foo::Baz', "Foo::Baz is the second one in the list" );
is( $list->[1]{version}, '1.02_01',     "Foo::Baz has latest version" );

is( $list->[-1]{'package name'}, 'Quux', "Quux is the last one in the list" );


#my $string = $package_details->as_string;
open my($fh), ">", \ my $string;

$package_details->write_fh( $fh );

like( $string, qr/^Line-Count: 3/m, "Line count shows three lines" );
}


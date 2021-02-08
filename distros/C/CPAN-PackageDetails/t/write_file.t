use Test::More;

use Digest::MD5 qw(md5_hex);
use File::Spec::Functions;
use File::Temp;
use Test::Output;

no warnings;

my $class  = 'CPAN::PackageDetails';
my $method = 'write_file';

use_ok( $class );
can_ok( $class, $method );

my $output_dir = catfile( qw(t test_output) );
mkdir $output_dir;
ok( -e $output_dir, 'Output directory [$output_dir] exists' );

my $regression_dir = catfile( qw(t test_regression) );
ok( -e $regression_dir, 'Regression directory [$regression_dir] exists' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with nothing given to new, and no entries
{
my $basename = 'no_entries.gz';

my $output_file     = catfile( $output_dir,     $basename );
my $regression_file = catfile( $regression_dir, $basename );

unlink $output_file;
ok( ! -e $output_file, "Test file $output_file does not exist yet" );
ok( -e $regression_file, "Regression file $regression_file exists" );

my $package_details = $class->new;
isa_ok( $package_details, $class );
can_ok( $package_details, $method );

ok( $package_details->$method( $output_file ), "$method returns true for $output_file" );
ok( -e $output_file, "Output file now exists" );

TODO: {
local $TODO = "Haven't figured out how to compare files";

is( md5_hex($output_file), md5_hex($regression_file), "MD5 digests for gzipped files match")
}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with nothing given to new, and some entries added
{
my $basename = 'three_entries.gz';

my $output_file     = catfile( $output_dir,     $basename );
my $regression_file = catfile( $regression_dir, $basename );

unlink $output_file;
ok( ! -e $output_file, "Test file $output_file does not exist yet" );
ok( -e $regression_file, "Regression file $regression_file exists" );

my $package_details = $class->new;
isa_ok( $package_details, $class );
can_ok( $package_details, $method );

my @entries_to_add = (
	[ 'Foo::Bar', '1.01',    '/a/b/c/Foo-1.01.tgz'],
	[ 'Foo::Baz', '1.02_01', '/a/b/c/Foo-Baz-1.02_01.tgz'],
	[ 'Quux',     '2800',    '/a/b/c/Quux-2800.tgz'],
	);

foreach my $tuple ( @entries_to_add )
	{
	$package_details->add_entry(
		'package name' => $tuple->[0],
		version        => $tuple->[1],
		path           => $tuple->[2],
		);
	}

is( $package_details->count, scalar @entries_to_add,
		"Count is the same number as added entries");

ok( $package_details->$method( $output_file ), "$method returns true for $output_file" );
ok( -e $output_file, "Output file now exists" );

TODO: {
local $TODO = "Haven't figured out how to compare files";

is( md5_hex($output_file), md5_hex($regression_file), "MD5 digests for gzipped files match")
}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it fails if I don't give it a filename
{
my $package_details = $class->new;
isa_ok( $package_details, $class );
can_ok( $package_details, $method );

stderr_like
	{ $package_details->$method() }
	qr/Missing argument/,
	"$method fails without a filename";
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test that it fails if I don't give it a bad filename
{
my $bad_dir  = catfile( qw(tt foo bar baz));
my $bad_file = catfile( $bad_dir, 'output.txt.gz');
ok( ! -d $bad_dir, "Bad directory [$bad_dir] is not there" );

my $package_details = $class->new;
isa_ok( $package_details, $class );
can_ok( $package_details, $method );

stderr_like
	{ $package_details->$method( $bad_file ) }
	qr/Could not open/,
	"$method fails without a bad filename";
}

done_testing();

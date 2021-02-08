use Test::More;

use File::Spec::Functions;
use Test::Output;

my $class  = 'CPAN::PackageDetails';
my $method = 'read';

use_ok( $class );
can_ok( $class, $method );

my $file = catfile( qw(t test_files 02packages.details.txt.gz) );
ok( -e $file, "Test file $file exists" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with single, good argument to read
{
my $lines = 1438;

my $package_details = $class->$method( $file );

isa_ok( $package_details, $class );
is( $package_details->source_file, $file, "Get back the right filename");

# test with the top level
# these are values taken from the input file
is( $package_details->file, '02packages.details.txt',
	'file field reports right value from top level'
	);
is( $package_details->url, 'http://www.perl.com/CPAN/modules/02packages.details.txt',
	'url field reports right value from top level'  );

is( $package_details->count, $lines,
	'line field reports right value from top level'  );

is( $package_details->line_count, $lines,
	"Entries has the right number of elements from delegate level");

# test with the delegate level
# these are values taken from the input file
my $header = $package_details->header;

is( $header->file, '02packages.details.txt',
	'file field reports right value from delegate level'
	);
is( $header->url, 'http://www.perl.com/CPAN/modules/02packages.details.txt',
	'url field reports right value from delegate level'  );

is( $header->line_count, $lines,
	'line field reports right value from delegate level'  );

my $entries = $package_details->entries;
is( $entries->count, $lines,
	"Entries has the right number of elements from delegate level");

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Simple round-tripping test
unlike( $header->as_string, qr/^ line-count: [^\n]* \n .* ^ line-count: /ixms,
        "Round-tripping parsed header doesn't duplicate Line-Count" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with no arguments to read - should fail
stderr_like
	{ $class->$method() }
	qr/Missing argument!/,
	"$method carps when I don't give it an argument";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with a single bad argument to read (missing file) - should fail
{
my $missing_file = 'fooey.gz';
ok( ! -e $missing_file, "Missing file is not there" );

stderr_like
	{ $class->$method( $missing_file  ) }
	qr/Could not open/,
	"$method carps when I don't give it an argument";
}

done_testing();

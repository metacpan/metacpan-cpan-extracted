use Test::More;

use Digest::MD5 qw(md5_hex);
use File::Spec::Functions;
use File::Temp;
use Test::Output;

my $class  = 'CPAN::PackageDetails';
my $method = 'as_string';

use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test with nothing given to new, and some entries added
{
my $basename = 'three_entries.gz';

my $package_details = $class->new;
isa_ok( $package_details, $class );
TODO: { local $TODO = "Not implemented"; can_ok( $package_details, $method ); };
can_ok( $package_details->header,  $method );
can_ok( $package_details->entries, $method );

my @entries_to_add = (
	[ 'Foo::Bar', '1.01',    '/a/b/c/Foo-1.01.tgz'],
	[ 'Foo::Baz', '1.02_01', '/a/b/c/Foo-Baz-1.02_01.tgz'],
	[ 'Quux',     '2800',    '/a/b/c/Quux-2800.tgz'],
	);

foreach my $tuple ( @entries_to_add ) {
	no warnings;
	$package_details->add_entry(
		'package name' => $tuple->[0],
		version        => $tuple->[1],
		path           => $tuple->[2],
		);
	}

is( $package_details->count, scalar @entries_to_add,
		"Count is the same number as added entries");

my @columns = ( 'package_name', qw(version path));
my $entries = $package_details->entries->{entries}; # XXX yuck

foreach my $package ( keys %$entries ) {
	my $package_hash = $entries->{$package};

	foreach my $hash ( values %$package_hash ) {
		my $entry = $hash;
		ok( length( $entry->as_string( @columns ) ) > 1, "Some sort of string comes back from entry")
		}
	}

}

done_testing();

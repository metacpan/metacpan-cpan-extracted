use Test::More 'no_plan';

use strict;
use warnings;

my $class  = 'CPAN::PackageDetails::Entries';
my $method = 'add_entry';

use_ok( $class );
can_ok( $class, $method );

my $entries = $class->new;
isa_ok( $entries, $class );

{
my $bad_package = 'This is messed up';

my $rc = eval {
	$entries->add_entry(
		package_name => $bad_package,
		version      => 1.22,
		path         => 'a/b/c.tgz',
		);
	};
my $at = $@;

ok( ! defined $rc, "Carped for suspicious package name [$bad_package] " );
like( $at, qr/suspicious/, "Error message notes that [$bad_package] is suspicious" );
}

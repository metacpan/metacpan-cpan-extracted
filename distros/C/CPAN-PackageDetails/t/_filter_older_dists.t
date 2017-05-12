#!perl
use strict;
use warnings;

use Test::More 'no_plan';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class  = 'CPAN::PackageDetails';
my $method = '_filter_older_dists';

use_ok( $class );
can_ok( $class, $method );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# try it with relative paths and no older dists
{
my @list = qw( 
	Foo-1.23.tgz 
	Foo-Bar-3.45.tgz 
	Bar-2.34.tgz 
	);

my @copy = @list;

$class->$method( \@copy );
is_deeply( \@copy, \@list, "Unique list has the same elements it started with" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with relative paths and and an older dist
{
my @list = qw( 
	Foo-1.23.tgz
	Foo-1.22.tgz
	Foo-Bar-3.45.tgz 
	Bar-2.34.tgz 
	);

my @expected = qw( 
	Foo-1.23.tgz
	Foo-Bar-3.45.tgz 
	Bar-2.34.tgz 
	);

$class->$method( \@list );
is( scalar @list, scalar @expected, "Filtered list of filenames has the right length" );
is_deeply( \@list, \@expected, "Filtered list of filenames paths has right paths" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it with absolute paths and and an older dist
# The older dist comes first in the list
{
my @list = qw( 
	/a/b/c/d/authors/id/B/BDFOY/Test-Data-1.21.tgz
	/a/b/c/d/authors/id/B/BDFOY/Test-Data-1.22.tgz
	);

my @expected = qw( 
	/a/b/c/d/authors/id/B/BDFOY/Test-Data-1.22.tgz
	);

$class->$method( \@list );
is( scalar @list, scalar @expected, "Filtered list of absolute paths has the right length" );
is_deeply( \@list, \@expected, "Filtered list of absolute paths has right paths" );
}

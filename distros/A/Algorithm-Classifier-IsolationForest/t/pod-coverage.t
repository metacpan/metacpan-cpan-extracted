#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
	if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
	if $@;

# Symbols that live in a package's symbol table but are not part of any
# public interface, so there is nothing for a user to read about them:
#
#   - ALL_CAPS :: `use constant` values -- compile-time implementation
#     detail (MAGIC, HEADER_LEN, MAX_INBUF, EULER, ...)
#   - *_xs :: the Inline::C / XS entry points, documented as a group in
#     the NATIVE ACCELERATION section and never called by user code
#   - bootstrap :: installed by XSLoader when the prebuilt object loads
all_pod_coverage_ok(
	{
		also_private => [ qr/\A[A-Z][A-Z0-9_]*\z/, qr/_xs\z/, qr/\Abootstrap\z/, ],
	},
	'POD coverage'
);

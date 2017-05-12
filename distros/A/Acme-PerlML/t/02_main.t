#!/usr/bin/perl -w

# Unit Testing for Acme::PerlML

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 4;
use Acme::PerlML ();

my $code = <<'END_CODE';
print "Hello World";
END_CODE

# Convert to XML
my $XML = Acme::PerlML::code2xml( $code );
ok( $XML, 'Converted to XML' );
is( "$XML\n", <<'END_XML', 'XML matches expected' );
<document><statement><token_word>print</token_word><token_whitespace> </token_whitespace><token_quote_double>&quot;Hello World&quot;</token_quote_double><token_structure>;</token_structure></statement><token_whitespace>
</token_whitespace></document>
END_XML

my $code2 = Acme::PerlML::xml2code( $XML );
ok( $code2, 'Converted back to code' );
is( $code2, $code, 'Code is the same as the original' );

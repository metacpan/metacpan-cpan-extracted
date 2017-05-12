#!perl

use Test::More tests => 7;
use strict;

BEGIN {
	use_ok( 'Data::Validate::XSD' );
}

# ====================== PERLIAN ==================== #

my $definition = 'data/definition1.pl';
my $data       = [ 'data/file1.pl', 'data/file2.pl' ];

my $validator = Data::Validate::XSD->newFromFile( $definition );

ok( ref($validator) eq 'Data::Validate::XSD', 'Validator Object' );

my $even;
foreach my $filename (@{$data}) {
	my $errors = $validator->validateFile( $filename );
	# test booliean
	if($even) {
		ok( ref($errors), 'Errors Total' );
	} else {
		ok( not($errors), 'Passes Total' );
	}
	$even = not $even;
}

# ======================== XML ====================== #

$definition = 'data/definition1.xsd';
$data       = [ 'data/file1.xml', 'data/file2.xml' ];

$validator = Data::Validate::XSD->newFromFile( $definition );

ok( ref($validator) eq 'Data::Validate::XSD', 'Validator Object' );

$even = 0;
foreach my $filename (@{$data}) {
  my $errors = $validator->validateFile( $filename );
  # test booliean
  if($even) {
    ok( ref($errors), 'Errors Total' );
  } else {
    ok( not($errors), 'Passes Total' );
  }
  $even = not $even;
}

1;

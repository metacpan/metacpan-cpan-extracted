package Test2::Licensecheck;

my $CLASS = __PACKAGE__;

use strict;
use warnings;

use Test2::API qw(context);
use Test2::Todo;
use Test2::Compare qw(compare relaxed_convert strict_convert);

use File::Basename;
use App::Licensecheck;

use base 'Exporter';
our @EXPORT = qw(license_is license_like);

my $app = App::Licensecheck->new( shortname_scheme => 'debian,spdx' );
$app->lines(0);

sub license_is ($$)
{
	my ( $corpus, $exp ) = @_;

	my $ctx = context();

	my ( $failures, $exp_license, $exp_license_todo, $exp_copyright );

	# exp is either scalar, or array of current+todo
	if ( ref($exp) eq 'ARRAY' ) {
		( $exp_license, $exp_license_todo ) = @{$exp};
	}
	else {
		$exp_license = $exp;
	}

	# corpus is either scalar (file), or array (list of files)
	for ( ref($corpus) eq 'ARRAY' ? @{$corpus} : $corpus ) {
		my ( $got_license, $got_copyright ) = $app->parse($_);

		my $pat = 'detect %s "%s" for ' . basename($_);

		if ($exp_license) {
			my $name = sprintf( $pat, 'licensing', $exp_license );

			my $delta = compare(
				$got_license, $exp_license,
				\&strict_convert
			);
			if ($delta) {
				$ctx->fail( $name, $delta->diag );
				$failures++;
			}
			else {
				$ctx->ok( 1, $name );
			}
		}

		if ($exp_license_todo) {
			my $todo = Test2::Todo->new( reason => 'Fix later' );

			my $name = sprintf( $pat, 'licensing', $exp_license_todo );

			my $delta = compare(
				$got_license, $exp_license_todo,
				\&strict_convert
			);
			if ($delta) {
				$ctx->fail( $name, $delta->diag );
				$failures++;
			}
			else {
				$ctx->ok( 1, $name );
			}

			$todo->end;
		}

		if ($exp_copyright) {
			my $name = sprintf( $pat, 'copyright', $exp_copyright );

			my $delta = compare(
				$got_copyright, $exp_copyright,
				\&strict_convert
			);
			if ($delta) {
				$ctx->fail( $name, $delta->diag );
				$failures++;
			}
			else {
				$ctx->ok( 1, $name );
			}
		}
	}
	$ctx->release;
	return $failures ? 1 : 0;
}

sub license_like ($$)
{
	my ( $corpus, $exp ) = @_;

	my $ctx = context();

	my $pat = 'detect %s "%s" for ' . basename($corpus);

	my $failures;

	# exp is either regexp, or array of regexp
	for ( ref($exp) eq 'ARRAY' ? @{$exp} : $exp ) {
		my ($got) = $app->parse($corpus);

		my $name = sprintf( $pat, 'licensing', $_ );

		my $delta = compare( $got, $_, \&relaxed_convert );
		if ($delta) {
			$ctx->fail( $name, $delta->diag );
			$failures++;
		}
		else {
			$ctx->ok( 1, $name );
		}
	}

	$ctx->release;
	return $failures ? 1 : 0;
}

1;

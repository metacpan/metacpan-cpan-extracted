package Test::Licensecheck;

my $CLASS = __PACKAGE__;

use parent qw(Test::Builder::Module);
@EXPORT = qw(license_is license_like done_testing);

use strict;
use warnings;

use File::Basename;
use App::Licensecheck;

# test corpus data
my $app = App::Licensecheck->new;
$app->lines(0);
$app->deb_fmt(1);

sub license_is ($$)
{
	my ( $corpus, $expected ) = @_;
	my $tb = $CLASS->builder;
	my ( $expected_license, $expected_license_todo );
	my $expected_copyright;

	# expected is either scalar, or array of current+todo
	if ( ref($expected) eq 'ARRAY' ) {
		( $expected_license, $expected_license_todo ) = @{$expected};
	}
	else {
		$expected_license = $expected;
	}

	# corpus is either scalar (file), or array (list of files)
	for ( ref($corpus) eq 'ARRAY' ? @{$corpus} : $corpus ) {
		my ( $detected_license, $detected_copyright ) = $app->parse($_);

		$tb->is_eq(
			$detected_license, $expected_license,
			"detect licensing \"$expected_license\" for " . basename($_)
		) if ($expected_license);

		if ($expected_license_todo) {
			$tb->todo_start;
			$tb->is_eq(
				$detected_license, $expected_license_todo,
				"detect licensing \"$expected_license_todo\" for "
					. basename($_)
			);
			$tb->todo_end;
		}

		$tb->is_eq(
			$detected_copyright, $expected_copyright,
			"detect copyright \"$expected_copyright\" for " . basename($_)
		) if ($expected_copyright);
	}
}

sub license_like ($$)
{
	my ( $corpus, $expected ) = @_;
	my $tb = $CLASS->builder;

	# expected is either regexp, or array of regexp
	for ( ref($expected) eq 'ARRAY' ? @{$expected} : $expected ) {
		my ($detected) = $app->parse($corpus);

		$tb->like(
			$detected, $_,
			"detect licensing \"$_\" for " . basename($corpus)
		);
	}
}

sub done_testing ()
{
	my $tb = $CLASS->builder;

	$tb->done_testing;
}

1;

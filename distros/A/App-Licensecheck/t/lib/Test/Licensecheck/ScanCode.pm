package Test::Licensecheck::ScanCode;

my $CLASS = __PACKAGE__;

use parent qw(Test::Licensecheck);
@EXPORT
	= qw(done_testing is_licensed_like_scancode are_licensed_like_scancode);

use strict;
use warnings;

use Test::Requires qw(
	File::BaseDir
	List::MoreUtils
	YAML::XS
);

use Path::Tiny 0.053;
use App::Licensecheck;

my $corpus = File::BaseDir::data_dirs('tests/ScanCode');

sub licenses ($)
{
	my $corpus      = shift;
	my @licensedirs = qw(
		src/licensedcode/data/licenses
		src/licensedcode/data/composites/licenses
		src/licensedcode/data/non-english/licenses
	);
	my $licenses;

	# collect license hints
	for ( map { path($corpus)->child($_)->children(qr/\.yml$/) }
		@licensedirs )
	{

		# TODO: use YAML-declared key (don't assume stem equals key)
		$licenses->{ $_->basename(qr/\.[^.]+/) } = ( YAML::XS::LoadFile($_) );
	}

	return $licenses;
}

sub expected ($$;$)
{
	my ( $file, $licenses, $overrides ) = @_;
	my $stem = $file->basename(qr/\.[^.]+/);

	return $overrides->{$stem} if ( $overrides and $overrides->{$stem} );

	my $hints = YAML::XS::LoadFile( $file->sibling("$stem.yml") );
	my $license_key
		= $licenses->{$stem}{spdx_license_key} || $licenses->{$stem}{key}
		if $licenses->{$stem};

	# explicitly distinguish our unknown-if-any from ScanCode unknown-id
	# TODO: support unclassified (i.e. detected-but-unclassified)
	$hints->{licenses} //= [ $license_key || 'UNKNOWN_OR_NONE' ];

	for ( @{ $hints->{licenses} } ) {

		# TODO: Report ScanCode bug: Wrongly cased SPDX identifier
		s/^agpl\b/AGPL/;
		s/apache\b/Apache/;
		s/^gfdl\b/GFDL/;
		s/^gpl\b/GPL/;
		s/^khronos/Khronos/;
		s/^lgpl\b/LGPL/;

		# TODO: Report ScanCode bug: Missing SPDX identifier
		s/^mit-old-style-no-advert$/NTP/;

		# TODO: Report SPDX bug: Missing versioning
		s/^Aladdin$/Aladdin-8/;

		# TODO: support (non-SPDX) ScanCode identifiers
		s/^epl\b/EPL/;
		s/^kevlin-henney/Kevlin-Henney/;
		s/^mit$/Expat/;
		s/^unicode-mappings$/Unicode-strict/;

		# TODO: support output number format normalization
		s/-PLUS$/+/i;
		s/^(?:[AL]?GPL)-[1-3]\K\.0(\+?)$/$1/i;
	}

	return $hints->{licenses};
}

# parse skipfile (one uncommented entry per line)
sub parse_skipfile ($;$)
{
	my ( $file, $testpaths ) = shift;
	my $skips;
	for ( path($file)->lines_utf8( { chomp => 1 } ) ) {
		next if /^\s*[#]/;

#		diag "skipfile entry seems bogus: $_" unless grep { /$_$/ } @{ $testpaths };
		$skips->{$_} = 1;
	}

	return $skips;
}

# test corpus data
my $app = App::Licensecheck->new;
$app->lines(0);
$app->deb_fmt(1);

sub is_licensed_like_scancode ($$;$$)
{
	my ( $file, $licenses, $skiplist, $overrides ) = @_;
	my $tb = $CLASS->builder;

	return if (/\.yml$/);

#	return if ( $skiplist and $skiplist->{ $file->basename(qr/\.[^.]+/) } );
	if ( $skiplist and $skiplist->{ $file->basename(qr/\.[^.]+/) } ) {
		$tb->todo_start;
	}

	# avoid fc() to support older Perl: SPDX probably use only ASCII
	my $expected = join ' and/or ',
		List::MoreUtils::uniq sort { lc($a) cmp lc($b) }
		map { $licenses->{$_}{spdx_license_key} || $_ }
		@{ expected( $file, $licenses, $overrides ) };

	my ( $detected, $detected_copyright ) = $app->parse($file);

	# TODO: support SPDX identifiers (not Debian)
	$detected =~ s/-clause\b/-Clause/g;

	# TODO: normalize to upstream preferred number formats
	$detected =~ s/\b(?:[AL]?GPL)-\d\K\.0(?![.\d])//g;
	$detected =~ s/\b(?:Apache|BSL|MPL)-\d(?!\.)\K/.0/g;

	# TODO: support legal reasoning for arguably too vague licensing
	# https://github.com/nexB/scancode-toolkit/issues/668
	$detected =~ s/\b(?:GFDL)\K(?!-)/-1.1+/g;
	$detected =~ s/\b(?:GPL)\K(?!-)/-1+/g;
	$detected =~ s/\b(?:LGPL)\K(?!-)/-2+/g;
	$detected =~ s/\b(?:MPL)\K(?!-)/-1.0+/g;

	# TODO: rename to UNKNOWN_OR_NONE
	# TODO: support NONE (i.e. certainly no license)
	$detected =~ s/^UNKNOWN\K$/_OR_NONE/g;

	$tb->is_eq(
		$detected, $expected,
		"detect licensing \"$expected\" for " . $file->basename
	);
	if ( $tb->in_todo ) {
		$tb->todo_end;
	}
}

sub are_licensed_like_scancode ($;$$)
{
	my ( $testpaths, $skipfile, $overrides ) = @_;
	my $tb = $CLASS->builder;

	$tb->skip_all('corpus missing from $ENV{XDG_DATA_DIRS} + tests/ScanCode/')
		unless $corpus;

	my $licenses = licenses($corpus);

	#note explain $licenses;

	my $skiplist = parse_skipfile( $skipfile, $testpaths );

	for (
		sort { lc($a) cmp lc($b) }
		map  { path($corpus)->child($_)->children } @{$testpaths}
		)
	{
		is_licensed_like_scancode( $_, $licenses, $skiplist, $overrides );
	}
}

sub done_testing
{
	my $tb = $CLASS->builder;
	$tb->done_testing;
}

1;

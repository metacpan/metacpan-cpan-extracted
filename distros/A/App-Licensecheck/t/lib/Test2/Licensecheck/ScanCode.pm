package Test2::Licensecheck::ScanCode;

my $CLASS = __PACKAGE__;

use strict;
use warnings;

use Test2::API qw(context);
use Test2::Todo;
use Test2::Compare qw(compare strict_convert);

use Test2::Require::Module qw(YAML::XS);
use Test2::Require::TestCorpus qw(ScanCode);

use Test2::Licensecheck;

use Path::Tiny 0.053;
use App::Licensecheck;
use List::SomeUtils qw(uniq);

use base qw(Exporter);
our @EXPORT = qw(are_licensed_like_scancode);

my $corpus = File::BaseDir::data_dirs('tests/ScanCode');

my $app = App::Licensecheck->new( shortname_scheme => 'debian,spdx' );
$app->lines(0);

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

		# TODO: support (non-SPDX) ScanCode identifiers
		s/^epl\b/EPL/;
		s/^kevlin-henney/Kevlin-Henney/;
		s/^mit$/Expat/;
		s/^unicode-mappings$/Unicode-strict/;
		s/^w3c-software-20021231$/W3C-20021231/;

		# TODO: support output number format normalization
		s/-PLUS$/+/i;
		s/^(?:[AL]?GPL)-[1-3]\K\.0(\+?)$/$1/i;
	}

	return $hints->{licenses};
}

# parse skipfile:
# * first word is the target item
# * "todo" as second word flags item as todo
# * "skip" as second word skips item
# * remaining uncommented words is a "fix", replacing expected expression
# * trailing comment is used as reason for todo or skip, or as note for fix
sub parse_skipfile ($;$)
{
	my ( $file, $testpaths ) = shift;
	my $skips;
	foreach ( path($file)->lines_utf8( { chomp => 1 } ) ) {
		next unless $_;    # blank line

		my ( $text, $comment ) = split /\s*#\s*/;
		next unless ($text);    # comment-only line

		@_ = split ' ', $text;
		next unless (@_);       # virtually empty line

		my $target = shift;
		unless (@_) {
			$skips->{$target} = $comment ? [ '', '', '', $comment ] : 1;
			next;
		}

		my ( $fix, $pending, $skip );

		$pending = ( $_[0] eq 'todo' );
		$skip    = ( $_[0] eq 'skip' );
		shift if ( $pending or $skip );
		$fix = @_ ? join ' ', @_ : '';
		$skips->{$target} = [ $pending, $skip, $fix, $comment ];
	}

	return $skips;
}

sub are_licensed_like_scancode ($;$$)
{
	my ( $testpaths, $skipfile, $overrides ) = @_;

	my $ctx = context();

	my $licenses = licenses($corpus);

	my $skiplist = parse_skipfile( $skipfile, $testpaths );

	my $failures;

	foreach my $file (
		sort { lc($a) cmp lc($b) }
		map  { path($corpus)->child($_)->children } @{$testpaths}
		)
	{

		next if ( $file =~ /\.yml$/ );

		my $pat = 'detect %s "%s" for ' . $file->basename;

		my ( $skipdata, $fix, $pending, $skip, $note );

		if ($skiplist) {
			$skipdata = $skiplist->{ $file->basename(qr/\.[^.]+/) };
			if ($skipdata) {
				$pending = 1;
				( $pending, $skip, $fix, $note ) = @{$skipdata}
					if ( ref($skipdata) eq 'ARRAY' );
			}
		}

		my $reason = $note || 'Fix later';

		if ($skip) {
			$ctx->skip( $file->basename, $reason );
			next;
		}

		my $todo = Test2::Todo->new( reason => $reason )
			if ($pending);

		# avoid fc() to support older Perl: SPDX probably use only ASCII
		my $exp = join ' and/or ',
			uniq sort { lc($a) cmp lc($b) }
			map       { $licenses->{$_}{spdx_license_key} || $_ }
			@{ expected( $file, $licenses, $overrides ) };

		my ( $got, $got_copyright ) = $app->parse($file);

		# TODO: Report SPDX bug: Missing versioning
		$got =~ s/Aladdin\K-8//g;

		# TODO: support SPDX identifiers (not Debian)
		$got =~ s/-clause\b/-Clause/g;

		# TODO: normalize to upstream preferred number formats
		$got =~ s/\b(?:[AL]?GPL)-\d\K\.0(?![.\d])//g;
		$got =~ s/\b(?:Apache|BSL|MPL)-\d(?!\.)\K/.0/g;

		# TODO: support legal reasoning for arguably too vague licensing
		# https://github.com/nexB/scancode-toolkit/issues/668
		$got =~ s/\b(?:GFDL)\K(?!-)/-1.1+/g;
		$got =~ s/\b(?:GPL)\K(?!-)/-1+/g;
		$got =~ s/\b(?:LGPL)\K(?!-)/-2+/g;
		$got =~ s/\b(?:MPL)\K(?!-)/-1.0+/g;

		# TODO: rename to UNKNOWN_OR_NONE
		# TODO: support NONE (i.e. certainly no license)
		$got =~ s/^UNKNOWN\K$/_OR_NONE/g;

		my $name = sprintf( $pat, 'licensing', $fix ? "$fix ($exp)" : $exp );

		my $delta = compare( $got, $fix || $exp, \&strict_convert );
		if ($delta) {
			$ctx->fail( $name, $delta->diag );
			$failures++;
		}
		else {
			$ctx->ok( 1, $name );
		}

		$todo->end
			if ($todo);
	}

	$ctx->release;
	return $failures ? 1 : 0;
}

1;

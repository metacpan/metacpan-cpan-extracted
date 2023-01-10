use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use App::Licensecheck;
use Path::Tiny;

# undetected or misdetected
# TODO: add/update patterns in Regexp::Pattern::License
my %broken = (
	'MIT-Cheusov'                     => 'UNKNOWN',
	'MIT-Minimal'                     => 'UNKNOWN',
	'MIT-Bellcore'                    => 'UNKNOWN',
	'MIT-Old-Style'                   => 'MIT-Open-Group and/or NTP',
	'MIT-Old-Style-disclaimer-no-doc' => 'UNKNOWN',
	'Unicode'                         => 'UNKNOWN',    # unicode_dfs_2005
	'MIT-UnixCrypt-Variant'           => 'UNKNOWN',
);

plan 33 + %broken;

# weakly labeled
# TODO: add Fedora names in Regexp::Pattern::License
my %imperfect = (
	'Adobe-Glyph'           => 'MIT-Adobe-Glyph-List',
	Boost                   => 'MIT-Thrift',
	bdwgc                   => 'MIT-Another-Minimal',
	'DSDP'                  => 'MIT-PetSC',
	'Festival'              => 'MIT-Festival',
	ICU                     => 'MIT-ICU',
	libtiff                 => 'MIT-Hylafax',
	mit_epinions            => 'MIT-Epinions',
	mit_mpich2              => 'MIT-mpich2',
	mit_new                 => 'MIT-sublicense',
	mit_old                 => 'MIT-Modern',
	mit_oldstyle_disclaimer => 'MIT-Old-Style-disclaimer',
	mit_oldstyle            => 'MIT-Old-Style',
	mit_openvision          => 'MIT-OpenVision',
	mit_osf                 => 'MIT-HP',
	mit_unixcrypt           => 'MIT-UnixCrypt',
	mit_whatever            => 'MIT-Whatever',
	mit_widget              => 'MIT-Nuclear',
	mit_xfig                => 'MIT-Xfig',
	mpich2                  => 'MIT-mpich2',
	ntp_disclaimer          => 'MIT-Old-Style-disclaimer-no-ad',
	NTP                     => 'MIT-Old-Style-no-ad',
	SMLNJ                   => 'MIT-Mlton',
	WordNet                 => 'MIT-WordNet',
);

my @opts = (
	schemes   => [qw(fedora)],
	top_lines => 0,
);

sub scanner
{
	my $expected = $_->basename('.txt');

	return if $expected eq $_->basename;

	my ($license) = App::Licensecheck->new(@opts)->parse($_);
	my $todo;

	if ( exists $broken{$expected} ) {
		like $imperfect{$license} || $license,
			qr/^\Q$expected\E|\Q$broken{$expected}\E$/,
			"Corpus file $_";
		$todo = todo 'not yet implemented';
	}
	is( $imperfect{$license} || $license, $expected,
		"Corpus file $_"
	);
}

path("t/fedora")->visit( \&scanner );

done_testing;

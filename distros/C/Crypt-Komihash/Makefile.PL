use ExtUtils::MakeMaker;
use Config;

#my $is_64bit = ($Config{use64bitint} || $Config{use64bitall});
my $is_64bit  = $Config{uvsize} >= 8;

# Cannot build if we don't have 64bit UVs
if (!$is_64bit) {
	die "This module requires a 64-bit platform.\n";
}

WriteMakefile(
	NAME             => 'Crypt::Komihash',
	VERSION_FROM     => 'lib/Crypt/Komihash.pm',
    ABSTRACT         => 'Komihash implementation in Perl',
	XSMULTI          => 1,
	AUTHOR           => 'Scott Baker <bakerscot@cpan.org>',
	LICENSE          => 'mit',
	MIN_PERL_VERSION => '5.016',
	LIBS             => [''],                   # e.g., '-lm'
    DEFINE           => '',                     # e.g., '-DHAVE_SOMETHING'
    INC              => '-Ilib',                # path to 'Crypt/Komihash.h'

	PREREQ_PM          => { 'ExtUtils::MakeMaker' => '7.12', },
	CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '7.12', },
	TEST_REQUIRES      => { 'Test::More' => '0', },

	META_MERGE => {
		dynamic_config => 1,
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				url => 'https://github.com/scottchiefbaker/perl-Crypt-Komihash.git',
				web => 'https://github.com/scottchiefbaker/perl-Crypt-Komihash',
				type => 'git'
			},
			bugtracker => {
				"web" => "https://github.com/scottchiefbaker/perl-Crypt-Komihash/issues"
			},
		}
	},

);

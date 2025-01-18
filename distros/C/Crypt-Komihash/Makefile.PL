use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Crypt::Komihash',
	VERSION_FROM     => 'lib/Crypt/Komihash.pm',
    ABSTRACT         => 'Komihash implementation in Perl',
	XSMULTI          => 1,
	AUTHOR           => 'Scott Baker <bakerscot@cpan.org>',
	LICENSE          => 'mit',
	MIN_PERL_VERSION => '5.012',
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
				url => 'https://github.com/scottchiefbaker/perl-Random-Simple.git',
				web => 'https://github.com/scottchiefbaker/perl-Random-Simple',
				type => 'git'
			},
			bugtracker => {
				"web" => "https://github.com/scottchiefbaker/perl-Random-Simple/issues"
			},
		}
	},

);

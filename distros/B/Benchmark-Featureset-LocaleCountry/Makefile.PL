use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
	AUTHOR   => 'Ron Savage (ron@savage.net.au)',
	ABSTRACT => 'Compare Locale::Codes, Locale::Country::Multilingual, WWW::Scraper::Wikipedia::ISO3166, etc',
	) : (),
	clean =>
	{
	FILES => 'blib/* Makefile MANIFEST Benchmark-Featureset-LocaleCountry-*'
	},
	dist =>
	{
	COMPRESS => 'gzip',
	SUFFIX   => 'gz'
	},
	DISTNAME  => 'Benchmark-Featureset-LocaleCountry',
	NAME      => 'Benchmark::Featureset::LocaleCountry',
# Next line runs copy.config.pl when user runs 'make'.
# Warning: '...' => 0 is OK but => '' or undef are ignored.
	PL_FILES  => {'scripts/copy.config.pl' => 'Copying...'},
	PREREQ_PM =>
	{
	Config::Tiny                               => 2.13,
	Date::Simple                               => 3.03,
	File::Copy                                 => 2.18,
	File::HomeDir                              => 0.97,
	Hash::FieldHash                            => 0.10,
	Locale::Country                            => 3.16,
	Locale::Country::Multilingual              => 0.23,
	Locale::Geocode                            => 1.2,
	Locale::Object                             => 0.78,
	Locale::Object::DB                         => 0.78,
	Locale::SubCountry                         => 1.46,
	Path::Class                                => 0.23,
	Set::Array                                 => 0.22,
	strict                                     => 1.04,
	Test::More                                 => 0.94,
	Test::Pod                                  => 1.44,
	Text::Xslate                               => 1.0007,
	warnings                                   => 1.12,
	WWW::Scraper::Wikipedia::ISO3166::Database => 1.01,
	},
	VERSION_FROM => 'lib/Benchmark/Featureset/LocaleCountry.pm',
);

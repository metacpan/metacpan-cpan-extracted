use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Basic shopping cart',
    ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST Business-Cart-Generic-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'Business-Cart-Generic',
 NAME      => 'Business::Cart::Generic',
# Next line runs copy.config.pl when user runs 'make'.
# Warning: '...' => 0 is OK but => '' or undef are ignored.
 PL_FILES   => {'scripts/copy.config.pl' => 'Copying...'},
 META_MERGE =>
 {
	 no_index =>
	 {
		 directory => [qw{lib/Business/Cart/Generic/Schema/}],
		 file      => [qw{lib/Business/Cart/Generic/Schema.pm}],
	 },
 },
 PREREQ_PM =>
 {
	Brannigan                                  => 0.8,
	CGI::Untaint                               => 1.26,
 	CGI                                        => 3.52,
 	CGI::Application                           => 4.31,
 	Config::Tiny                               => 2.13,
 	Data::Session                              => 1.03,
 	DBIx::Admin::CreateTable                   => 2.07,
 	DBIx::Class                                => 0.08121,
 	DBIx::Class::Schema::Loader                => 0.06001,
 	DBIx::Connector                            => 0.42,
	File::Copy                                 => 2.18,
 	File::HomeDir                              => 0.97,
	FindBin                                    => 1.50,
	IO::File                                   => 1.14,
 	JSON::XS                                   => 2.3,
 	Log::Handler::Output::DBI                  => 0.11,
 	Moose                                      => 0.98,
 	namespace::autoclean                       => 0.09,
 	parent                                     => 0.224,
 	Path::Class                                => 0.23,
	Perl6::Slurp                               => 0.03,
	Try::Tiny                                  => 0.09,
	Test::More                                 => 0.94,
	Test::Pod                                  => 1.44,
	Text::CSV_XS                               => 0.80,
 	Text::Xslate                               => 1.0007,
	WWW::Scraper::Wikipedia::ISO3166::Database => 1.01,
 },
 VERSION_FROM => 'lib/Business/Cart/Generic.pm',
);

use lib 'inc';
use ExtUtils::MakeMaker;
use Inline::Module;

WriteMakefile(
	NAME			=> 'CDS',
	VERSION_FROM	=> 'lib/CDS.pm',
	PREREQ_PM		=> {
						'Carp::Always' => 0,
						'Cwd' => 0,
						'Digest::SHA' => 0,
						'Encode' => 0,
						'Fcntl' => 0,
						'HTTP::Date' => 0,
						'HTTP::Headers' => 0,
						'HTTP::Request' => 0,
						'HTTP::Server::Simple::CGI' => 0,
						'Inline' => 0,
						'LWP::UserAgent' => 0,
						'Sys::Hostname' => 0,
						'Term::ANSIColor' => 0,
						'Term::ReadLine' => 0,
						'Time::Local' => 0,
						},
	ABSTRACT		=> 'Condensation Data System (condensation.io), support for folder and HTTP stores, command line interface',
	AUTHOR			=> 'Thomas Lochmatter <thomas.lochmatter@viereck.ch>',
	LICENSE			=> 'mit',
	EXE_FILES		=> ['scripts/cds'],
	postamble		=> {
						inline => {
							module => 'CDS::C',
							stub => 'CDS::C::Inline',
							ilsm => 'Inline::C',
							},
						},
	);

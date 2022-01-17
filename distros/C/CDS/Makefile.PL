use 5.010000;
use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> 'Condensation',
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
	ABSTRACT		=> 'Condensation library for Perl with support for folder and HTTP stores, and a command line interface.',
	AUTHOR			=> 'Thomas Lochmatter <thomas.lochmatter@viereck.ch>',
	LICENSE			=> 'mit',
	EXE_FILES		=> ['scripts/cds'],
);

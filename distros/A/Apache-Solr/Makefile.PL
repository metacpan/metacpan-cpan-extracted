use warnings;
use strict;
use 5.16.1;

use ExtUtils::MakeMaker;

# Use command 'oodist' to produce your whole software release.

my $version  = '1.12';
my $git      = "https://github.com/markov2/perl5-Apache-Solr";
my $publish  = "../public_html/apache-solr";
my $homepage = "https://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.06,
	first_year    => 2012,
	email         => 'mark\@overmeer.net',

	include  => [
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
			'WebService::Solr::Query',
			'WebService::Solr',
		],
		pmhead         => undef,
	},

	tests    => {
	},

	release  => {
		publish        => "$publish/source",
	},

	raw      => {
		publish        => "$publish/raw",
	},

	generate => [ {
		# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	}, ],
);

my %requires = (
	'Data::Dumper'        => 0,
	'Encode'              => 0,
	'HTTP::Request'       => 0,
	'JSON'                => 0,
	'Log::Report'         => 0,
	'LWP::UserAgent'      => 0,
	'Scalar::Util'        => 0,
	'Test::More'          => 0,
	'Time::HiRes'         => 0,
	'URI'                 => 0,
	'XML::LibXML::Simple' => 0,
	'MIME::Types'         => 0,
);

WriteMakefile
	NAME        => 'Apache::Solr',
	VERSION     => $version,
	AUTHOR      => 'Mark Overmeer',
	ABSTRACT    => 'Client for the Solr database',
	LICENSE     => 'perl_5',

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => "$git.git",
				web  => $git,
			},
			bugtracker => {
				web  => "$git/issues",
			},
			homepage => $homepage,
			license  => [ 'https://dev.perl.org/licenses/' ],
		},
		prereqs => {
			runtime => {
				requires   => \%requires,
				recommends => {},
				suggests   => {},
			},
			develop => {
				requires => {
					'OODoc' => '3.00',
				},
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				},
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/apache-solr/raw
DISTDIR         = ../public_html/apache-solr/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2012
EMAIL           = markov@cpan.org
WEBSITE         = https://perl.overmeer.net/CPAN/
__POSTAMBLE


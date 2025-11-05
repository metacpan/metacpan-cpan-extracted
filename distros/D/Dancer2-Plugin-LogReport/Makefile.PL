use ExtUtils::MakeMaker;

use 5.016;
use warnings;
use strict;

# Use command 'oodist' to produce your whole software release.
my $version  = '2.00';
my $webpages = "../public_html";
my $git      = "https://github.com/markov2/perl5-Dancer2-Plugin-LogReport";
my $publish  = "../public_html/dancer2-plugin-logreport";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.04,
	first_year    => 2015,
	email         => "markov\@cpan.org",

	include  => [
		'../Log-Report',
	],

	use      => [
	],

	parser   => {
		syntax         => 'markov',
		skip_links     => [
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

	generate => [
	  {
		# Add real pod to the releases
		format         => 'pod3',
		podtail        => undef,
	  },
	],
);

my %prereq  = (
	'Dancer2'          => '0.207',
	'Log::Report'      => '1.42',
	'Scalar::Util'     => 0,
);

#use Data::Dumper;
#warn Dumper \%prereq;

WriteMakefile
	NAME      => 'Dancer2::Plugin::LogReport',
	VERSION   => $version,
	PREREQ_PM => \%prereq,

	AUTHOR    => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT  => 'logging, exceptions and translations in Dancer2 via Log::Report',
	LICENSE   => 'perl_5',

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => "$git.git",
				web  => $git,
			},
			homepage => $homepage,
			license  => [ 'http//dev.perl.org/licenses/' ],
		},
		prereqs => {
			develop => {
				requires => {
					'OODoc' => '3.04',
				}
			},
			test => {
				requires => {
					'Test::More' => 1.00,
					'Test::Pod'  => 1.00,
				}
			},
		},

		# You may use multiple set-ups, see "oodist --make"
		x_oodist => \%oodist,
	};

# for translation tables
#linkext::
#	../Log-Report-Lexicon/bin/xgettext-perl --mode=VERBOSE -p lib/Log/Report/messages lib

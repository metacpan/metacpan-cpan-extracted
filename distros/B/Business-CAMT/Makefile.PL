# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

use strict;
use warnings;
use utf8;
use 5.020;

use ExtUtils::MakeMaker;

# Use command 'oodist' to produce your whole software release.
my $git      = "https://github.com/markov2/perl5-Business-CAMT";
my $publish  = "../public_html/business-camt";
my $homepage = "http://perl.overmeer.net/CPAN/";

my %oodist   = (
	oodoc_version => 3.05,
	first_year    => 2024,
	email    => "markov\@cpan.org",

	include  => [
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
		format         => 'pod3',
		podtail        => undef,
	  },
	],
);

WriteMakefile
    NAME             => 'Business::CAMT',
    VERSION          => '0.14',
    AUTHOR           => 'Mark Overmeer <markov@cpan.org>',
	ABSTRACT         => 'ISO20022 Cash Management (CAMT) messages',
	LICENSE          => 'perl_5',

    PREREQ_PM        => {
		'Data::Dumper'   => 0,
		'Getopt::Long'   => 0,
		'JSON'           => 0,
		'List::Util'     => 0,
        'Log::Report'    => 1.32,
		'Path::Class'    => 0,
        'Scalar::Util'   => 0,
        'XML::Compile'   => 1.64,
        'XML::Compile::Cache' => 1.06,
        'XML::LibXML'    => 2.0207,
    },
	EXE_FILES        => [ qw(bin/camt) ],

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
					'OODoc' => '3.00',
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

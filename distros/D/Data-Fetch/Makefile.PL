#!/usr/bin/env perl

use strict;
use warnings;

no lib '.';

use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use Config;

unless($Config{usethreads}) {
	print STDERR "NA: Perl not compiled with thread support\n";
	exit(0);
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME		=> 'Data::Fetch',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Data/Fetch.pm',
    ABSTRACT_FROM       => 'lib/Data/Fetch.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
	'Test::Warn' => 0,
	'Test::CleanNamespaces' => 0,
	# 'Test::Kwalitee' => 0,
    }, PREREQ_PM => {
	'Scalar::Util' => 0,
	'threads' => 0,
    }, dist => $dist,
    clean		=> { FILES => 'Data-Fetch-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
		repository => {
			type => 'git',
			# repository => 'https://github.com/nigelhorne/Data-Fetch',
			url => 'git://github.com/nigelhorne/Data-Fetch.git',
			web => 'https://github.com/nigelhorne/Data-Fetch',
		}, bugtracker => {
			# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Fetch',
			web => 'https://github.com/nigelhorne/Data-Fetch/issues',
			url => 'https://github.com/nigelhorne/Data-Fetch/issues',
			mailto => 'bug-Data-Fetch@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.12.0'	# Get decent thread support
    # MIN_PERL_VERSION	=> '5.6.2'
);

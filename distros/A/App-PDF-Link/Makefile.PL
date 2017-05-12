#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

require 5.010;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $master = 'lib/App/PDF/Link.pm';
my $version = MM->parse_version($master);

WriteMakefile(
 NAME           => 'App::PDF::Link',
 ABSTRACT       => 'Utility to insert file links into PDF documents',
 VERSION	=> "$version",
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',

 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ 'script/pdflink' ],
 PL_FILES	=> {
		    'script/pp.PL' => [ 'script/pdflink' ]
		   },

 PREREQ_PM      => {
		    'PDF::API2'    => 2.029,
		    'Text::CSV_XS' => 0,
		   },
 BUILD_REQUIRES  => {
		    'Test::More'   => 1.001014,
		   },

 MIN_PERL_VERSION => '5.010000',
 LICENSE => 'perl',
 META_MERGE => {
     'meta-spec' => { version => 2 },
     resources        => {
	 repository   => {
	     type => 'git',
	     url  => 'git://github.com/sciurius/pdflink',
	     web  => 'https://github.com/sciurius/pdflink',
         },
     },
     provides         => {
	 pdflink => { file => "script/pdflink",
		       version => $version },
	 "App::PDF::Link"
		  => { file => "lib/App/PDF/Link.pm",
		       version => $version },
     },
     no_index         => {
         directory => [
	    "lib/App/PDF/Link",
	 ],
         namespace => [
	    "PDF::API2",
	 ],
     },
 },

);

1;

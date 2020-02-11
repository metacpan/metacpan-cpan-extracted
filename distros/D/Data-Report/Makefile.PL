#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $master = 'lib/Data/Report.pm';
my $version = MM->parse_version($master);

WriteMakefile(
 NAME                => 'Data::Report',
 AUTHOR              => 'Johan Vromans <jv@cpan.org>',
 VERSION             => $version,
 ABSTRACT_FROM       => $master,
 LICENSE             => 'perl_5',
 PL_FILES            => {},
 DIR		     => [],
 MIN_PERL_VERSION    => '5.010001',
 PREREQ_PM => {
     'ExtUtils::MakeMaker' => 6.46, # for META_MERGE, LICENSE
     'Test::More' => 0,
     'Text::CSV'  => 1.00,
 },
 TEST_REQUIRES  => {
        'Text::CSV'  => 1.00,
 },
 META_MERGE => {
   resources    => {
     repository => {
       type => 'git',
       web  => 'https://github.com/sciurius/perl-Data-Report',
       url  => 'https://github.com/sciurius/perl-Data-Report.git',
     },
     bugtracker => {
       web => "https://github.com/sciurius/perl-Data-Report/issues",
     },
   },
   'meta-spec' => {
     version => '2',
     url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
   },
   recommends => {
		  'HTML::Entities' => 0,
   },

   no_index => {
       package => [ qw(DB) ],
   },
 }
);

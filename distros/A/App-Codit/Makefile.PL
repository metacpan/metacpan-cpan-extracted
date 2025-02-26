use ExtUtils::MakeMaker;

use strict;
use warnings;

my $name = 'App::Codit';
my $pm = 'lib/App/Codit.pm';
my $git = 'App-Codit';

my %prereq = (
	'Data::Compare'       => '1.29',
	'File::Path'          => '2.18',
	'File::Spec'          => '3.75',
	'Getopt::Long'        => '2.54',
	'Test::Tk'            => '3.04',
	'Tk'                  => '804.032',
	'Tk::AppWindow'       => '0.21',
	'Tk::CodeText'        => '0.64',
	'Tk::FileBrowser'     =>	'0.09',
	'Tk::PodViewer'       =>	'0.06',
	'Tk::QuickForm'       =>	'0.09',
	'Tk::Terminal'        =>	'0.03',
);

WriteMakefile(
	NAME					=> $name,
	VERSION_FROM		=> $pm,
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> $pm,
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	EXE_FILES => ['bin/codit'],
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "git://github.com/haje61/$git.git",
				web  => "https://github.com/haje61/$git",
			},
			bugtracker => {
				web  => "https://github.com/haje61/$git/issues",
			},
		}}
	) : () ),
);
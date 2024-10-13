use ExtUtils::MakeMaker;

use strict;
my %prereq = (
	'Data::Compare'       => '1.29',
	'File::Path'          => '2.18',
	'File::Spec'          => '3.75',
	'Getopt::Long'        => '2.54',
	'Test::Tk'            => '3.04',
	'Tk'                  => '804.030',
	'Tk::AppWindow'       => '0.15',
	'Tk::CodeText'        => '0.53',
	'Tk::FileBrowser'     =>	'0.04',
	'Tk::PodViewer'       =>	'0.04',
	'Tk::Terminal'        =>	'0.03',
);

WriteMakefile(
	NAME					=> 'App::Codit',
	VERSION_FROM		=> 'lib/App/Codit.pm',
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> 'lib/App/Codit.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	EXE_FILES => ['bin/codit'],
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/App-Codit.git',
            web  => 'https://github.com/haje61/App-Codit',
         },
      }}
    ) : () ),
);
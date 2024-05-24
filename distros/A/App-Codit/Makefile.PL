use ExtUtils::MakeMaker;

use strict;
my %prereq = (
	'File::Path'          => '2.18',
	'File::Spec'          => '3.75',
	'Test::Tk'            => '3.03',
	'Tk'                  => '804.023',
	'Tk::AppWindow'       => '0.06',
	'Tk::CodeText'        => '0.50',
	'Tk::FileBrowser'     =>	'0.03'
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
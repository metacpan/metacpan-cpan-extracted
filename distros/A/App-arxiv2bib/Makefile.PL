use warnings;
use v5.20;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::arxiv2bib',
    VERSION_FROM     => 'lib/App/arxiv2bib.pm',
    ABSTRACT         => 'Extract bibliographic data from the arXiv API',
    AUTHOR           => 'stuart-little',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.20.0',
    EXE_FILES        => ['script/arxiv2bib'],
    PREREQ_PM        => {	
	'warnings' => 0,
	    'Mojolicious' => 9.19,
    },
    TEST_REQUIRES =>
    {
	'Test::Simple'	=> 1.302185,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
	'meta-spec' => { version => 2 },
	    resources => {
		repository => {
		    type => 'git',
		    url  => 'https://github.com/stuart-little/app-arxiv2bib.git',
		    web  => 'https://github.com/stuart-little/app-arxiv2bib',
		},
	}})
     : ()
    ),
    );

use 5.008004;
use ExtUtils::MakeMaker;

os_unsupported if $^O eq 'MSWin32';

WriteMakefile(
  NAME             => 'App::news',
  VERSION_FROM     => 'lib/App/news.pm',
  ABSTRACT         => 'a web front-end for a news server',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/news',
  ],
  PREREQ_PM => {
    'Mojolicious' => 0,
    'Modern::Perl' => 1.20180701, # for '2018'
    'DateTime::Format::Mail' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://alexschroeder.ch/cgit/news',
	web  => 'https://alexschroeder.ch/cgit/news/about/',
      },
    },
  },
);

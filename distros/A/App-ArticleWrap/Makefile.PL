use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::ArticleWrap',
  VERSION_FROM     => 'lib/App/ArticleWrap.pm',
  ABSTRACT_FROM    => 'lib/App/ArticleWrap.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/article-wrap',
  ],
  PREREQ_PM => {
    'Modern::Perl' => 1.20180701, # for '2018'
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.52',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://src.alexschroeder.ch/article-wrap.git',
	web  => 'https://src.alexschroeder.ch/article-wrap.git',
      },
    },
  },
);

sub MY::postamble {
  return <<'EOT';
README.md: script/article-wrap
	pod2markdown $< $@
	perl -e 'use File::Slurper qw(read_text write_text); $$_=read_text("README.md"); s/^(    .*)\n\n/$1\n```\n\n/gm; s/\n\n    </\n\n```xml\n    </g; s/\n\n    /\n\n```sh\n    /g; s/^    //gm; die $$_ if /ERROR/; write_text("README.md", $$_)'
EOT
}

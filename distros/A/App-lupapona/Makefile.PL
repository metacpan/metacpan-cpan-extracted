use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::lupapona',
  VERSION_FROM     => 'lib/App/lupapona.pm',
  ABSTRACT_FROM    => 'lib/App/lupapona.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/lupa-pona',
  ],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Mojo::IOLoop' => 0,
    'Mojo::Log' => 0,
    # this is an optional dependency for Mojo::IOLoop
    'IO::Socket::SSL' => 0,
    'File::Slurper' => 0,
    'Modern::Perl' => 0,
    'URI::Escape' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://alexschroeder.ch/cgit/lupa-pona',
	web  => 'https://alexschroeder.ch/cgit/lupa-pona/about/',
      },
    },
  },
  clean => {
    FILES => "test target",
  },
);

sub MY::postamble {
  return <<'MOKU_PONA_TARGETS';
# Update the README file. The Perl script no only converts the POD
# documentation to Markdown, it also adds a table of contents.
README.md: script/lupa-pona
	./update-readme script/lupa-pona
MOKU_PONA_TARGETS
}

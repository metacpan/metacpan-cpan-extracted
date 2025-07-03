use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::traveller',
  VERSION_FROM     => 'lib/App/traveller.pm',
  ABSTRACT_FROM    => 'lib/App/traveller.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/traveller',
  ],
  PREREQ_PM => {
    'Modern::Perl' => 1.20180701, # for '2018'
    'Mojolicious' => 9.00,       # removed tls_verify from Mojo::IOLoop::TLS 9.0
  },
  TEST_REQUIRES => {
    'Test::Memory::Cycle' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://alexschroeder.ch/cgit/traveller',
	web  => 'https://alexschroeder.ch/cgit/traveller/about/',
      },
    },
  },
  clean => {
    FILES => "test-[0-9][0-9][0-9][0-9] t/*.pem",
  },
);

sub MY::postamble {
  return <<'EOT';
run:
	morbo --mode development --listen http://*:3090 script/traveller
EOT
}

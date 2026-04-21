use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'DBIx::Wizard',
  VERSION_FROM  => 'lib/DBIx/Wizard.pm',
  ABSTRACT_FROM => 'lib/DBIx/Wizard.pod',
  AUTHOR        => 'Thomas Busch <tbusch@cpan.org>',
  LICENSE       => 'MIT',
  MIN_PERL_VERSION => '5.10.0',
  PREREQ_PM     => {
    'DBI'          => 0,
    'SQL::Wizard'  => '0.11',
    'Time::Moment'  => '0.44',
  },
  TEST_REQUIRES => {
    'Test::More'   => 0,
    'DBD::SQLite'  => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    x_authority => 'cpan:TBUSCH',
    keywords => [qw(
      dbi database query builder executor zero-configuration orm
      sql fluent lightweight chaining chainable resultset cursor 
      select insert update delete truncate
      join expression composable
      postgresql mysql sqlite
    )],
    resources => {
      homepage => 'https://github.com/thomasbusch/perl-DBIx-Wizard',
      repository => {
        type => 'git',
        url  => 'https://github.com/thomasbusch/perl-DBIx-Wizard.git',
        web  => 'https://github.com/thomasbusch/perl-DBIx-Wizard',
      },
      bugtracker => {
        web => 'https://github.com/thomasbusch/perl-DBIx-Wizard/issues',
      },
    },
  },
);

sub MY::postamble {
  return <<'MAKE';
readme: lib/DBIx/Wizard.pod
	perl tools/pod2readme.pl lib/DBIx/Wizard.pod > README.md
MAKE
}


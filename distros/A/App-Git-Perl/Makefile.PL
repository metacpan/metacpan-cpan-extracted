#use 5.014;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::Git::Perl',
  VERSION_FROM     => 'script/git-perl',
  ABSTRACT_FROM    => 'lib/App/Git/Perl.pm',
  AUTHOR           => 'Nedzad Hrnjica',
  LICENSE          => 'perl',
  MIN_PERL_VERSION => '5.014',
  EXE_FILES        => ['script/git-perl'],
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type       => 'git',
        url        => 'https://github.com/nedzadhrnjica/App-Git-Perl.git',
        web        => 'https://github.com/nedzadhrnjica/App-Git-Perl',
      },
      bugtracker => {
        web        => 'https://github.com/nedzadhrnjica/App-Git-Perl/issues',
      },
    },
    provides => {
      'App::Git::Perl' => {
        file => 'lib/App/Git/Perl.pm',
        version => '0.1.12',
      }
    },
  })
  : ()
  ),
);


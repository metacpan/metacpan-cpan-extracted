use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Dancer2::Template::Obj2HTML',
  VERSION_FROM     => 'lib/Dancer2/Template/Obj2HTML.pm',
  ABSTRACT_FROM    => 'lib/Dancer2/Template/Obj2HTML.pm',
  AUTHOR           => 'Pero Moretti',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => [],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Dancer2'   => 0,
    'Moo'      => 0,
    'JSON'     => 0,
    'HTML::Obj2HTML' => 0
  },
  TEST_REQUIRES => {
    'File::Basename' => 0,
    'Path::Tiny' => 0,
    'FindBin' => 0,
    'HTTP::Request::Common' => 0,
    'JSON::MaybeXS' => 0,
    'Module::Load' => 0,
    'Plack::Test' => 0,
    'Test::More' => 0,
    'Test::Mock::LWP::Dispatch' => 0,
    'URI' => 0
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/Pero-Moretti/Perl-Dancer2-Template-Obj2HTML.git',
              web  => 'https://github.com/Pero-Moretti/Perl-Dancer2-Template-Obj2HTML',
          },
      }})
   : ()
  ),
);

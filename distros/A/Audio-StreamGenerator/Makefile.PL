use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Audio::StreamGenerator',
  VERSION_FROM     => 'lib/Audio/StreamGenerator.pm',
  ABSTRACT_FROM    => 'lib/Audio/StreamGenerator.pm',
  AUTHOR           => 'Sander Plas',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Log::Log4perl' => 0
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/Oele/audio-streamgenerator.git',
              web  => 'https://github.com/Oele/audio-streamgenerator',
          },
          bugtracker => {
              web => 'https://github.com/Oele/audio-streamgenerator/issues'
          }
      }})
   : ()
  ),
);

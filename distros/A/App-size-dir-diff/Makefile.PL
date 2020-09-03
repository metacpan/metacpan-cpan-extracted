use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::size::dir::diff',
  VERSION_FROM     => 'lib/App/size/dir/diff.pm',
  ABSTRACT_FROM    => 'lib/App/size/dir/diff.pm',
  AUTHOR           => 'Jonas Jensen',
  LICENSE          => 'GPL_2',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/size-dir-diff'],
  PREREQ_PM        => {
    'strict'       => 0,
    'warnings'     => 0,
    'File::Find'   => 0,
    'Storable'     => 0,
    'Getopt::Std'  => 0,
    'Data::Dumper' => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'git@bitbucket.org:Kasreyn/size_dir_diff.git',
              web  => 'https://bitbucket.org/Kasreyn/size_dir_diff/src',
          },
      }})
   : ()
  ),
);

use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::Utils',
  VERSION_FROM     => 'lib/App/Utils.pm',
  ABSTRACT_FROM    => 'lib/App/Utils.pm',
  AUTHOR           => 'Vlado Keselj vlado@dnlp.ca http://vlado.ca',
  LICENSE          => 'perl',
  MIN_PERL_VERSION => '5.0008004',
  EXE_FILES        => ['bin/date-tag', 'bin/date-tag-file',
    'bin/remove-empty-dirs', 'bin/save'],
  PREREQ_PM        => {
    'POSIX' => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
          url  => 'https://github.com/vkeselj/App-Utils.git',
          web  => 'https://github.com/vkeselj/App-Utils',
      },
    }})
  : ()
  ),
);

# parts of Makefile used only in the development directory
if (-f 'priv.make' ) {
    open(M, ">>Makefile") or die;
    open(I,"priv.make") or die;
    while (<I>) { print M }
    close(M); close(I);
}

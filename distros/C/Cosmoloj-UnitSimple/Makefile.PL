use 5.008004;
use ExtUtils::MakeMaker;

# ignore demo.pl
sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /demo\.pl$/; # SKIP
    return $file;
}

WriteMakefile(
  NAME             => 'Cosmoloj::UnitSimple',
  VERSION_FROM     => 'unitSimple.pm',
  ABSTRACT_FROM    => 'unitSimple.pm',
  AUTHOR           => 'Samuel Andres',
  LICENSE          => 'UnLicense',
  MIN_PERL_VERSION => '5.008004',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'DateTime' => '0.37',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/SamuelAndresPascal/cosmoloj-pl.git',
              web  => 'https://github.com/SamuelAndresPascal/cosmoloj-pl',
          },
      }})
   : ()
  ),
);
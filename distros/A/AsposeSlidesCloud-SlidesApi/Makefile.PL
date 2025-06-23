use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'AsposeSlidesCloud::SlidesApi',
  VERSION          => 25.06,
  ABSTRACT         => 'Aspose.Slides Cloud SDK',
  AUTHOR           => 'Victor Putrov',
  LICENSE          => 'MIT',
  MIN_PERL_VERSION => '5.008004',
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
   )
);

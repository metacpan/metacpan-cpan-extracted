use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypt::Lucifer',
    VERSION_FROM      => 'lib/Crypt/Lucifer.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/Lucifer.pm', # retrieve abstract from module
       AUTHOR         => 'Sadegh Ahmadzadegan <sadegh.ahm@gmail.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
if  (eval {require ExtUtils::Constant; 1}) {
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Crypt::Lucifer',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

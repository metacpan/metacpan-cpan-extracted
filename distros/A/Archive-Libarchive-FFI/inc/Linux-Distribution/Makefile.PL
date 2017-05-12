use 5.006000;
use ExtUtils::MakeMaker;
unless (lc $^O eq "linux") {
    die "OS unsupported\n";
}
WriteMakefile(
    NAME              => 'Linux::Distribution',
    VERSION_FROM      => 'lib/Linux/Distribution.pm', # finds $VERSION
    PREREQ_PM         => {
      'Test::More' => 0,
    },
    ABSTRACT_FROM  => 'lib/Linux/Distribution.pm', # retrieve abstract from module
    AUTHOR         => 'Alexandr Ciornii <alexchorny@gmail.com>', #Alberto Re <alberto@accidia.net>
    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
     ('LICENSE'	=> 'perl', 'MIN_PERL_VERSION' => 5.006,) : ()),
    PL_FILES => {},
);

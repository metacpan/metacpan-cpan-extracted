use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Date::WeekOfYear',
    'VERSION_FROM'	=> 'WeekOfYear.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      'Time::Local' => 0,
      'Test::More' => 0, #build only
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'WeekOfYear.pm', # retrieve abstract from module
    AUTHOR     => 'Greg George, IT Technology Solutions P/L, Australia, gng@cpan.org',
    ($ExtUtils::MakeMaker::VERSION ge '6.31'? 
     ('LICENSE'		=> 'perl', ) : ()),
    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
     ('MIN_PERL_VERSION' => 5.006,) : ()),
);

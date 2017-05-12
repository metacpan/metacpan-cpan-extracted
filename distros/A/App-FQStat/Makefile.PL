use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::FQStat',
    VERSION_FROM      => 'lib/App/FQStat.pm', # finds $VERSION
    PREREQ_PM         => {
      DateTime => '0',
      File::HomeDir => '0',
      String::ShellQuote => '0',
      String::Trigram => '0',
      Term::ANSIScreen => '0',
      Term::CallEditor => '0',
      Time::HiRes => '0',
      Term::ReadKey => '0',
      Time::Zone => '0',
      YAML::Tiny => '0',
      threads => '0',
      threads::shared => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/FQStat.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org') : ()),
);

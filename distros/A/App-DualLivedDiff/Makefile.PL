use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::DualLivedDiff',
    VERSION_FROM      => 'lib/App/DualLivedDiff.pm', # finds $VERSION
    PREREQ_PM         => {
      'Archive::Extract' => '0',
      'File::Find' => '0',
      'Getopt::Long' => '0',
      'Parse::CPAN::Meta' => '0.04',
      'LWP::Simple' => '0',
      'File::Temp' => '0',
      'File::Spec' => '0',
    }, # e.g., Module::Name => 1.1
    LICENSE => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/DualLivedDiff.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    EXE_FILES => [
      'script/dualLivedDiff',
    ],
);


use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::PayPal::SDK',
    VERSION_FROM      => 'lib/Business/PayPal/SDK.pm', # finds $VERSION
    PREREQ_PM         => {
      'Class::Accessor' => 0,
      'Inline' => 0,
      'Inline::Java' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/PayPal/SDK.pm', # retrieve abstract from module
       AUTHOR         => 'Jacob Boswell <jacob@s56.net>') : ()),
);

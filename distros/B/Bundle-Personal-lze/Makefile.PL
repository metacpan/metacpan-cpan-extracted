use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bundle::Personal::lze',
    VERSION_FROM      => 'lib/Bundle/Personal/lze.pm', # finds $VERSION
    PREREQ_PM         => {Module::Signature => 0.55}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       AUTHOR         => 'Dirk Lindner <linse@suse.de>') : ()),
);

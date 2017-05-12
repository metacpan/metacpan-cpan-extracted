use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Archive::Tyd',
    VERSION_FROM      => 'lib/Archive/Tyd.pm', # finds $VERSION
    PREREQ_PM         => {
       'Crypt::CipherSaber' => 1.00,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Archive/Tyd.pm', # retrieve abstract from module
       AUTHOR         => 'C. J. Kirsle <kirsle@cpan.org>') : ()),
);

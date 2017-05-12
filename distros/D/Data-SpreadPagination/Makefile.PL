use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::SpreadPagination',
    VERSION_FROM      => 'lib/Data/SpreadPagination.pm', # finds $VERSION
    NO_META           => 1,
    PREREQ_PM         => {
        'Data::Page' => 0.18,
        'Math::Round' => '0',
      }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/SpreadPagination.pm', # retrieve abstract from module
       AUTHOR         => 'Jody Belka <knew@cpan.org>') : ()),
);

use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CCCP::SQLiteWrap',
    VERSION_FROM      => 'lib/CCCP/SQLiteWrap.pm', # finds $VERSION
    PREREQ_PM         => {
                           DBI => 0,
                           File::Temp => 0,
                           File::Copy => 0,
                           Data::UUID => 0,
                           Digest::MD5 => 0
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/CCCP/Encode.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Sivirinov') : ()),
);

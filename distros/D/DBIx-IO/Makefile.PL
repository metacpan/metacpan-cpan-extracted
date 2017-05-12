use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::IO',
    VERSION_FROM      => 'IO.pm', # finds $VERSION
    PREREQ_PM         => { DBI => 0, POSIX => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'IO.pm', # retrieve abstract from module
       AUTHOR         => 'Reed Sandberg') : ()),
);

unless (eval('require Date::Manip'))
{
    warn("Optional module Date::Manip not found, you will\nnot be able to use DBIx::IO::GenLib::normalize_date() (man\nDBIx::IO::GenLib, see $DBIx::IO::GenLib::UNKNOWN_DATE_FORMAT)\n");
}


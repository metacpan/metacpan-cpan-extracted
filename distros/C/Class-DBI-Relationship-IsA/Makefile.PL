use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::Relationship::IsA',
    VERSION_FROM      => 'lib/Class/DBI/Relationship/IsA.pm', # finds $VERSION
    PREREQ_PM         => { Class::DBI => 0.96, Class::DBI::AbstractSearch => 0.05 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       ( AUTHOR         => 'Richard Hundt <richard@webtk.org.uk>') : ()),
);

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Class::DBI::Relationship::HasManyOrdered',
    VERSION_FROM      => 'lib/Class/DBI/Relationship/HasManyOrdered.pm', # finds $VERSION
    PREREQ_PM         => { Class::DBI => 0.96 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Aaron Trevena <teejay@droogs.org>') : ()),
);

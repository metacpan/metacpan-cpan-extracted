use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	   => 'Class::ObjectTemplate::DB',
    VERSION_FROM   => 'DB.pm',
    PREREQ_PM => { 'Class::ObjectTemplate' => '0.7'}
);

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'              =>  'Data::ACL',
    'PREREQ_PM'         =>  {
        'Set::NestedGroups' =>  0.01
    },
    'VERSION_FROM'      =>  'lib/Data/ACL.pm'
);

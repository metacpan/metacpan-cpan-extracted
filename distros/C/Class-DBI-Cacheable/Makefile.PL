use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Class::DBI::Cacheable',
    'VERSION'   => '0.03',
    'PREREQ_PM' => {
        DBI              => 0,
        Class::DBI       => 0,
        CLASS            => 0,
        Cache::Cache     => 0,
        Cache::FileCache => 0,
    },
);

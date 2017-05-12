use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Cache::YAMLCache',
    'VERSION_FROM' => 'YAMLCache.pm',
    'PREREQ_PM'    => {
        'Cache::Cache' => 0,
        'YAML' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT => 'Cache::Cache implementation that persists cache data as YAML',
       AUTHOR   => 'Michael Nachbaur <mike@nachbaur.com>') : ()),
);

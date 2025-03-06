use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Array::Intersection',
    VERSION_FROM      => 'lib/Array/Intersection.pm',
    PREREQ_PM         => {
                          'Test::Simple'    => 0, #Test::More
                          'List::MoreUtils' => 0, #uniq
                          'Exporter'        => 0,
                         },
    ABSTRACT_FROM     => 'lib/Array/Intersection.pm',
    AUTHOR            => 'Michael R. Davis <MRDVT>',
    LICENSE           => 'mit',
  'META_MERGE' => {
    'meta-spec' => {
      'version' => 2
    },
    'resources' => {
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Array-Intersection/issues'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Array-Intersection',
      'repository' => {
        'url' => 'git@github.com:mrdvt92/perl-Array-Intersection.git',
        'web' => 'https://github.com/mrdvt92/perl-Array-Intersection.git',
        'type' => 'git'
      }
    }
  },
);

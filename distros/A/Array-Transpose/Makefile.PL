use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Array::Transpose',
    VERSION_FROM  => 'lib/Array/Transpose.pm',
    AUTHOR        => 'Michael R. Davis',
    ABSTRACT_FROM => 'lib/Array/Transpose.pm',
    LICENSE       => 'bsd',
    PREREQ_PM     => {
                      'Test::Simple' => 0.44,
                      'Exporter'     => 0,
                     },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Array-Transpose.git',
        'url' => 'git@github.com:mrdvt92/perl-Array-Transpose.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Array-Transpose',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Array-Transpose/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);

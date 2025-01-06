use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'DBIx::Array::Connect',
    VERSION_FROM  => 'lib/DBIx/Array/Connect.pm',
    AUTHOR        => 'Michael R. Davis',
    ABSTRACT_FROM => 'lib/DBIx/Array/Connect.pm',
    LICENSE       => 'gpl_2',
    PREREQ_PM     => {
                      'Test::Simple'        => 0.44,
                      'Package::New'        => 0,
                      'Config::IniFiles'    => 0,
                      'Path::Class'         => 0,
                      'DBIx::Array'         => 0.14,
     $^O eq "MSWin32" ?
                    ( 'Win32'               => 0  ):
                    ( 'Sys::Path'           => 0  ),
                     },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-DBIx-Array-Connect.git',
        'url' => 'git@github.com:mrdvt92/perl-DBIx-Array-Connect.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-DBIx-Array-Connect',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-DBIx-Array-Connect/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);

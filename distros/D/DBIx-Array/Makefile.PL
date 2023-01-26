use ExtUtils::MakeMaker;
WriteMakefile(
 NAME         => 'DBIx::Array',
 LICENSE      => 'mit',
 VERSION_FROM => 'lib/DBIx/Array.pm',
 AUTHOR       => 'Michael R. Davis',
 ABSTRACT_FROM=> 'lib/DBIx/Array.pm',
 PREREQ_PM    => {
                  'DBI'                     => 0,
                  'Test::Simple'            => 0,    #for Test::More
                  'DBD::CSV'                => 0,    #for tests
                  'Tie::Cache'              => 0,    #for prepare cache
                  'File::Basename'          => 0,    #for connect
                 },
 META_MERGE   => {
                  'resources' => {
                    'repository' => {
                      'web' => 'https://github.com/mrdvt92/perl-DBIx-Array.git',
                      'url' => 'git@github.com:mrdvt92/perl-DBIx-Array.git',
                      'type' => 'git'
                    },
                    'homepage' => 'https://github.com/mrdvt92/perl-DBIx-Array',
                    'bugtracker' => {
                      'web' => 'https://github.com/mrdvt92/perl-DBIx-Array/issues'
                    },
                  },
                  'meta-spec' => {
                    'version' => 2
                  },
                 },
);

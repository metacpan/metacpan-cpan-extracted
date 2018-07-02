use ExtUtils::MakeMaker;
WriteMakefile(
 NAME         => 'DBIx::Array',
 VERSION_FROM => 'lib/DBIx/Array.pm',
 AUTHOR       => 'Michael R. Davis (domain=>stopllc,tld=>com,account=>mdavis)',
 ABSTRACT_FROM=> 'lib/DBIx/Array.pm',
 PREREQ_PM    => {
                  'DBI'                     => 0,
                  'Test::Simple'            => 0,    #for Test::More
                  'DBD::CSV'                => 0,    #for tests
                  'Tie::Cache'              => 0,    #for prepare cache
                  'File::Basename'          => 0,    #for connect
                  'List::MoreUtils'         => 0.07, #for mesh function
                 },
);

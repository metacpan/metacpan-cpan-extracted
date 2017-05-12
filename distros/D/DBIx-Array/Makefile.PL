use ExtUtils::MakeMaker;
WriteMakefile(
 NAME         => 'DBIx-Array',
 VERSION_FROM => 'lib/DBIx/Array.pm',
 AUTHOR       => 'Michael R. Davis (domain=>stopllc,tld=>com,account=>mdavis)',
 ABSTRACT_FROM=> 'lib/DBIx/Array.pm',
 PREREQ_PM    => {
               'DBI'                     => 0,    #need 1.40 for prepare cache
               'Test::Simple'            => 0,    #for Test::More
               'DBD::CSV'                => 0,    #for tests
               'Package::New'            => 0,
                 },
);

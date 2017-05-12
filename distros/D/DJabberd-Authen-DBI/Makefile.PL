use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME              => 'DJabberd::Authen::DBI',
   VERSION_FROM      => 'lib/DJabberd/Authen/DBI.pm',
   PREREQ_PM         => { DJabberd => 0.83, DBI => 0 },
   ABSTRACT_FROM  => 'lib/DJabberd/Authen/DBI.pm',
   AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>',
  );

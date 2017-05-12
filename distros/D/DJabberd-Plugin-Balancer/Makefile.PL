use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME              => 'DJabberd::Plugin::Balancer',
   VERSION_FROM      => 'lib/DJabberd/Plugin/Balancer.pm',
   PREREQ_PM         => { DJabberd => 0.83 },
   ABSTRACT_FROM  => 'lib/DJabberd/Plugin/Balancer.pm',
   AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>',
  );

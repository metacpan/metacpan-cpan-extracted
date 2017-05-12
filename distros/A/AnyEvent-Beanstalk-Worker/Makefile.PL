use 5.016001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'AnyEvent::Beanstalk::Worker',
    VERSION_FROM      => 'lib/AnyEvent/Beanstalk/Worker.pm',
    PREREQ_PM         => {
                          'AnyEvent' => '7.05',
                          'AnyEvent::Beanstalk' => '1.123530'
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/AnyEvent/Beanstalk/Worker.pm',
       AUTHOR         => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
);

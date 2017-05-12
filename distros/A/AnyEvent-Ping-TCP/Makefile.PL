use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'AnyEvent::Ping::TCP',
    VERSION_FROM	=> 'lib/AnyEvent/Ping/TCP.pm',
    PREREQ_PM		=> { 'AnyEvent' => 7, 'Time::HiRes' => 1.9719 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/AnyEvent/Ping/TCP.pm',
       AUTHOR         => 'Phillip O\'Donnell <podonnell@cpan.org>') : ()),
);

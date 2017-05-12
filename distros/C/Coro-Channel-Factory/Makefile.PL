use 5.008002;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Coro::Channel::Factory',
    VERSION_FROM      => 'lib/Coro/Channel/Factory.pm', 
    PREREQ_PM         => { 'Coro' => 1 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Coro/Channel/Factory.pm',
       AUTHOR         => 'Phillip O\'Donnell <podonnell@cpan.org>') : ()),
);

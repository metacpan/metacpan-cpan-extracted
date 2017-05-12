
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'AnyEvent::Semaphore',
               VERSION_FROM  => 'lib/AnyEvent/Semaphore.pm',
               PREREQ_PM     => { AnyEvent => '6.01',
                                  Method::WeakCallback => '0.03' },
               ABSTRACT_FROM => 'lib/AnyEvent/Semaphore.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>'
);

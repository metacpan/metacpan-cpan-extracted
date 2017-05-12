use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'AnyEvent::PacketForwarder',
               VERSION_FROM  => 'lib/AnyEvent/PacketForwarder.pm',
               PREREQ_PM     => { 'AnyEvent::PacketReader' => '0',
                                  'AnyEvent' => '0', },
               ABSTRACT_FROM => 'lib/AnyEvent/PacketForwarder.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
);

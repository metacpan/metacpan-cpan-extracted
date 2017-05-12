use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'AnyEvent::PacketReader',
               VERSION_FROM  => 'lib/AnyEvent/PacketReader.pm',
               PREREQ_PM     => { 'AnyEvent' => '0' },
               ABSTRACT_FROM => 'lib/AnyEvent/PacketReader.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
);

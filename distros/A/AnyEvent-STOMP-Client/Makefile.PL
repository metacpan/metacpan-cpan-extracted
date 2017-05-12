use strict;
use warnings;

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;

if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME          => 'AnyEvent::STOMP::Client',
    AUTHOR        => 'Raphael Seebacher <raphael@seebachers.ch>',
    LICENSE       => 'perl',
    ABSTRACT      => 'An event-based non-blocking STOMP 1.2 client based on AnyEvent and Object::Event.',
    VERSION_FROM  => 'lib/AnyEvent/STOMP/Client.pm',
    PREREQ_PM     => {
        'AnyEvent'      => 7.05,
        'Object::Event' => 1.23,
    },
    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=AnyEvent-STOMP-Client',
            repository  => {
                type => 'git',
                web  => 'https://github.com/raphiniert/AnyEvent-STOMP-Client',
                url  => 'git://github.com/raphiniert/AnyEvent-STOMP-Client.git',
            },
        },
    })),
);

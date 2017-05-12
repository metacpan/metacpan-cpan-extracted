use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
    NAME          => 'AnyEvent::REST::Server',
    AUTHOR        => 'Raphael Seebacher <raphael@seebachers.ch>',
    LICENSE       => 'perl',
    ABSTRACT      => 'An AnyEvent-based TCP server providing a RESTful interface.',
    VERSION_FROM  => 'lib/AnyEvent/REST/Server.pm',
    PREREQ_PM     => {
        'AnyEvent'      => 7.04,
        'Object::Event' => 1.23,
    },
);

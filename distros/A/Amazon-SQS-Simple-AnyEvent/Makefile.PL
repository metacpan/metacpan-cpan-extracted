use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Amazon::SQS::Simple::AnyEvent',
    AUTHOR              => 'Jeffrey Ryan Thalhammer <jeff@thaljef.org>',
    VERSION_FROM        => 'lib/Amazon/SQS/Simple/AnyEvent.pm',
    ABSTRACT_FROM       => 'lib/Amazon/SQS/Simple/AnyEvent.pm',
    PREREQ_PM => {
        'Test::More'          => 0,
        'AnyEvent::HTTP'      => 0,
        'Amazon::SQS::Simple' => 2.04,
        'XML::Simple'         => 0,
    },
    clean => {
        FILES => 'Amazon-SQS-Simple-AnyEvent-*'
    },
);

#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Bot::BasicBot::Pluggable::Module::Notify',
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/Notify.pm',
    ABSTRACT            => 'Notify users via email, when they are away from IRC',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Bot::BasicBot::Pluggable'                  => '0',
        'Bot::BasicBot::Pluggable::Module::Seen'    => '0',
        'IO::File'                                  => '0',
        'MIME::Lite'                                => '0',

        # build/test prereqs
        'Test::More'                                => '0.70'

    }
);


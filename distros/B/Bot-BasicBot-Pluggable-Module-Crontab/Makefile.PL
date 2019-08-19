#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Bot::BasicBot::Pluggable::Module::Crontab',
    VERSION_FROM        => 'lib/Bot/BasicBot/Pluggable/Module/Crontab.pm',
    ABSTRACT            => 'Provides a crontab-like message service for IRC channels',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Bot::BasicBot::Pluggable'  => '0',
        'DateTime'                  => '0',
        'IO::File'                  => '0',
        'Time::Crontab'             => '0',

        # build/test prereqs
        'File::Temp'                => '0',
        'FindBin::libs'             => '0',
        'Test::MockModule'          => '0',
        'Test::More'                => '0.70'

    }
);


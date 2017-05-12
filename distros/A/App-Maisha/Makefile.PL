#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'App::Maisha',
    VERSION_FROM        => 'lib/App/Maisha.pm',
    ABSTRACT            => 'A command line social micro-blog networking tool',
    NO_META             => 1,

    PREREQ_PM           => {

        # prereqs
        'Carp'                  => '0',
        'Class::Accessor::Fast' => '0',
        'Config::Any'           => '0',
        'File::Basename'        => '0',
        'File::HomeDir'         => '0',
        'File::Path'            => '0',
        'IO::File'              => '0',
        'Module::Pluggable'     => '2.7',
        'Net::Twitter'          => '3.18003',
        'Storable'              => '0',
        'Term::Shell'           => '0',
        'Text::Wrap'            => '0',

        # used by maisha script
        'FindBin'               => '0',
        'Getopt::Long'          => '0',
        'Pod::Usage'            => '0',     

        # build/test prereqs
        'Test::More'            => '0.70'

    },

    EXE_FILES           => ['script/maisha']
);

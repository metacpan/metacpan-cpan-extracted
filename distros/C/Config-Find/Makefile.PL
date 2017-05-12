#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile( AUTHOR       => 'Salvador Fandino <sfandino@yahoo.com>',
               NAME         => 'Config::Find',
               VERSION_FROM => 'lib/Config/Find.pm',
               ABSTRACT     => 'Find configuration files in the native OS fashion',
               PREREQ_PM    => {# prereqs
                                'File::Which'   => '0',
                                'File::Spec'    => '0',
                                'File::HomeDir' => '0',
                                # build/test prereqs
                                'Test::More'    => '0.70',
                                'IO::File'      => '0' } );

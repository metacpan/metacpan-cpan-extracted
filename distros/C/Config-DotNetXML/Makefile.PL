#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	    ABSTRACT        => 'Use .Net XML COnfig files.',
	    AUTHOR          => ['Jonathan Stowe (jns@gellyfish.co.uk)'],
        NAME            => 'Config::DotNetXML',
        dist            => { 
            COMPRESS    => 'gzip',
            SUFFIX      => '.gz'
        },
        VERSION_FROM  => 'lib/Config/DotNetXML.pm',
        PREREQ_PM     => { 
            'XML::XPath' => '1.13',
            'Test::More'  => '0.33',
        },
        META_MERGE        => {
            "meta-spec" => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'https://github.com/jonathanstowe/Config-DotNetXML.git',
                    web => 'https://github.com/jonathanstowe/Config-DotNetXML',
                },
            },
        },
);


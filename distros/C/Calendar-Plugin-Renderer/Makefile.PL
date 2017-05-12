#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Calendar::Plugin::Renderer',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Calendar/Plugin/Renderer.pm',
    ABSTRACT_FROM      => 'lib/Calendar/Plugin/Renderer.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'        => 0,
        'File::Temp'        => 0,
        'XML::SemanticDiff' => 0,
    },
    PREREQ_PM => {
        'Term::ANSIColor::Markup' => '0.06',
        'SVG'                     => '2.64',
        'Moo'                     => '2.000000',
        'Moo::Role'               => '2.000000',
        'namespace::clean'        => '0.24',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Calendar-Plugin-Renderer-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Calendar::Plugin::Renderer'             => { file => 'lib/Calendar/Plugin/Renderer.pm'          , version => '0.12' },
            'Calendar::Plugin::Renderer::Util'       => { file => 'lib/Calendar/Plugin/Renderer/Util.pm'     , version => '0.12' },
            'Calendar::Plugin::Renderer::Text'       => { file => 'lib/Calendar/Plugin/Renderer/Text.pm'     , version => '0.12' },
            'Calendar::Plugin::Renderer::SVG'        => { file => 'lib/Calendar/Plugin/Renderer/SVG.pm'      , version => '0.12' },
            'Calendar::Plugin::Renderer::SVG::Page'  => { file => 'lib/Calendar/Plugin/Renderer/SVG/Page.pm' , version => '0.12' },
            'Calendar::Plugin::Renderer::SVG::Text'  => { file => 'lib/Calendar/Plugin/Renderer/SVG/Text.pm' , version => '0.12' },
            'Calendar::Plugin::Renderer::SVG::Box'   => { file => 'lib/Calendar/Plugin/Renderer/SVG/Box.pm'  , version => '0.12' },
            'Calendar::Plugin::Renderer::SVG::Label' => { file => 'lib/Calendar/Plugin/Renderer/SVG/Label.pm', version => '0.12' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Calendar-Plugin-Renderer.git',
                web  => 'https://github.com/manwar/Calendar-Plugin-Renderer',
            },
        }})
     : ()
    ),
);

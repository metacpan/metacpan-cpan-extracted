#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Catalyst::Model::KiokuDB',
    VERSION_FROM => 'lib/Catalyst/Model/KiokuDB.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'KiokuDB' => '0.46',
        'KiokuX::Model' => 0,
        'Catalyst' => 5.8,
        'Moose' => 0,
        'Scope::Guard' => 0,
        'Hash::Util::FieldHash::Compat' => 0,

        # FIXME factor out into a separate module?
        'Catalyst::Plugin::Authentication' => 0,
        'KiokuX::User' => 0,
    },
);

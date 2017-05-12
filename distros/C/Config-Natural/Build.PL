#!/usr/bin/perl
use Module::Build;
Module::Build->new(
    'module_name' => 'Config::Natural', 
    'license' => 'perl', 
    'requires' => {
        'Carp' => 0, 
        'File::Spec' => 0, 
        'FileHandle' => 0, 
    }, 
)->create_build_script;

use strict;
use Module::Build;
# $Id: Build.PL,v 1.3 2005/03/25 15:28:53 danielr Exp $

Module::Build->new(
    'license'            => 'perl',
    'module_name'        => 'DBIx::AbstractStatement',
    'create_makefile_pl' => 'traditional',
    'create_readme'      => '1',
    'requires' => {
        'Class::Accessor' => 0,
    }
)->create_build_script;

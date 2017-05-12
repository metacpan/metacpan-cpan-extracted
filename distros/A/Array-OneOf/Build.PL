use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Array::OneOf -- checks if an element is in an array',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Array::OneOf',
            'requires' => {},
            'dist_version_from' => 'lib/Array/OneOf.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();

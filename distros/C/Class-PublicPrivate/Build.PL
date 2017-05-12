use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Class::PublicPrivate - Class with public keys with any name and a separate set of private keys',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Class::PublicPrivate',
            'requires' => {},
            'dist_version_from' => 'lib/Class/PublicPrivate.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();

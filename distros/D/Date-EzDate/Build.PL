use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Date::EzDate - Date and time manipulation made easy',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Date::EzDate',
            'requires' => {},
            'dist_version_from' => 'lib/Date/EzDate.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();

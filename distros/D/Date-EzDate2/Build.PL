use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Date::EzDate2 - Date and time manipulation made easy',
            'requires' => {
                            'DateTime' => '1.34',
                            'Clone' => '0.38',
                            'DateTime::TimeZone' => '2.01',
                            'Test::Most' => '0.34'
                          },
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'dist_version_from' => 'lib/Date/EzDate2.pm',
            'module_name' => 'Date::EzDate2',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();

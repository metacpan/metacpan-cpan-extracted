use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'CGI::Plus -- Extra utilities for CGI',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'CGI::Plus',
            'requires' => {
                            'CGI::Cookie' => 0,
                            'CGI::Safe' => 0,
                            'String::Util' => '1.24'
                          },
            'dist_version_from' => 'lib/CGI/Plus.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();

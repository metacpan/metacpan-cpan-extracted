use strict;

use Module::Build;

Module::Build->new( module_name => 'DateTime::Format::Excel',
                    author      => 'Achim Bursian <aburs@cpan.com>',
                    license     => 'perl',
                    requires    => { 'DateTime' => 0.1705,
                                     'Test::More' => '0.47',
                                   },
                    create_makefile_pl => 'traditional',
                  )->create_build_script;

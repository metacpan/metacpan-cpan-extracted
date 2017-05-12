use strict;
use Module::Build;

Module::Build->new(
                    module_name        => "CGI::Wiki::Formatter::Multiple",
                    license            => "perl",
                    requires           => {
                                            "CGI::Wiki"  => '0.48',
                                          },
                    build_requires     => {
                                            "Test::More" => 0,
                                          },
                    recommends         => {
                                            "DBD::SQLite" => 0, # for testing
                                          },
                    create_makefile_pl => "small",
                  )->create_build_script;

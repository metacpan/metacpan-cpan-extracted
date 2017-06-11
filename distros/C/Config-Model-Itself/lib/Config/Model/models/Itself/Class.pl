#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#    Copyright (c) 2007-2015 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Lesser Public License
#    as published by the Free Software Foundation; either version 2.1
#    of the License, or (at your option) any later version.
#
#    Config-Model-Itself is distributed in the hope that it will be
#    useful, but WITHOUT ANY WARRANTY; without even the implied
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model-Itself; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

[
    [
        name => "Itself::Class",
        author => 'Dominique Dumont',
        copyright => '2007-2011 Dominique Dumont.',
        license => 'LGPL-2',

        class_description =>
          "Configuration class. This class represents a node of a configuration tree.",

        'element' => [

            [qw/class_description license/] => {
                type       => 'leaf',
                value_type => 'string',
            },

            [qw/author copyright/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'uniline',
                }
            },

            'class' => {
                type       => 'leaf',
                value_type => 'uniline',
                summary    => "Override implementation of configuration node",
                description =>
                "Perl class name used to override the default implementation of a configuration node. "
                ."This Perl class must inherit L<Config::Model::Node>. Use with care.",
                assert => {
                    "1_load_class" => {
                        code => 'not defined $_ or eval{Mouse::Util::load_class($_)}; not $@;',
                        msg  => 'Error while loading $_ class ',
                    },
                    "2_class_inherit" => {
                        code => 'not defined $_ or $_->isa("Config::Model::Node")',
                        msg  => 'class $_ must inherit Config::Model::Node',
                    }
            },

            },

            'element' => {
                type       => 'hash',
                level      => 'important',
                ordered    => 1,
                index_type => 'string',
                cargo      => {
                    type              => 'node',
                    config_class_name => 'Itself::Element',
                },
            },

            [qw/include include_backend/] => {
                type  => 'list',
                cargo => {
                    type       => 'leaf',
                    value_type => 'reference',
                    refer_to   => '! class',
                }
            },

            'include_after' => {
                type       => 'leaf',
                value_type => 'reference',
                refer_to   => '- element',
            },

            generated_by => {
                type       => 'leaf',
                value_type => 'uniline',
            },
            'read_config' => {
                type  => 'list',
                cargo => {
                    type              => 'node',
                    config_class_name => 'Itself::ConfigRead',
                },
            },

            'write_config' => {
                type  => 'list',
                cargo => {
                    type              => 'node',
                    config_class_name => 'Itself::ConfigWrite',
                },
            },
            'accept' => {
                type       => 'hash',
                index_type => 'string',
                ordered    => 1,
                cargo      => {
                    type              => 'node',
                    config_class_name => 'Itself::ConfigAccept',
                },
            },
        ],
        'description' => [
            element => "Specify the elements names of this configuration class.",
            include => "Include the element description of another class into this class.",
            include_after => "insert the included elements after a specific element. "
            . "By default, included elements are placed before all other elements.",
            include_backend => "Include the read/write specification of another class into this class.",
            class_description => "Explain the purpose of this configuration class. This description is re-used to generate the documentation of your configuration class. You can use pod markup to format your description. See L<perlpod> for details.",
            read_config => "Specify the Perl class(es) and function(s) used to read configuration data. The specified functions are tried in sequence to get configuration data. ",
            write_config => "Specify the Perl class and function used to write configuration data.",
            generated_by => "When set, this class was generated by some program. You should not edit "
                ."this class as your modifications may be clobbered later on when the class is regenerated.",
            accept => "Specifies names of the elements this configuration class accepts as valid. "
                ."The key of the hash is a regular expression that are be tested against
           candidate parameters. When the parameter matches the regular expression,
           a new parameter is created in the model using the description provided
           in the value of this hash key. Note that the regexp must match the whole name
           of the potential parameter. I.e. the specified regexp is eval\'ed
           with a leading C<^> and a trailing C<\$>."
        ],
    ],

    [
        name => 'Itself::ConfigWR::DefaultLayer',

        'element'     => [
            'config_dir' => {
                type         => 'leaf',
                value_type   => 'uniline',
                level        => 'normal',
            },

            os_config_dir => {
                type => 'hash',
                index_type => 'string',
                cargo      => {
                    type       => 'leaf',
                    value_type => 'uniline',
                },
                summary => 'configuration file directory for specific OS',
                description => 'Specify and alternate location of a configuration directory depending '
                    .q!on the OS (as returned by C<$^O> or C<$Config{'osname'}>, see L<perlport/PLATFORMS>) !
                    .q!Common values for C<$^O> are 'linux', 'MSWin32', 'darwin'!
            },
            'file' => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'normal',
                summary    => 'target configuration file name',
                description => 'specify the configuration file name. This parameter may '
                    .'not be applicable depending on your application. It may also be '
                    .'hardcoded in a custom backend. If not specified, the instance name '
                    .'is used as base name for your configuration file. The configuration file name'
                    .'can be specified with &index keyword when a backend is associated to a node '
                    .'contained in a hash. See '
                    .'L<backend specifications|http://search.cpan.org/dist/Config-Model/lib/Config/Model/BackendMgr.pm#Backend_specification>.'
            },
        ]
    ],

    [
        name => "Itself::ConfigWR",
        include => "Itself::ConfigWR::DefaultLayer",
        include_after => 'backend',

        'element' => [

            'syntax' => {
                type       => 'leaf',
                value_type => 'enum',
                choice     => [qw/cds perl ini custom/],
                status     => 'deprecated',
                description => 'Deprecated parameter that specified the file syntax to store permanently configuration data. Replaced by "backend"',
            },

            'backend' => {
                type         => 'leaf',
                class        => 'Config::Model::Itself::BackendDetector',
                value_type   => 'enum',
                choice       => [qw/cds_file perl_file custom/],
                replace   => {
                    perl => 'perl_file',
                    ini  => 'IniFile',
                    ini_file  => 'IniFile',
                    cds  => 'cds_file',
                },
                migrate_from => {
                    formula   => '$old',
                    variables => { old => '- syntax' },
                },
                description => 'specifies the backend to store permanently configuration data.',
                help => {
                    cds_file => "file with config data string. This is Config::Model own serialisation format, designed to be compact and readable. Configuration filename is made with instance name",
                    IniFile =>
"Ini file format. Beware that the structure of your model must match the limitations of the INI file format, i.e only a 2 levels hierarchy. Configuration filename is made with instance name",
                    perl_file =>
"file with a perl data structure. Configuration filename is made with instance name",
                    custom =>
"Custom format. You must specify your own class and method to perform the read or write function. See Config::Model::AutoRead doc for more details",
               }
            },

           yaml_class => {
                type             => 'leaf',
                value_type       => 'uniline',
                level            => 'hidden',
                description      => 'Specify the YAML class that is used to load and dump YAML files.'
                    .' Defaults to L<YAML::Tiny>.'
                    .' See L<yaml_class doc|Config::Model::Backend::Yaml/yaml_class> for details on '
                    .' why another YAML class can suit your configuration file needs.',
                upstream_default => 'YAML::Tiny',
                warp             => {
                    follow => '- backend',
                    rules  => [ Yaml => { level => 'normal', } ],
                }
            },

            file_mode => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'normal',
                summary     => 'configuration file mode',
                description => 'specify the configuration file mode. C<file_mode> parameter can be used to set the '
                    . 'mode of the written file. C<file_mode> value can be in any form supported by L<Path::Tiny/chmod>.'
            },

            default_layer => {
                type => 'node',
                config_class_name => 'Itself::ConfigWR::DefaultLayer',
                summary => q!How to find default values in a global config file!,
                description => q!Specifies where to find a global configuration file that !
                    .q!specifies default values. For instance, this is used by OpenSSH to !
                    .q!specify a global configuration file (C</etc/ssh/ssh_config>) that is !
                    .q!overridden by user's file!,
            },

            'class' => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                warp       => {
                    follow => '- backend',
                    rules  => [
                        custom => {
                            level     => 'normal',
                            mandatory => 1,
                        }
                    ],
                }
            },

            'store_class_in_hash' => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                description => 'Specify element hash name that contains all INI classes. '
                    .'See L<Config::Model::Backend::IniFile/"Arbitrary class name">',
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },

            'section_map' => {
                type       => 'hash',
                level      => 'hidden',
                index_type => 'string',
                description => 'Specify element name that contains one INI class. E.g. to store '
                     .'INI class [foo] in element Foo, specify { foo => "Foo" } ',
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                },
                cargo => {
                    type => 'leaf',
                    value_type => 'uniline',
                },
            },

            ['split_list_value','split_check_list_value'] => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                description => 'Regexp to split the value read from ini file. Usually "\s+" or "[,\s]"',
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },

            assign_char => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                description => 'Character used to assign value in INI file. Default is C<=>. '
                    .'See L<details|Config::Model::Backend::IniFile/"Handle key value files">',
                upstream_default => '#',
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },

            assign_with => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                description => 'String used write assignment in INI file. Default is "C< = >". '
                    .'See L<details|Config::Model::Backend::IniFile/"Handle key value files">',
                upstream_default => '#',
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },

            ['join_list_value', 'join_check_list_value'] => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },

            'write_boolean_as' => {
                type       => 'list',
                description => 'Specify how to write a boolean value in config file. Suggested values are '
                    . '"no","yes". ',
                max_index => 1,
                cargo => {
                    type => 'leaf',
                    value_type => 'uniline',
                },
            },

            force_lc_section => {
                type => 'leaf',
                value_type => 'boolean',
                level      => 'hidden',
                upstream_default => 0,
                description => "force section to be lowercase",
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },
            force_lc_key => {
                type => 'leaf',
                value_type => 'boolean',
                level      => 'hidden',
                upstream_default => 0,
                description => "force key names to be lowercase",
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },
            force_lc_value => {
                type => 'leaf',
                value_type => 'boolean',
                level      => 'hidden',
                upstream_default => 0,
                description => "force values to be lowercase",
                warp => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },

             'full_dump' => {
                type             => 'leaf',
                value_type       => 'boolean',
                level            => 'hidden',
                description      => 'Also dump default values in the data structure. Useful if the dumped configuration data will be used by the application. (default is yes)',
                upstream_default => '1',
                warp             => {
                    follow => { backend => '- backend' },
                    rules  => [ '$backend =~ /yaml|perl/i' => { level => 'normal', } ],
                }
            },

           'comment_delimiter' => {
                type             => 'leaf',
                value_type       => 'uniline',
                level            => 'hidden',
                description      => 'list of characters that start a comment. When more that one character'
                .' is used. the first one is used to write back comment. For instance,'
                .' value "#;" indicate that a comments can start with "#" or ";" and that all comments'
                .' are written back with "#".',
                upstream_default => '#',
                warp             => {
                    follow => '- backend',
                    rules  => [ IniFile => { level => 'normal', } ],
                }
            },

            'auto_delete' => {
                type             => 'leaf',
                value_type       => 'boolean',
                level            => 'normal',
                upstream_default => 0,
                summary          => 'Delete empty configuration file',
                description      => 'Delete configuration files when no information is left in there.'
                . ' This may happen when data is removed by user. This is mostly useful when the '
                . ' configuration of an application is made of several files.',
            },

        ],
        description => [
            join_list_value => 'string to join list values before writing the entry in ini file. Usually " " or ", "',
            join_check_list_value => 'string to join checked items names before writing the entry in the ini file. Usually " " or ", "',
        ],

    ],

    [
        name    => 'Itself::ConfigRead',
        include => "Itself::ConfigWR",

        'element' => [
            'function' => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                warp       => {
                    follow => '- backend',
                    rules  => [
                        custom => {
                            level            => 'normal',
                            upstream_default => 'read',
                        }
                    ],
                }
            },

            'auto_create' => {
                type             => 'leaf',
                value_type       => 'boolean',
                level            => 'normal',
                upstream_default => 0,
                summary          => 'Creates configuration files as needed',
                migrate_from     => {
                    formula   => '$old',
                    variables => { old => '- allow_empty' },
                },
            },

            'allow_empty' => {
                type             => 'leaf',
                value_type       => 'boolean',
                level            => 'normal',
                status           => 'deprecated',
                upstream_default => 0,
                summary          => 'deprecated in favor of auto_create',
            },

        ],
    ],

    [
        name    => 'Itself::ConfigWrite',
        include => "Itself::ConfigWR",

        'element' => [
            'function' => {
                type       => 'leaf',
                value_type => 'uniline',
                level      => 'hidden',
                warp       => {
                    follow => '- backend',
                    rules  => [
                        custom => {
                            level            => 'normal',
                            upstream_default => 'write',
                        }
                    ],
                }
            },

            # move to ConfigRW when removing legacy allow_empty
            'auto_create' => {
                type             => 'leaf',
                value_type       => 'boolean',
                level            => 'normal',
                upstream_default => 0,
                summary          => 'Creates configuration files as needed',
            },

        ],
    ],
    [
        name => 'Itself::ConfigAccept',

        include       => "Itself::Element",
        include_after => 'accept_after',
        'element'     => [
            'name_match' => {
                type             => 'leaf',
                value_type       => 'uniline',
                upstream_default => '.*',
                status           => 'deprecated',
             },
             'accept_after' => {
                type => 'leaf',
                value_type => 'reference' ,
                refer_to => '- - element' ,
                description => 'specify where to insert accepted element. This does'
                 . ' not change the behavior and helps generating more consistent '
                 . ' user interfaces'
             }

        ],
    ],

];

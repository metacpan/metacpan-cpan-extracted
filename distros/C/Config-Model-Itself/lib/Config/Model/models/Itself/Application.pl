#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
    {
        name => 'Itself::Application',
        # read/written by Config::Model::Itself (read_all)

        element => [
            model => {
                refer_to => '! class',
                type => 'leaf',
                value_type => 'reference',
                description => 'Top class required to configure this application',
            },
            synopsis => {
                type => 'leaf',
                value_type => 'uniline',
                description => "one line description of the application."
            },
            link_to_doc => {
                type => 'leaf',
                value_type => 'uniline',
                description => "Documentation URL."
            },
            category => {
                choice => [
                    'system',
                    'user',
                    'application'
                ],
                type => 'leaf',
                value_type => 'enum',
                mandatory => 1,
                description => 'Can be "system", "user" or "application"',
                help => {
                    system => 'Configuration file is owned by root and usually located in C</etc>',
                    user => 'Configuration files is owned by user and usually located in C<~/.*>',
                    application => 'Configuration file is located anywhere and is usually explicitly '
                    .'specified to application. E.g. C<multistrap -f CONFIG_FILE>',
                }
            },
            allow_config_file_override => {
                type => 'leaf',
                upstream_default => '0',
                value_type => 'boolean',
                description => 'Set if user can override the configuration file loaded by default by cme',
            },
            require_config_file => {
                type => 'leaf',
                upstream_default => '0',
                value_type => 'boolean',
                description => "set when there's no default path for the configuration file."
                . "user will have to specify a configuration file with C<--file> option."
            },
            require_backend_argument => {
                type => 'leaf',
                upstream_default => '0',
                value_type => 'boolean',
                description => "set when the application backend requires an argument passed "
                . "as 3rd argument to cme, e.g. cme <cmd> <app> <backend_arg>."
            },
            use_backend_argument_as_config_file  => {
                type => 'leaf',
                upstream_default => '0',
                value_type => 'boolean',
                description => "When backend argument is also used as the name of the config file."
            },
            backend_argument_info => {
                type => 'leaf',
                value_type => 'uniline',
                description => "Short description of the backend argument. Used to generate error "
                    ."message when user forgets to set the 3rd cme argument."
            },
            config_dir => {
                type => 'leaf',
                value_type => 'uniline',
                description => "set configuration directory where config file is read from "
                . "or written to. This value does not override a directory specified in the model."
            },
            support_info => {
                type => 'leaf',
                value_type => 'uniline',
                description => "Instructions to let user report a bug for this application. This URL is shown in "
                    . 'the message of unknown element exception in the string "please submit a bug report '
                    . '$support_info". Defaults to an url to Config::Model bug tracker',
                upstream_default => 'to https://github.com/dod38fr/config-model/issues',
            }
        ],
    }
] ;


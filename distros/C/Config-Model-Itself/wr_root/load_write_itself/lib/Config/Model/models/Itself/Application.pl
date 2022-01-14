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
    'element' => [
      'model',
      {
        'description' => 'Top class required to configure this application',
        'refer_to' => '! class',
        'type' => 'leaf',
        'value_type' => 'reference'
      },
      'synopsis',
      {
        'description' => 'one line description of the application.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'link_to_doc',
      {
        'description' => 'Documentation URL.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'category',
      {
        'choice' => [
          'system',
          'user',
          'application'
        ],
        'description' => 'Can be "system", "user" or "application"',
        'help' => {
          'application' => 'Configuration file is located anywhere and is usually explicitly specified to application. E.g. C<multistrap -f CONFIG_FILE>',
          'system' => 'Configuration file is owned by root and usually located in C</etc>',
          'user' => 'Configuration files is owned by user and usually located in C<~/.*>'
        },
        'mandatory' => 1,
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'allow_config_file_override',
      {
        'description' => 'Set if user can override the configuration file loaded by default by cme',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'require_config_file',
      {
        'description' => 'set when there\'s no default path for the configuration file.user will have to specify a configuration file with C<--file> option.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'require_backend_argument',
      {
        'description' => 'set when the application backend requires an argument passed as 3rd argument to cme, e.g. cme <cmd> <app> <backend_arg>.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'use_backend_argument_as_config_file',
      {
        'description' => 'When backend argument is also used as the name of the config file.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'backend_argument_info',
      {
        'description' => 'Short description of the backend argument. Used to generate error message when user forgets to set the 3rd cme argument.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'config_dir',
      {
        'description' => 'set configuration directory where config file is read from or written to. This value does not override a directory specified in the model.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'support_info',
      {
        'description' => 'Instructions to let user report a bug for this application. This URL is shown in the message of unknown element exception in the string "please submit a bug report $support_info". Defaults to an url to Config::Model bug tracker',
        'type' => 'leaf',
        'upstream_default' => 'to https://github.com/dod38fr/config-model/issues',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'Itself::Application'
  }
]
;


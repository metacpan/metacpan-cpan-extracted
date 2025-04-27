#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2022 by Dominique Dumont <ddumont@cpan.org>.
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
      'a_string',
      {
        'default' => 'test failed',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'CmeAppTest',
    'rw_config' => {
      'auto_create' => '1',
      'backend' => 'Yaml',
      'file' => 'cme-test.yml'
    }
  }
]
;


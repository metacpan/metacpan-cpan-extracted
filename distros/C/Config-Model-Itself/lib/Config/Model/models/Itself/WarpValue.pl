#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  [
      name => "Itself::WarpApply",
      gist => "{when}",
      element => [
          when => {
              type => 'leaf',
              value_type => 'string',
          },
          apply => {
              type => 'warped_node',
              warp => {
                  rules => [
                      '&get_type =~ /hash|list/' => {
                          config_class_name => 'Itself::WarpableElement'
                      },
                      '&get_type !~ /hash|list/' => {
                          config_class_name => 'Itself::WarpOnlyElement' ,
                      }
                  ]
              },
              description => 'Apply parameters when the "when" condition is true. The "when" condition '.
              'is a formula using the '
              . 'variables defined in "follow" element. Only the first matching "when" condition is applied.',
          }
      ]
  ],
  [
   name => "Itself::WarpValue",

   class_description => 'Warp functionality enable a Value object to change its properties (i.e. default value or its type) dynamically according to the value of another Value object located elsewhere in the configuration tree.',

   gist => '@{rules} rules',

   'element' => [
       'follow' => {
           type => 'hash',
           index_type =>'string',
           cargo => { type => 'leaf', value_type => 'uniline' } ,
           description => 'Specify with the path of the configuration element that drives '
           .'the warp, i.e .the elements that control the property change. '
           .'These are specified using a variable name (used in the "rules" formula)'
           .'and a path to fetch the actual value. Example $country => " ! country"',
       },
       'rules' => {
           type => 'list',
           cargo => {
               type => 'node',
               config_class_name => "Itself::WarpApply",
           },
           description => 'Specify a set of test and paramaters to apply. Only the fist matching test is used to apply its parameters.'
       },
   ],
],
];

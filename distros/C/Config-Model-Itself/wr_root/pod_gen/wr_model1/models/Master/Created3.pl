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
    'author' => [
      'dod@foo.com'
    ],
    'class_description' => 'Master class created nb 3
for tests purpose.',
    'copyright' => [
      '2011 dod'
    ],
    'element' => [
      'created1',
      {
        'description' => 'element 1',
        'type' => 'leaf',
        'value_type' => 'number'
      },
      'created2',
      {
        'description' => 'another element',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'license' => 'LGPL',
    'name' => 'Master::Created3'
  }
]
;

=head1 Annotations

=over

=item class:"Master::Created3"

my great class 3

=item class:"Master::Created3" element:created1 type

not autumn

=item class:"Master::Created3" element:created1 type

not autumn

=back


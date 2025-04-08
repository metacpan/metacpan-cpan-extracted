#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2025 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'accept' => [
      '.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Unexpected systemd parameter. Please contact cme author to update systemd model.'
      }
    ],
    'element' => [
      'Alias',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'A space-separated list of additional names this unit shall be installed under. The names listed
here must have the same suffix (i.e. type) as the unit filename. This option may be specified more than once,
in which case all listed names are used. At installation time, systemctl enable will create
symlinks from these names to the unit filename. Note that not all unit types support such alias names, and this
setting is not supported for them. Specifically, mount, slice, swap, and automount units do not support
aliasing.',
        'type' => 'list'
      },
      'WantedBy',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This option may be used more than once, or a space-separated list of unit names may
be given. A symbolic link is created in the C<.wants/>, C<.requires/>,
or C<.upholds/> directory of each of the listed units when this unit is installed
by systemctl enable. This has the effect of a dependency of type
C<Wants>, C<Requires>, or C<Upholds> being added
from the listed unit to the current unit. See the description of the mentioned dependency types
in the [Unit] section for details.

In case of template units listing non template units, the listing unit must have
C<DefaultInstance> set, or systemctl enable must be called with
an instance name. The instance (default or specified) will be added to the
C<.wants/>, C<.requires/>, or C<.upholds/>
list of the listed unit. For example, WantedBy=getty.target in a service
C<getty@.service> will result in systemctl enable getty@tty2.service
creating a C<getty.target.wants/getty@tty2.service> link to
C<getty@.service>. This also applies to listing specific instances of templated
units: this specific instance will gain the dependency. A template unit may also list a template
unit, in which case a generic dependency will be added where each instance of the listing unit will
have a dependency on an instance of the listed template with the same instance value. For example,
WantedBy=container@.target in a service C<monitor@.service> will
result in systemctl enable monitor@.service creating a
C<container@.target.wants/monitor@.service> link to
C<monitor@.service>, which applies to all instances of
C<container@.target>.',
        'type' => 'list'
      },
      'RequiredBy',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This option may be used more than once, or a space-separated list of unit names may
be given. A symbolic link is created in the C<.wants/>, C<.requires/>,
or C<.upholds/> directory of each of the listed units when this unit is installed
by systemctl enable. This has the effect of a dependency of type
C<Wants>, C<Requires>, or C<Upholds> being added
from the listed unit to the current unit. See the description of the mentioned dependency types
in the [Unit] section for details.

In case of template units listing non template units, the listing unit must have
C<DefaultInstance> set, or systemctl enable must be called with
an instance name. The instance (default or specified) will be added to the
C<.wants/>, C<.requires/>, or C<.upholds/>
list of the listed unit. For example, WantedBy=getty.target in a service
C<getty@.service> will result in systemctl enable getty@tty2.service
creating a C<getty.target.wants/getty@tty2.service> link to
C<getty@.service>. This also applies to listing specific instances of templated
units: this specific instance will gain the dependency. A template unit may also list a template
unit, in which case a generic dependency will be added where each instance of the listing unit will
have a dependency on an instance of the listed template with the same instance value. For example,
WantedBy=container@.target in a service C<monitor@.service> will
result in systemctl enable monitor@.service creating a
C<container@.target.wants/monitor@.service> link to
C<monitor@.service>, which applies to all instances of
C<container@.target>.',
        'type' => 'list'
      },
      'UpheldBy',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This option may be used more than once, or a space-separated list of unit names may
be given. A symbolic link is created in the C<.wants/>, C<.requires/>,
or C<.upholds/> directory of each of the listed units when this unit is installed
by systemctl enable. This has the effect of a dependency of type
C<Wants>, C<Requires>, or C<Upholds> being added
from the listed unit to the current unit. See the description of the mentioned dependency types
in the [Unit] section for details.

In case of template units listing non template units, the listing unit must have
C<DefaultInstance> set, or systemctl enable must be called with
an instance name. The instance (default or specified) will be added to the
C<.wants/>, C<.requires/>, or C<.upholds/>
list of the listed unit. For example, WantedBy=getty.target in a service
C<getty@.service> will result in systemctl enable getty@tty2.service
creating a C<getty.target.wants/getty@tty2.service> link to
C<getty@.service>. This also applies to listing specific instances of templated
units: this specific instance will gain the dependency. A template unit may also list a template
unit, in which case a generic dependency will be added where each instance of the listing unit will
have a dependency on an instance of the listed template with the same instance value. For example,
WantedBy=container@.target in a service C<monitor@.service> will
result in systemctl enable monitor@.service creating a
C<container@.target.wants/monitor@.service> link to
C<monitor@.service>, which applies to all instances of
C<container@.target>.',
        'type' => 'list'
      },
      'Also',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Additional units to install/deinstall when
this unit is installed/deinstalled. If the user requests
installation/deinstallation of a unit with this option
configured, systemctl enable and
systemctl disable will automatically
install/uninstall units listed in this option as well.

This option may be used more than once, or a
space-separated list of unit names may be
given.',
        'type' => 'list'
      },
      'DefaultInstance',
      {
        'description' => 'In template unit files, this specifies for
which instance the unit shall be enabled if the template is
enabled without any explicitly set instance. This option has
no effect in non-template unit files. The specified string
must be usable as instance identifier.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'generated_by' => 'parseman.pl from systemd doc',
    'name' => 'Systemd::Section::Install'
  }
]
;


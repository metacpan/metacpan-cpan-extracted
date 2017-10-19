#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'accept' => [
      '.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'class_description' => 'common install section',
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
        'description' => 'This option may be used more than once, or a
space-separated list of unit names may be given. A symbolic
link is created in the .wants/ or
.requires/ directory of each of the
listed units when this unit is installed by systemctl
enable. This has the effect that a dependency of
type C<Wants> or C<Requires>
is added from the listed unit to the current unit. The primary
result is that the current unit will be started when the
listed unit is started. See the description of
C<Wants> and C<Requires> in
the [Unit] section for details.

WantedBy=foo.service in a service
bar.service is mostly equivalent to
Alias=foo.service.wants/bar.service in the
same file. In case of template units, systemctl
enable must be called with an instance name, and
this instance will be added to the
.wants/ or
.requires/ list of the listed unit. E.g.
WantedBy=getty.target in a service
getty@.service will result in
systemctl enable getty@tty2.service
creating a
getty.target.wants/getty@tty2.service
link to getty@.service.
',
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
      },
      'RequiredBy',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This option may be used more than once, or a
space-separated list of unit names may be given. A symbolic
link is created in the .wants/ or
.requires/ directory of each of the
listed units when this unit is installed by systemctl
enable. This has the effect that a dependency of
type C<Wants> or C<Requires>
is added from the listed unit to the current unit. The primary
result is that the current unit will be started when the
listed unit is started. See the description of
C<Wants> and C<Requires> in
the [Unit] section for details.

WantedBy=foo.service in a service
bar.service is mostly equivalent to
Alias=foo.service.wants/bar.service in the
same file. In case of template units, systemctl
enable must be called with an instance name, and
this instance will be added to the
.wants/ or
.requires/ list of the listed unit. E.g.
WantedBy=getty.target in a service
getty@.service will result in
systemctl enable getty@tty2.service
creating a
getty.target.wants/getty@tty2.service
link to getty@.service.
',
        'type' => 'list'
      }
    ],
    'name' => 'Systemd::Section::Install'
  }
]
;


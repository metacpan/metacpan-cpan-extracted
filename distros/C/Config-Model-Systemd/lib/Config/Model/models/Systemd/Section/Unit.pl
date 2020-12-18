#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2020 by Dominique Dumont.
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
        'warn' => 'Unknown parameter'
      }
    ],
    'class_description' => "A unit file is a plain text ini-style file that encodes information about a service, a
socket, a device, a mount point, an automount point, a swap file or partition, a start-up
target, a watched file system path, a timer controlled and supervised by
L<systemd(1)>, a
resource management slice or a group of externally created processes. See
L<systemd.syntax(7)>
for a general description of the syntax.

This man page lists the common configuration options of all
the unit types. These options need to be configured in the [Unit]
or [Install] sections of the unit files.

In addition to the generic [Unit] and [Install] sections
described here, each unit may have a type-specific section, e.g.
[Service] for a service unit. See the respective man pages for
more information:
L<systemd.service(5)>,
L<systemd.socket(5)>,
L<systemd.device(5)>,
L<systemd.mount(5)>,
L<systemd.automount(5)>,
L<systemd.swap(5)>,
L<systemd.target(5)>,
L<systemd.path(5)>,
L<systemd.timer(5)>,
L<systemd.slice(5)>,
L<systemd.scope(5)>.


Unit files are loaded from a set of paths determined during compilation, described in the next
section.

Valid unit names consist of a \"name prefix\" and a dot and a suffix specifying the unit type. The
\"unit prefix\" must consist of one or more valid characters (ASCII letters, digits, C<:>,
C<->, C<_>, C<.>, and C<\\>). The total
length of the unit name including the suffix must not exceed 256 characters. The type suffix must be one
of C<.service>, C<.socket>, C<.device>,
C<.mount>, C<.automount>, C<.swap>,
C<.target>, C<.path>, C<.timer>,
C<.slice>, or C<.scope>.

Units names can be parameterized by a single argument called the \"instance name\". The unit is then
constructed based on a \"template file\" which serves as the definition of multiple services or other
units. A template unit must have a single C<\@> at the end of the name (right before the
type suffix). The name of the full unit is formed by inserting the instance name between
C<\@> and the unit type suffix. In the unit file itself, the instance parameter may be
referred to using C<%i> and other specifiers, see below.

Unit files may contain additional options on top of those
listed here. If systemd encounters an unknown option, it will
write a warning log message but continue loading the unit. If an
option or section name is prefixed with C<X->, it is
ignored completely by systemd. Options within an ignored section
do not need the prefix. Applications may use this to include
additional information in the unit files.

Units can be aliased (have an alternative name), by creating a symlink from the new name to the
existing name in one of the unit search paths. For example, C<systemd-networkd.service>
has the alias C<dbus-org.freedesktop.network1.service>, created during installation as
a symlink, so when systemd is asked through D-Bus to load
C<dbus-org.freedesktop.network1.service>, it'll load
C<systemd-networkd.service>. As another example, C<default.target> \x{2014}
the default system target started at boot \x{2014} is commonly symlinked (aliased) to either
C<multi-user.target> or C<graphical.target> to select what is started
by default. Alias names may be used in commands like disable,
start, stop, status, and similar, and in all
unit dependency directives, including C<Wants>, C<Requires>,
C<Before>, C<After>. Aliases cannot be used with the
preset command.

Aliases obey the following restrictions: a unit of a certain type (C<.service>,
C<.socket>, \x{2026}) can only be aliased by a name with the same type suffix. A plain unit (not
a template or an instance), may only be aliased by a plain name. A template instance may only be aliased
by another template instance, and the instance part must be identical. A template may be aliased by
another template (in which case the alias applies to all instances of the template). As a special case, a
template instance (e.g. C<alias\@inst.service>) may be a symlink to different template
(e.g. C<template\@inst.service>). In that case, just this specific instance is aliased,
while other instances of the template (e.g. C<alias\@foo.service>,
C<alias\@bar.service>) are not aliased. Those rule preserve the requirement that the
instance (if any) is always uniquely defined for a given unit and all its aliases.

Unit files may specify aliases through the C<Alias> directive in the [Install]
section. When the unit is enabled, symlinks will be created for those names, and removed when the unit is
disabled. For example, C<reboot.target> specifies
C<Alias=ctrl-alt-del.target>, so when enabled, the symlink
C</etc/systemd/systemd/ctrl-alt-del.service> pointing to the
C<reboot.target> file will be created, and when
CtrlAltDel is invoked,
systemd will look for the C<ctrl-alt-del.service> and execute
C<reboot.service>. systemd does not look at the [Install] section at
all during normal operation, so any directives in that section only have an effect through the symlinks
created during enablement.

Along with a unit file C<foo.service>, the directory
C<foo.service.wants/> may exist. All unit files symlinked from such a directory are
implicitly added as dependencies of type C<Wants> to the unit. Similar functionality
exists for C<Requires> type dependencies as well, the directory suffix is
C<.requires/> in this case. This functionality is useful to hook units into the
start-up of other units, without having to modify their unit files. For details about the semantics of
C<Wants>, see below. The preferred way to create symlinks in the
C<.wants/> or C<.requires/> directory of a unit file is by embedding
the dependency in [Install] section of the target unit, and creating the symlink in the file system with
the enable or preset commands of
L<systemctl(1)>.

Along with a unit file C<foo.service>, a \"drop-in\" directory
C<foo.service.d/> may exist. All files with the suffix C<.conf> from this
directory will be parsed after the unit file itself is parsed. This is useful to alter or add configuration
settings for a unit, without having to modify unit files. Drop-in files must contain appropriate section
headers. For instantiated units, this logic will first look for the instance C<.d/> subdirectory
(e.g. C<foo\@bar.service.d/>) and read its C<.conf> files, followed by the template
C<.d/> subdirectory (e.g. C<foo\@.service.d/>) and the C<.conf>
files there. Moreover for units names containing dashes (C<->), the set of directories generated by
truncating the unit name after all dashes is searched too. Specifically, for a unit name
C<foo-bar-baz.service> not only the regular drop-in directory
C<foo-bar-baz.service.d/> is searched but also both C<foo-bar-.service.d/> and
C<foo-.service.d/>. This is useful for defining common drop-ins for a set of related units, whose
names begin with a common prefix. This scheme is particularly useful for mount, automount and slice units, whose
systematic naming structure is built around dashes as component separators. Note that equally named drop-in files
further down the prefix hierarchy override those further up,
i.e. C<foo-bar-.service.d/10-override.conf> overrides
C<foo-.service.d/10-override.conf>.

In cases of unit aliases (described above), dropins for the aliased name and all aliases are
loaded. In the example of C<default.target> aliasing
C<graphical.target>, C<default.target.d/>,
C<default.target.wants/>, C<default.target.requires/>,
C<graphical.target.d/>, C<graphical.target.wants/>,
C<graphical.target.requires/> would all be read. For templates, dropins for the
template, any template aliases, the template instance, and all alias instances are read. When just a
specific template instance is aliased, then the dropins for the target template, the target template
instance, and the alias template instance are read.

In addition to C</etc/systemd/system>, the drop-in C<.d/>
directories for system services can be placed in C</usr/lib/systemd/system> or
C</run/systemd/system> directories. Drop-in files in C</etc/>
take precedence over those in C</run/> which in turn take precedence over those
in C</usr/lib/>. Drop-in files under any of these directories take precedence
over unit files wherever located. Multiple drop-in files with different names are applied in
lexicographic order, regardless of which of the directories they reside in.

Units also support a top-level drop-in with C<type.d/>,
where type may be e.g. C<service> or C<socket>,
that allows altering or adding to the settings of all corresponding unit files on the system.
The formatting and precedence of applying drop-in configurations follow what is defined above.
Configurations in C<type.d/> have the lowest precedence
compared to settings in the name specific override directories. So the contents of
C<foo-.service.d/10-override.conf> would override
C<service.d/10-override.conf>.

Note that while systemd offers a flexible dependency system
between units it is recommended to use this functionality only
sparingly and instead rely on techniques such as bus-based or
socket-based activation which make dependencies implicit,
resulting in a both simpler and more flexible system.

As mentioned above, a unit may be instantiated from a template file. This allows creation
of multiple units from a single configuration file. If systemd looks for a unit configuration
file, it will first search for the literal unit name in the file system. If that yields no
success and the unit name contains an C<\@> character, systemd will look for a
unit template that shares the same name but with the instance string (i.e. the part between the
C<\@> character and the suffix) removed. Example: if a service
C<getty\@tty3.service> is requested and no file by that name is found, systemd
will look for C<getty\@.service> and instantiate a service from that
configuration file if it is found.

To refer to the instance string from within the
configuration file you may use the special C<%i>
specifier in many of the configuration options. See below for
details.

If a unit file is empty (i.e. has the file size 0) or is
symlinked to C</dev/null>, its configuration
will not be loaded and it appears with a load state of
C<masked>, and cannot be activated. Use this as an
effective way to fully disable a unit, making it impossible to
start it even manually.

The unit file format is covered by the
L<Interface
Portability and Stability Promise|https://systemd.io/PORTABILITY_AND_STABILITY/>.

The set of load paths for the user manager instance may be augmented or
changed using various environment variables. And environment variables may in
turn be set using environment generators, see
L<systemd.environment-generator(7)>.
In particular, C<\$XDG_DATA_HOME> and
C<\$XDG_DATA_DIRS> may be easily set using
L<systemd-environment-d-generator(8)>.
Thus, directories listed here are just the defaults. To see the actual list that
would be used based on compilation options and current environment use


+-+systemd-analyze --user unit-paths



Moreover, additional units might be loaded into systemd from
directories not on the unit load path by creating a symlink pointing to a
unit file in the directories. You can use systemctl link
for this operation. See
L<systemctl(1)>
for its usage and precaution.


Unit files may also include a number of C<Condition\x{2026}=> and
C<Assert\x{2026}=> settings. Before the unit is started, systemd will verify
that the specified conditions are true. If not, the starting of the unit will be (mostly silently)
skipped. Failing conditions will not result in the unit being moved into the C<failed>
state. The conditions are checked at the time the queued start job is to be executed. The ordering
dependencies are still respected, so other units are still pulled in and ordered as if this unit was
successfully activated. Use condition expressions in order to skip units that do not apply to the local
system, for example because the kernel or runtime environment doesn't require their functionality.


If multiple conditions are specified, the unit will be executed if all of them apply (i.e. a
logical AND is applied). Condition checks can use a pipe symbol (C<|>) after the equals
sign (C<Condition\x{2026}=|\x{2026}>), which causes the condition becomes a triggering condition. If
at least one triggering condition is defined for a unit, then the unit will be executed if at least one
of the triggering conditions apply and all of the non-triggering conditions. If you prefix an argument
with the pipe symbol and an exclamation mark, the pipe symbol must be passed first, the exclamation
second. If any of these options is assigned the empty string, the list of conditions is reset
completely, all previous condition settings (of any kind) will have no effect.

The C<AssertArchitecture>, C<AssertVirtualization>, \x{2026} options
provide a similar mechanism that causes the job to fail (instead of being skipped). The failed check is
logged. Units with failed conditions are considered to be in a clean state and will be garbage
collected if they are not referenced. This means that when queried, the condition failure may or may
not show up in the state of the unit.

Note that neither assertion nor condition expressions result in unit state changes. Also note
that both are checked at the time the job is to be executed, i.e. long after depending jobs and it
itself were queued. Thus, neither condition nor assertion expressions are suitable for conditionalizing
unit dependencies.

The condition verb of
L<systemd-analyze(1)> can
be used to test condition and assert expressions.

Except for C<ConditionPathIsSymbolicLink>, all path checks follow symlinks.
This configuration class was generated from systemd documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>
",
    'copyright' => [
      '2010-2016 Lennart Poettering and others',
      '2016 Dominique Dumont'
    ],
    'element' => [
      'Description',
      {
        'description' => 'A human readable name for the unit. This is used by
systemd (and other UIs) as the label for the unit, so this string should
identify the unit rather than describe it, despite the name. C<Apache2 Web
Server> is a good example. Bad examples are C<high-performance light-weight
HTTP server> (too generic) or C<Apache2> (too specific and
meaningless for people who do not know Apache). systemd will use this
string as a noun in status messages (C<Starting
description...>, C<Started
description.>, C<Reached target
description.>, C<Failed to start
description.>), so it should be capitalized, and should
not be a full sentence or a phrase with a continuous verb. Bad examples include
C<exiting the container> or C<updating the database once per
day.>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Documentation',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'A space-separated list of URIs referencing
documentation for this unit or its configuration. Accepted are
only URIs of the types C<http://>,
C<https://>, C<file:>,
C<info:>, C<man:>. For more
information about the syntax of these URIs, see L<uri(7)>.
The URIs should be listed in order of relevance, starting with
the most relevant. It is a good idea to first reference
documentation that explains what the unit\'s purpose is,
followed by how it is configured, followed by any other
related documentation. This option may be specified more than
once, in which case the specified list of URIs is merged. If
the empty string is assigned to this option, the list is reset
and all prior assignments will have no
effect.',
        'type' => 'list'
      },
      'Wants',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Configures requirement dependencies on other units. This option may be specified more
than once or multiple space-separated units may be specified in one option in which case dependencies
for all listed names will be created. Dependencies of this type may also be configured outside of the
unit configuration file by adding a symlink to a C<.wants/> directory accompanying
the unit file. For details, see above.

Units listed in this option will be started if the configuring unit is. However, if the listed
units fail to start or cannot be added to the transaction, this has no impact on the validity of the
transaction as a whole, and this unit will still be started. This is the recommended way to hook
the start-up of one unit to the start-up of another unit.

Note that requirement dependencies do not influence the order in which services are started or
stopped. This has to be configured independently with the C<After> or
C<Before> options. If unit C<foo.service> pulls in unit
C<bar.service> as configured with C<Wants> and no ordering is
configured with C<After> or C<Before>, then both units will be
started simultaneously and without any delay between them if C<foo.service> is
activated.',
        'type' => 'list'
      },
      'Requires',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Similar to C<Wants>, but declares a stronger
dependency. Dependencies of this type may also be configured by adding a symlink to a
C<.requires/> directory accompanying the unit file.

If this unit gets activated, the units listed will be activated as well. If one of
the other units fails to activate, and an ordering dependency C<After> on the
failing unit is set, this unit will not be started. Besides, with or without specifying
C<After>, this unit will be stopped if one of the other units is explicitly
stopped.

Often, it is a better choice to use C<Wants> instead of
C<Requires> in order to achieve a system that is more robust when dealing with
failing services.

Note that this dependency type does not imply that the other unit always has to be in active state when
this unit is running. Specifically: failing condition checks (such as C<ConditionPathExists>,
C<ConditionPathIsSymbolicLink>, \x{2026} \x{2014} see below) do not cause the start job of a unit with a
C<Requires> dependency on it to fail. Also, some unit types may deactivate on their own (for
example, a service process may decide to exit cleanly, or a device may be unplugged by the user), which is not
propagated to units having a C<Requires> dependency. Use the C<BindsTo>
dependency type together with C<After> to ensure that a unit may never be in active state
without a specific other unit also in active state (see below).",
        'type' => 'list'
      },
      'Requisite',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Similar to C<Requires>. However, if the units listed here
are not started already, they will not be started and the starting of this unit will fail
immediately. C<Requisite> does not imply an ordering dependency, even if
both units are started in the same transaction. Hence this setting should usually be
combined with C<After>, to ensure this unit is not started before the other
unit.

When C<Requisite=b.service> is used on
C<a.service>, this dependency will show as
C<RequisiteOf=a.service> in property listing of
C<b.service>. C<RequisiteOf>
dependency cannot be specified directly.',
        'type' => 'list'
      },
      'BindsTo',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Configures requirement dependencies, very similar in style to
C<Requires>. However, this dependency type is stronger: in addition to the effect of
C<Requires> it declares that if the unit bound to is stopped, this unit will be stopped
too. This means a unit bound to another unit that suddenly enters inactive state will be stopped too.
Units can suddenly, unexpectedly enter inactive state for different reasons: the main process of a service unit
might terminate on its own choice, the backing device of a device unit might be unplugged or the mount point of
a mount unit might be unmounted without involvement of the system and service manager.

When used in conjunction with C<After> on the same unit the behaviour of
C<BindsTo> is even stronger. In this case, the unit bound to strictly has to be in active
state for this unit to also be in active state. This not only means a unit bound to another unit that suddenly
enters inactive state, but also one that is bound to another unit that gets skipped due to a failed condition
check (such as C<ConditionPathExists>, C<ConditionPathIsSymbolicLink>, \x{2026} \x{2014}
see below) will be stopped, should it be running. Hence, in many cases it is best to combine
C<BindsTo> with C<After>.

When C<BindsTo=b.service> is used on
C<a.service>, this dependency will show as
C<BoundBy=a.service> in property listing of
C<b.service>. C<BoundBy>
dependency cannot be specified directly.",
        'type' => 'list'
      },
      'PartOf',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Configures dependencies similar to
C<Requires>, but limited to stopping and
restarting of units. When systemd stops or restarts the units
listed here, the action is propagated to this unit. Note that
this is a one-way dependency\x{a0}\x{2014} changes to this unit do not
affect the listed units.

When C<PartOf=b.service> is used on
C<a.service>, this dependency will show as
C<ConsistsOf=a.service> in property listing of
C<b.service>. C<ConsistsOf>
dependency cannot be specified directly.",
        'type' => 'list'
      },
      'Conflicts',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'A space-separated list of unit names. Configures negative requirement
dependencies. If a unit has a C<Conflicts> setting on another unit, starting the
former will stop the latter and vice versa.

Note that this setting does not imply an ordering dependency, similarly to the
C<Wants> and C<Requires> dependencies described above. This means
that to ensure that the conflicting unit is stopped before the other unit is started, an
C<After> or C<Before> dependency must be declared. It doesn\'t
matter which of the two ordering dependencies is used, because stop jobs are always ordered before
start jobs, see the discussion in C<Before>/C<After> below.

If unit A that conflicts with unit B is scheduled to
be started at the same time as B, the transaction will either
fail (in case both are required parts of the transaction) or be
modified to be fixed (in case one or both jobs are not a
required part of the transaction). In the latter case, the job
that is not required will be removed, or in case both are
not required, the unit that conflicts will be started and the
unit that is conflicted is stopped.',
        'type' => 'list'
      },
      'Before',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'These two settings expect a space-separated list of unit names. They may be specified
more than once, in which case dependencies for all listed names are created.

Those two settings configure ordering dependencies between units. If unit
C<foo.service> contains the setting C<Before=bar.service> and both
units are being started, C<bar.service>\'s start-up is delayed until
C<foo.service> has finished starting up. C<After> is the inverse
of C<Before>, i.e. while C<Before> ensures that the configured unit
is started before the listed unit begins starting up, C<After> ensures the opposite,
that the listed unit is fully started up before the configured unit is started.

When two units with an ordering dependency between them are shut down, the inverse of the
start-up order is applied. I.e. if a unit is configured with C<After> on another
unit, the former is stopped before the latter if both are shut down. Given two units with any
ordering dependency between them, if one unit is shut down and the other is started up, the shutdown
is ordered before the start-up. It doesn\'t matter if the ordering dependency is
C<After> or C<Before>, in this case. It also doesn\'t matter which
of the two is shut down, as long as one is shut down and the other is started up; the shutdown is
ordered before the start-up in all cases. If two units have no ordering dependencies between them,
they are shut down or started up simultaneously, and no ordering takes place. It depends on the unit
type when precisely a unit has finished starting up. Most importantly, for service units start-up is
considered completed for the purpose of C<Before>/C<After> when all
its configured start-up commands have been invoked and they either failed or reported start-up
success. Note that this does includes C<ExecStartPost> (or
C<ExecStopPost> for the shutdown case).

Note that those settings are independent of and orthogonal to the requirement dependencies as
configured by C<Requires>, C<Wants>, C<Requisite>,
or C<BindsTo>. It is a common pattern to include a unit name in both the
C<After> and C<Wants> options, in which case the unit listed will
be started before the unit that is configured with these options.

Note that C<Before> dependencies on device units have no effect and are not
supported.  Devices generally become available as a result of an external hotplug event, and systemd
creates the corresponding device unit without delay.',
        'type' => 'list'
      },
      'After',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'These two settings expect a space-separated list of unit names. They may be specified
more than once, in which case dependencies for all listed names are created.

Those two settings configure ordering dependencies between units. If unit
C<foo.service> contains the setting C<Before=bar.service> and both
units are being started, C<bar.service>\'s start-up is delayed until
C<foo.service> has finished starting up. C<After> is the inverse
of C<Before>, i.e. while C<Before> ensures that the configured unit
is started before the listed unit begins starting up, C<After> ensures the opposite,
that the listed unit is fully started up before the configured unit is started.

When two units with an ordering dependency between them are shut down, the inverse of the
start-up order is applied. I.e. if a unit is configured with C<After> on another
unit, the former is stopped before the latter if both are shut down. Given two units with any
ordering dependency between them, if one unit is shut down and the other is started up, the shutdown
is ordered before the start-up. It doesn\'t matter if the ordering dependency is
C<After> or C<Before>, in this case. It also doesn\'t matter which
of the two is shut down, as long as one is shut down and the other is started up; the shutdown is
ordered before the start-up in all cases. If two units have no ordering dependencies between them,
they are shut down or started up simultaneously, and no ordering takes place. It depends on the unit
type when precisely a unit has finished starting up. Most importantly, for service units start-up is
considered completed for the purpose of C<Before>/C<After> when all
its configured start-up commands have been invoked and they either failed or reported start-up
success. Note that this does includes C<ExecStartPost> (or
C<ExecStopPost> for the shutdown case).

Note that those settings are independent of and orthogonal to the requirement dependencies as
configured by C<Requires>, C<Wants>, C<Requisite>,
or C<BindsTo>. It is a common pattern to include a unit name in both the
C<After> and C<Wants> options, in which case the unit listed will
be started before the unit that is configured with these options.

Note that C<Before> dependencies on device units have no effect and are not
supported.  Devices generally become available as a result of an external hotplug event, and systemd
creates the corresponding device unit without delay.',
        'type' => 'list'
      },
      'OnFailure',
      {
        'description' => 'A space-separated list of one or more units
that are activated when this unit enters the
C<failed> state.  A service unit using
C<Restart> enters the failed state only after
the start limits are reached.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PropagatesReloadTo',
      {
        'description' => 'A space-separated list of one or more units
where reload requests on this unit will be propagated to, or
reload requests on the other unit will be propagated to this
unit, respectively. Issuing a reload request on a unit will
automatically also enqueue a reload request on all units that
the reload request shall be propagated to via these two
settings.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ReloadPropagatedFrom',
      {
        'description' => 'A space-separated list of one or more units
where reload requests on this unit will be propagated to, or
reload requests on the other unit will be propagated to this
unit, respectively. Issuing a reload request on a unit will
automatically also enqueue a reload request on all units that
the reload request shall be propagated to via these two
settings.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'JoinsNamespaceOf',
      {
        'description' => 'For units that start processes (such as service units), lists one or more other units
whose network and/or temporary file namespace to join. This only applies to unit types which support
the C<PrivateNetwork>, C<NetworkNamespacePath> and
C<PrivateTmp> directives (see
L<systemd.exec(5)> for
details). If a unit that has this setting set is started, its processes will see the same
C</tmp/>, C</var/tmp/> and network namespace as one listed unit
that is started. If multiple listed units are already started, it is not defined which namespace is
joined. Note that this setting only has an effect if
C<PrivateNetwork>/C<NetworkNamespacePath> and/or
C<PrivateTmp> is enabled for both the unit that joins the namespace and the unit
whose namespace is joined.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RequiresMountsFor',
      {
        'description' => 'Takes a space-separated list of absolute
paths. Automatically adds dependencies of type
C<Requires> and C<After> for
all mount units required to access the specified path.

Mount points marked with C<noauto> are not
mounted automatically through C<local-fs.target>,
but are still honored for the purposes of this option, i.e. they
will be pulled in by this unit.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'OnFailureJobMode',
      {
        'description' => 'Takes a value of
C<fail>,
C<replace>,
C<replace-irreversibly>,
C<isolate>,
C<flush>,
C<ignore-dependencies> or
C<ignore-requirements>. Defaults to
C<replace>. Specifies how the units listed in
C<OnFailure> will be enqueued. See
L<systemctl(1)>\'s
C<--job-mode=> option for details on the
possible values. If this is set to C<isolate>,
only a single unit may be listed in
C<OnFailure>.',
        'migrate_from' => {
          'formula' => '$unit',
          'variables' => {
            'unit' => '- OnFailureIsolate'
          }
        },
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IgnoreOnIsolate',
      {
        'description' => 'Takes a boolean argument. If C<true>, this unit will not be stopped
when isolating another unit. Defaults to C<false> for service, target, socket, timer,
and path units, and C<true> for slice, scope, device, swap, mount, and automount
units.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'StopWhenUnneeded',
      {
        'description' => 'Takes a boolean argument. If
C<true>, this unit will be stopped when it is no
longer used. Note that, in order to minimize the work to be
executed, systemd will not stop units by default unless they
are conflicting with other units, or the user explicitly
requested their shut down. If this option is set, a unit will
be automatically cleaned up if no other active unit requires
it. Defaults to C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RefuseManualStart',
      {
        'description' => 'Takes a boolean argument. If
C<true>, this unit can only be activated or
deactivated indirectly. In this case, explicit start-up or
termination requested by the user is denied, however if it is
started or stopped as a dependency of another unit, start-up
or termination will succeed. This is mostly a safety feature
to ensure that the user does not accidentally activate units
that are not intended to be activated explicitly, and not
accidentally deactivate units that are not intended to be
deactivated. These options default to
C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RefuseManualStop',
      {
        'description' => 'Takes a boolean argument. If
C<true>, this unit can only be activated or
deactivated indirectly. In this case, explicit start-up or
termination requested by the user is denied, however if it is
started or stopped as a dependency of another unit, start-up
or termination will succeed. This is mostly a safety feature
to ensure that the user does not accidentally activate units
that are not intended to be activated explicitly, and not
accidentally deactivate units that are not intended to be
deactivated. These options default to
C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'AllowIsolate',
      {
        'description' => 'Takes a boolean argument. If
C<true>, this unit may be used with the
systemctl isolate command. Otherwise, this
will be refused. It probably is a good idea to leave this
disabled except for target units that shall be used similar to
runlevels in SysV init systems, just as a precaution to avoid
unusable system states. This option defaults to
C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'DefaultDependencies',
      {
        'description' => 'Takes a boolean argument. If
C<yes>, (the default), a few default
dependencies will implicitly be created for the unit. The
actual dependencies created depend on the unit type. For
example, for service units, these dependencies ensure that the
service is started only after basic system initialization is
completed and is properly terminated on system shutdown. See
the respective man pages for details. Generally, only services
involved with early boot or late shutdown should set this
option to C<no>. It is highly recommended to
leave this option enabled for the majority of common units. If
set to C<no>, this option does not disable
all implicit dependencies, just non-essential
ones.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'CollectMode',
      {
        'choice' => [
          'inactive',
          'inactive-or-failed'
        ],
        'description' => "Tweaks the \"garbage collection\" algorithm for this unit. Takes one of C<inactive>
or C<inactive-or-failed>. If set to C<inactive> the unit will be unloaded if it is
in the C<inactive> state and is not referenced by clients, jobs or other units \x{2014} however it
is not unloaded if it is in the C<failed> state. In C<failed> mode, failed
units are not unloaded until the user invoked systemctl reset-failed on them to reset the
C<failed> state, or an equivalent command. This behaviour is altered if this option is set to
C<inactive-or-failed>: in this case the unit is unloaded even if the unit is in a
C<failed> state, and thus an explicitly resetting of the C<failed> state is
not necessary. Note that if this mode is used unit results (such as exit codes, exit signals, consumed
resources, \x{2026}) are flushed out immediately after the unit completed, except for what is stored in the logging
subsystem. Defaults to C<inactive>.",
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'FailureActionExitStatus',
      {
        'description' => "Controls the exit status to propagate back to an invoking container manager (in case of a
system service) or service manager (in case of a user manager) when the
C<FailureAction>/C<SuccessAction> are set to C<exit> or
C<exit-force> and the action is triggered. By default the exit status of the main process of the
triggering unit (if this applies) is propagated. Takes a value in the range 0\x{2026}255 or the empty string to
request default behaviour.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SuccessActionExitStatus',
      {
        'description' => "Controls the exit status to propagate back to an invoking container manager (in case of a
system service) or service manager (in case of a user manager) when the
C<FailureAction>/C<SuccessAction> are set to C<exit> or
C<exit-force> and the action is triggered. By default the exit status of the main process of the
triggering unit (if this applies) is propagated. Takes a value in the range 0\x{2026}255 or the empty string to
request default behaviour.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'JobTimeoutSec',
      {
        'description' => 'When a job for this unit is queued, a timeout C<JobTimeoutSec> may be
configured. Similarly, C<JobRunningTimeoutSec> starts counting when the queued job is actually
started. If either time limit is reached, the job will be cancelled, the unit however will not change state or
even enter the C<failed> mode. This value defaults to C<infinity> (job timeouts
disabled), except for device units (C<JobRunningTimeoutSec> defaults to
C<DefaultTimeoutStartSec>). NB: this timeout is independent from any unit-specific timeout
(for example, the timeout set with C<TimeoutStartSec> in service units) as the job timeout has
no effect on the unit itself, only on the job that might be pending for it. Or in other words: unit-specific
timeouts are useful to abort unit state changes, and revert them. The job timeout set with this option however
is useful to abort only the job waiting for the unit state to change.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'JobRunningTimeoutSec',
      {
        'description' => 'When a job for this unit is queued, a timeout C<JobTimeoutSec> may be
configured. Similarly, C<JobRunningTimeoutSec> starts counting when the queued job is actually
started. If either time limit is reached, the job will be cancelled, the unit however will not change state or
even enter the C<failed> mode. This value defaults to C<infinity> (job timeouts
disabled), except for device units (C<JobRunningTimeoutSec> defaults to
C<DefaultTimeoutStartSec>). NB: this timeout is independent from any unit-specific timeout
(for example, the timeout set with C<TimeoutStartSec> in service units) as the job timeout has
no effect on the unit itself, only on the job that might be pending for it. Or in other words: unit-specific
timeouts are useful to abort unit state changes, and revert them. The job timeout set with this option however
is useful to abort only the job waiting for the unit state to change.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'JobTimeoutAction',
      {
        'description' => 'C<JobTimeoutAction> optionally configures an additional action to take when
the timeout is hit, see description of C<JobTimeoutSec> and
C<JobRunningTimeoutSec> above. It takes the same values as
C<StartLimitAction>. Defaults to C<none>.
C<JobTimeoutRebootArgument> configures an optional reboot string to pass to the
L<reboot(2)> system call.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'JobTimeoutRebootArgument',
      {
        'description' => 'C<JobTimeoutAction> optionally configures an additional action to take when
the timeout is hit, see description of C<JobTimeoutSec> and
C<JobRunningTimeoutSec> above. It takes the same values as
C<StartLimitAction>. Defaults to C<none>.
C<JobTimeoutRebootArgument> configures an optional reboot string to pass to the
L<reboot(2)> system call.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartLimitAction',
      {
        'choice' => [
          'none',
          'reboot',
          'reboot-force',
          'reboot-immediate',
          'poweroff',
          'poweroff-force',
          'poweroff-immediate',
          'exit',
          'exit-force'
        ],
        'description' => 'Configure an additional action to take if the rate limit configured with
C<StartLimitIntervalSec> and C<StartLimitBurst> is hit. Takes the same
values as the C<FailureAction>/C<SuccessAction> settings. If
C<none> is set, hitting the rate limit will trigger no action except that
the start will not be permitted. Defaults to C<none>.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'SourcePath',
      {
        'description' => 'A path to a configuration file this unit has
been generated from. This is primarily useful for
implementation of generator tools that convert configuration
from an external configuration file format into native unit
files. This functionality should not be used in normal
units.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ConditionArchitecture',
      {
        'cargo' => {
          'choice' => [
            'x86',
            'x86-64',
            'ppc',
            'ppc-le',
            'ppc64',
            'ppc64-le',
            'ia64',
            'parisc',
            'parisc64',
            's390',
            's390x',
            'sparc',
            'sparc64',
            'mips',
            'mips-le',
            'mips64',
            'mips64-le',
            'alpha',
            'arm',
            'arm-be',
            'arm64',
            'arm64-be',
            'sh',
            'sh64',
            'm68k',
            'tilegx',
            'cris',
            'arc',
            'arc-be',
            'native'
          ],
          'type' => 'leaf',
          'value_type' => 'enum'
        },
        'description' => 'Check whether the system is running on a specific architecture. Takes one of
C<x86>,
C<x86-64>,
C<ppc>,
C<ppc-le>,
C<ppc64>,
C<ppc64-le>,
C<ia64>,
C<parisc>,
C<parisc64>,
C<s390>,
C<s390x>,
C<sparc>,
C<sparc64>,
C<mips>,
C<mips-le>,
C<mips64>,
C<mips64-le>,
C<alpha>,
C<arm>,
C<arm-be>,
C<arm64>,
C<arm64-be>,
C<sh>,
C<sh64>,
C<m68k>,
C<tilegx>,
C<cris>,
C<arc>,
C<arc-be>, or
C<native>.

The architecture is determined from the information returned by
L<uname(2)>
and is thus subject to
L<personality(2)>.
Note that a C<Personality> setting in the same unit file has no effect on this
condition. A special architecture name C<native> is mapped to the architecture the
system manager itself is compiled for. The test may be negated by prepending an exclamation
mark.',
        'type' => 'list'
      },
      'ConditionVirtualization',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Check whether the system is executed in a virtualized environment and optionally
test whether it is a specific implementation. Takes either boolean value to check if being executed
in any virtualized environment, or one of
C<vm> and
C<container> to test against a generic type of virtualization solution, or one of
C<qemu>,
C<kvm>,
C<zvm>,
C<vmware>,
C<microsoft>,
C<oracle>,
C<powervm>,
C<xen>,
C<bochs>,
C<uml>,
C<bhyve>,
C<qnx>,
C<openvz>,
C<lxc>,
C<lxc-libvirt>,
C<systemd-nspawn>,
C<docker>,
C<podman>,
C<rkt>,
C<wsl>,
C<proot>,
C<pouch>,
C<acrn> to test
against a specific implementation, or
C<private-users> to check whether we are running in a user namespace. See
L<systemd-detect-virt(1)>
for a full list of known virtualization technologies and their identifiers. If multiple
virtualization technologies are nested, only the innermost is considered. The test may be negated
by prepending an exclamation mark.',
        'type' => 'list'
      },
      'ConditionHost',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionHost> may be used to match against the hostname or
machine ID of the host. This either takes a hostname string (optionally with shell style globs)
which is tested against the locally set hostname as returned by
L<gethostname(2)>, or
a machine ID formatted as string (see
L<machine-id(5)>).
The test may be negated by prepending an exclamation mark.',
        'type' => 'list'
      },
      'ConditionKernelCommandLine',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "C<ConditionKernelCommandLine> may be used to check whether a
specific kernel command line option is set (or if prefixed with the exclamation mark \x{2014} unset). The
argument must either be a single word, or an assignment (i.e. two words, separated by
C<=>). In the former case the kernel command line is searched for the word
appearing as is, or as left hand side of an assignment. In the latter case, the exact assignment is
looked for with right and left hand side matching. This operates on the kernel command line
communicated to userspace via C</proc/cmdline>, except when the service manager
is invoked as payload of a container manager, in which case the command line of C<PID
1> is used instead (i.e. C</proc/1/cmdline>).",
        'type' => 'list'
      },
      'ConditionKernelVersion',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionKernelVersion> may be used to check whether the kernel
version (as reported by uname -r) matches a certain expression (or if prefixed
with the exclamation mark does not match it). The argument must be a list of (potentially quoted)
expressions.  For each of the expressions, if it starts with one of C<<>,
C<<=>, C<=>, C<!=>, C<>=>,
C<>> a relative version comparison is done, otherwise the specified string is
matched with shell-style globs.

Note that using the kernel version string is an unreliable way to determine which features
are supported by a kernel, because of the widespread practice of backporting drivers, features, and
fixes from newer upstream kernels into older versions provided by distributions. Hence, this check
is inherently unportable and should not be used for units which may be used on different
distributions.',
        'type' => 'list'
      },
      'ConditionEnvironment',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "C<ConditionEnvironment> may be used to check whether a specific
environment variable is set (or if prefixed with the exclamation mark \x{2014} unset) in the service
manager's environment block.
The argument may be a single word, to check if the variable with this name is defined in the
environment block, or an assignment
(C<name=value>), to check if
the variable with this exact value is defined. Note that the environment block of the service
manager itself is checked, i.e. not any variables defined with C<Environment> or
C<EnvironmentFile>, as described above. This is particularly useful when the
service manager runs inside a containerized environment or as per-user service manager, in order to
check for variables passed in by the enclosing container manager or PAM.",
        'type' => 'list'
      },
      'ConditionSecurity',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionSecurity> may be used to check whether the given
security technology is enabled on the system. Currently, the recognized values are
C<selinux>, C<apparmor>, C<tomoyo>,
C<ima>, C<smack>, C<audit> and
C<uefi-secureboot>. The test may be negated by prepending an exclamation
mark.',
        'type' => 'list'
      },
      'ConditionCapability',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Check whether the given capability exists in the capability bounding set of the
service manager (i.e. this does not check whether capability is actually available in the permitted
or effective sets, see
L<capabilities(7)>
for details). Pass a capability name such as C<CAP_MKNOD>, possibly prefixed with
an exclamation mark to negate the check.',
        'type' => 'list'
      },
      'ConditionACPower',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Check whether the system has AC power, or is exclusively battery powered at the
time of activation of the unit. This takes a boolean argument. If set to C<true>,
the condition will hold only if at least one AC connector of the system is connected to a power
source, or if no AC connectors are known. Conversely, if set to C<false>, the
condition will hold only if there is at least one AC connector known and all AC connectors are
disconnected from a power source.',
        'type' => 'list'
      },
      'ConditionNeedsUpdate',
      {
        'cargo' => {
          'choice' => [
            '/var/',
            '/etc/',
            '!/var/',
            '!/etc/'
          ],
          'type' => 'leaf',
          'value_type' => 'enum'
        },
        'description' => 'Takes one of C</var/> or C</etc/> as argument,
possibly prefixed with a C<!> (to invert the condition). This condition may be
used to conditionalize units on whether the specified directory requires an update because
C</usr/>\'s modification time is newer than the stamp file
C<.updated> in the specified directory. This is useful to implement offline
updates of the vendor operating system resources in C</usr/> that require updating
of C</etc/> or C</var/> on the next following boot. Units making
use of this condition should order themselves before
L<systemd-update-done.service(8)>,
to make sure they run before the stamp file\'s modification time gets reset indicating a completed
update.

If the C<systemd.condition-needs-update=> option is specified on the kernel
command line (taking a boolean), it will override the result of this condition check, taking
precedence over any file modification time checks. If it is used
C<systemd-update-done.service> will not have immediate effect on any following
C<ConditionNeedsUpdate> checks, until the system is rebooted where the kernel
command line option is not specified anymore.',
        'type' => 'list'
      },
      'ConditionFirstBoot',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'boolean',
          'write_as' => [
            'no',
            'yes'
          ]
        },
        'description' => 'Takes a boolean argument. This condition may be used to conditionalize units on
whether the system is booting up for the first time.  This roughly means that C</etc/>
is unpopulated (for details, see "First Boot Semantics" in
L<machine-id(5)>).
This may be used to populate C</etc/> on the first boot after factory reset, or
when a new system instance boots up for the first time.

For robustness, units with C<ConditionFirstBoot=yes> should order themselves
before C<first-boot-complete.target> and pull in this passive target with
C<Wants>.  This ensures that in a case of an aborted first boot, these units will
be re-run during the next system startup.

If the C<systemd.condition-first-boot=> option is specified on the kernel
command line (taking a boolean), it will override the result of this condition check, taking
precedence over C</etc/machine-id> existence checks.',
        'type' => 'list'
      },
      'ConditionPathExists',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Check for the exists of a file. If the specified absolute path name does not exist,
the condition will fail. If the absolute path name passed to
C<ConditionPathExists> is prefixed with an exclamation mark
(C<!>), the test is negated, and the unit is only started if the path does not
exist.',
        'type' => 'list'
      },
      'ConditionPathExistsGlob',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionPathExistsGlob> is similar to
C<ConditionPathExists>, but checks for the existence of at least one file or
directory matching the specified globbing pattern.',
        'type' => 'list'
      },
      'ConditionPathIsDirectory',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionPathIsDirectory> is similar to
C<ConditionPathExists> but verifies that a certain path exists and is a
directory.',
        'type' => 'list'
      },
      'ConditionPathIsSymbolicLink',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionPathIsSymbolicLink> is similar to
C<ConditionPathExists> but verifies that a certain path exists and is a symbolic
link.',
        'type' => 'list'
      },
      'ConditionPathIsMountPoint',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionPathIsMountPoint> is similar to
C<ConditionPathExists> but verifies that a certain path exists and is a mount
point.',
        'type' => 'list'
      },
      'ConditionPathIsReadWrite',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionPathIsReadWrite> is similar to
C<ConditionPathExists> but verifies that the underlying file system is readable
and writable (i.e. not mounted read-only).',
        'type' => 'list'
      },
      'ConditionPathIsEncrypted',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionPathIsEncrypted> is similar to
C<ConditionPathExists> but verifies that the underlying file system\'s backing
block device is encrypted using dm-crypt/LUKS. Note that this check does not cover ext4
per-directory encryption, and only detects block level encryption. Moreover, if the specified path
resides on a file system on top of a loopback block device, only encryption above the loopback device is
detected. It is not detected whether the file system backing the loopback block device is encrypted.',
        'type' => 'list'
      },
      'ConditionDirectoryNotEmpty',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionDirectoryNotEmpty> is similar to
C<ConditionPathExists> but verifies that a certain path exists and is a non-empty
directory.',
        'type' => 'list'
      },
      'ConditionFileNotEmpty',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionFileNotEmpty> is similar to
C<ConditionPathExists> but verifies that a certain path exists and refers to a
regular file with a non-zero size.',
        'type' => 'list'
      },
      'ConditionFileIsExecutable',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionFileIsExecutable> is similar to
C<ConditionPathExists> but verifies that a certain path exists, is a regular file,
and marked executable.',
        'type' => 'list'
      },
      'ConditionUser',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionUser> takes a numeric C<UID>, a UNIX
user name, or the special value C<@system>. This condition may be used to check
whether the service manager is running as the given user. The special value
C<@system> can be used to check if the user id is within the system user
range. This option is not useful for system services, as the system manager exclusively runs as the
root user, and thus the test result is constant.',
        'type' => 'list'
      },
      'ConditionGroup',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'C<ConditionGroup> is similar to C<ConditionUser>
but verifies that the service manager\'s real or effective group, or any of its auxiliary groups,
match the specified group or GID. This setting does not support the special value
C<@system>.',
        'type' => 'list'
      },
      'ConditionControlGroupController',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Verify that the given cgroup controller (eg. C<cpu>) is available
for use on the system. For example, a particular controller may not be available if it was disabled
on the kernel command line with C<cgroup_disable=controller>. Multiple controllers
may be passed with a space separating them; in this case the condition will only pass if all listed
controllers are available for use. Controllers unknown to systemd are ignored. Valid controllers
are C<cpu>, C<cpuacct>, C<io>,
C<blkio>, C<memory>, C<devices>, and
C<pids>.',
        'type' => 'list'
      },
      'ConditionMemory',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Verify that the specified amount of system memory is available to the current
system. Takes a memory size in bytes as argument, optionally prefixed with a comparison operator
C<<>, C<<=>, C<=>, C<!=>,
C<>=>, C<>>. On bare-metal systems compares the amount of
physical memory in the system with the specified size, adhering to the specified comparison
operator. In containers compares the amount of memory assigned to the container instead.',
        'type' => 'list'
      },
      'ConditionCPUs',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Verify that the specified number of CPUs is available to the current system. Takes
a number of CPUs as argument, optionally prefixed with a comparison operator
C<<>, C<<=>, C<=>, C<!=>,
C<>=>, C<>>. Compares the number of CPUs in the CPU affinity
mask configured of the service manager itself with the specified number, adhering to the specified
comparison operator. On physical systems the number of CPUs in the affinity mask of the service
manager usually matches the number of physical CPUs, but in special and virtual environments might
differ. In particular, in containers the affinity mask usually matches the number of CPUs assigned
to the container and not the physically available ones.',
        'type' => 'list'
      },
      'AssertArchitecture',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertVirtualization',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertHost',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertKernelCommandLine',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertKernelVersion',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertSecurity',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertCapability',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertACPower',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertNeedsUpdate',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertFirstBoot',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathExists',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathExistsGlob',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsDirectory',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsSymbolicLink',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsMountPoint',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsReadWrite',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertDirectoryNotEmpty',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertFileNotEmpty',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertFileIsExecutable',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertUser',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertGroup',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertControlGroupController',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings
add assertion checks to the start-up of the unit. However, unlike the conditions settings, any
assertion setting that is not met results in failure of the start job (which means this is logged
loudly). Note that hitting a configured assertion does not cause the unit to enter the
C<failed> state (or in fact result in any state change of the unit), it affects
only the job queued for it. Use assertion expressions for units that cannot operate when specific
requirements are not met, and when this is something the administrator or user should look
into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartLimitInterval',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'StartLimitInterval is now StartLimitIntervalSec.'
      },
      'OnFailureIsolate',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'OnFailureIsolate is now OnFailureJobMode.'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd 247 doc',
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Section::Unit'
  }
]
;


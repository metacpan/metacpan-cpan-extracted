#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2016 by Dominique Dumont.
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
        'value_type' => 'uniline',
        'warn' => 'Unknown parameter'
      }
    ],
    'class_description' => "A unit configuration file encodes information about a
service, a socket, a device, a mount point, an automount point, a
swap file or partition, a start-up target, a watched file system
path, a timer controlled and supervised by
L<systemd(1)>,
a resource management slice or
a group of externally created processes. The syntax is inspired by
XDG
Desktop Entry Specification .desktop
files, which are in turn inspired by Microsoft Windows
.ini files.

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


Various settings are allowed to be specified more than once,
in which case the interpretation depends on the setting. Often,
multiple settings form a list, and setting to an empty value
\"resets\", which means that previous assignments are ignored. When
this is allowed, it is mentioned in the description of the
setting. Note that using multiple assignments to the same value
makes the unit file incompatible with parsers for the XDG
.desktop file format.

Unit files are loaded from a set of paths determined during
compilation, described in the next section.

Unit files may contain additional options on top of those
listed here. If systemd encounters an unknown option, it will
write a warning log message but continue loading the unit. If an
option or section name is prefixed with C<X->, it is
ignored completely by systemd. Options within an ignored section
do not need the prefix. Applications may use this to include
additional information in the unit files.

Boolean arguments used in unit files can be written in
various formats. For positive settings the strings
C<1>, C<yes>, C<true>
and C<on> are equivalent. For negative settings, the
strings C<0>, C<no>,
C<false> and C<off> are
equivalent.

Time span values encoded in unit files can be written in various formats. A stand-alone
number specifies a time in seconds.  If suffixed with a time unit, the unit is honored. A
concatenation of multiple values with units is supported, in which case the values are added
up. Example: C<50> refers to 50 seconds; C<2min\x{a0}200ms> refers to
2 minutes and 200 milliseconds, i.e. 120200\x{a0}ms.  The following time units are understood:
C<s>, C<min>, C<h>, C<d>,
C<w>, C<ms>, C<us>.  For details see
L<systemd.time(7)>.

Empty lines and lines starting with C<#> or C<;> are
ignored. This may be used for commenting. Lines ending in a backslash are concatenated with the
following line while reading and the backslash is replaced by a space character. This may be
used to wrap long lines.

Units can be aliased (have an alternative name), by creating a symlink from the new name
to the existing name in one of the unit search paths. For example,
systemd-networkd.service has the alias
dbus-org.freedesktop.network1.service, created during installation as the
symlink /usr/lib/systemd/system/dbus-org.freedesktop.network1.service. In
addition, unit files may specify aliases through the C<Alias> directive in the
[Install] section; those aliases are only effective when the unit is enabled. When the unit is
enabled, symlinks will be created for those names, and removed when the unit is disabled. For
example, reboot.target specifies
C<Alias=ctrl-alt-del.target>, so when enabled it will be invoked whenever
CTRL+ALT+DEL is pressed. Alias names may be used in commands like enable,
disable, start, stop,
status, \x{2026}, and in unit dependency directives C<Wants>,
C<Requires>, C<Before>, C<After>, \x{2026}, with the
limitation that aliases specified through C<Alias> are only effective when the
unit is enabled. Aliases cannot be used with the preset command.

Along with a unit file foo.service, the directory
foo.service.wants/ may exist. All unit files symlinked from such a
directory are implicitly added as dependencies of type C<Wants> to the unit.
This is useful to hook units into the start-up of other units, without having to modify their
unit files. For details about the semantics of C<Wants>, see below. The
preferred way to create symlinks in the .wants/ directory of a unit file is
with the enable command of the
L<systemctl(1)>
tool which reads information from the [Install] section of unit files (see below). A similar
functionality exists for C<Requires> type dependencies as well, the directory
suffix is .requires/ in this case.

Along with a unit file foo.service, a \"drop-in\" directory
foo.service.d/ may exist. All files with the suffix
C<.conf> from this directory will be parsed after the file itself is
parsed. This is useful to alter or add configuration settings for a unit, without having to
modify unit files. Each drop-in file must have appropriate section headers. Note that for
instantiated units, this logic will first look for the instance C<.d/>
subdirectory and read its C<.conf> files, followed by the template
C<.d/> subdirectory and the C<.conf> files there. Also note that
settings from the C<[Install]> section are not honored in drop-in unit files,
and have no effect.

In addition to /etc/systemd/system, the drop-in C<.d>
directories for system services can be placed in /usr/lib/systemd/system or
/run/systemd/system directories. Drop-in files in /etc
take precedence over those in /run which in turn take precedence over those
in /usr/lib. Drop-in files under any of these directories take precedence
over unit files wherever located.

Some unit names reflect paths existing in the file system
namespace. Example: a device unit
dev-sda.device refers to a device with the
device node /dev/sda in the
file system namespace. If this applies, a special way to escape
the path name is used, so that the result is usable as part of a
filename. Basically, given a path, \"/\" is replaced by \"-\", and all
other characters which are not ASCII alphanumerics are replaced by
C-style \"\\x2d\" escapes (except that \"_\" is never replaced and \".\"
is only replaced when it would be the first character in the
escaped path). The root directory \"/\" is encoded as single dash,
while otherwise the initial and ending \"/\" are removed from all
paths during transformation. This escaping is reversible. Properly
escaped paths can be generated using the
L<systemd-escape(1)>
command.

Optionally, units may be instantiated from a
template file at runtime. This allows creation of
multiple units from a single configuration file. If
systemd looks for a unit configuration file, it will
first search for the literal unit name in the
file system. If that yields no success and the unit
name contains an C<\@> character, systemd will look for a
unit template that shares the same name but with the
instance string (i.e. the part between the C<\@> character
and the suffix) removed. Example: if a service
getty\@tty3.service is requested
and no file by that name is found, systemd will look
for getty\@.service and
instantiate a service from that configuration file if
it is found.

To refer to the instance string from within the
configuration file you may use the special C<%i>
specifier in many of the configuration options. See below for
details.

If a unit file is empty (i.e. has the file size 0) or is
symlinked to /dev/null, its configuration
will not be loaded and it appears with a load state of
C<masked>, and cannot be activated. Use this as an
effective way to fully disable a unit, making it impossible to
start it even manually.

The unit file format is covered by the
Interface
Stability Promise.

Additional units might be loaded into systemd (\"linked\")
from directories not on the unit load path. See the
link command for
L<systemctl(1)>.
Also, some units are dynamically created via a
L<systemd.generator(7)>.

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
        'description' => 'A free-form string describing the unit. This
is intended for use in UIs to show descriptive information
along with the unit name. The description should contain a
name that means something to the end user. C<Apache2
Web Server> is a good example. Bad examples are
C<high-performance light-weight HTTP server>
(too generic) or C<Apache2> (too specific and
meaningless for people who do not know
Apache).',
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
      'Requires',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Configures requirement dependencies on other
units. If this unit gets activated, the units listed here will
be activated as well. If one of the other units gets
deactivated or its activation fails, this unit will be
deactivated. This option may be specified more than once or
multiple space-separated units may be specified in one option
in which case requirement dependencies for all listed names
will be created. Note that requirement dependencies do not
influence the order in which services are started or stopped.
This has to be configured independently with the
C<After> or C<Before>
options. If a unit foo.service requires a
unit bar.service as configured with
C<Requires> and no ordering is configured
with C<After> or C<Before>,
then both units will be started simultaneously and without any
delay between them if foo.service is
activated. Often, it is a better choice to use
C<Wants> instead of
C<Requires> in order to achieve a system that
is more robust when dealing with failing services.

Note that dependencies of this type may also be
configured outside of the unit configuration file by adding a
symlink to a .requires/ directory
accompanying the unit file. For details, see
above.',
        'type' => 'list'
      },
      'Requisite',
      {
        'description' => 'Similar to C<Requires>.
However, if the units listed here are not started already,
they will not be started and the transaction will fail
immediately. ',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Wants',
      {
        'description' => 'A weaker version of
C<Requires>. Units listed in this option will
be started if the configuring unit is. However, if the listed
units fail to start or cannot be added to the transaction,
this has no impact on the validity of the transaction as a
whole. This is the recommended way to hook start-up of one
unit to the start-up of another unit.

Note that dependencies of this type may also be
configured outside of the unit configuration file by adding
symlinks to a .wants/ directory
accompanying the unit file. For details, see
above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'BindsTo',
      {
        'description' => 'Configures requirement dependencies, very
similar in style to C<Requires>, however in
addition to this behavior, it also declares that this unit is
stopped when any of the units listed suddenly disappears.
Units can suddenly, unexpectedly disappear if a service
terminates on its own choice, a device is unplugged or a mount
point unmounted without involvement of
systemd.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PartOf',
      {
        'description' => "Configures dependencies similar to
C<Requires>, but limited to stopping and
restarting of units. When systemd stops or restarts the units
listed here, the action is propagated to this unit. Note that
this is a one-way dependency\x{a0}\x{2014} changes to this unit do not
affect the listed units. ",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Conflicts',
      {
        'description' => 'A space-separated list of unit names.
Configures negative requirement dependencies. If a unit has a
C<Conflicts> setting on another unit,
starting the former will stop the latter and vice versa. Note
that this setting is independent of and orthogonal to the
C<After> and C<Before>
ordering dependencies.

If a unit A that conflicts with a unit B is scheduled to
be started at the same time as B, the transaction will either
fail (in case both are required part of the transaction) or be
modified to be fixed (in case one or both jobs are not a
required part of the transaction). In the latter case, the job
that is not the required will be removed, or in case both are
not required, the unit that conflicts will be started and the
unit that is conflicted is stopped.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Before',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'A space-separated list of unit names.
Configures ordering dependencies between units. If a unit
foo.service contains a setting
C<Before=bar.service> and both units are being
started, bar.service\'s start-up is
delayed until foo.service is started up.
Note that this setting is independent of and orthogonal to the
requirement dependencies as configured by
C<Requires>. It is a common pattern to
include a unit name in both the C<After> and
C<Requires> option, in which case the unit
listed will be started before the unit that is configured with
these options. This option may be specified more than once, in
which case ordering dependencies for all listed names are
created. C<After> is the inverse of
C<Before>, i.e. while
C<After> ensures that the configured unit is
started after the listed unit finished starting up,
C<Before> ensures the opposite, i.e. that the
configured unit is fully started up before the listed unit is
started. Note that when two units with an ordering dependency
between them are shut down, the inverse of the start-up order
is applied. i.e. if a unit is configured with
C<After> on another unit, the former is
stopped before the latter if both are shut down. Given two units
with any ordering dependency between them, if one unit is shut
down and the other is started up, the shutdown is ordered
before the start-up. It doesn\'t matter if the ordering
dependency is C<After> or
C<Before>. It also doesn\'t matter which of the
two is shut down, as long as one is shut down and the other is
started up. The shutdown is ordered before the start-up in all
cases. If two units have no ordering dependencies between them,
they are shut down or started up simultaneously, and no ordering
takes place.
',
        'type' => 'list'
      },
      'After',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'A space-separated list of unit names.
Configures ordering dependencies between units. If a unit
foo.service contains a setting
C<Before=bar.service> and both units are being
started, bar.service\'s start-up is
delayed until foo.service is started up.
Note that this setting is independent of and orthogonal to the
requirement dependencies as configured by
C<Requires>. It is a common pattern to
include a unit name in both the C<After> and
C<Requires> option, in which case the unit
listed will be started before the unit that is configured with
these options. This option may be specified more than once, in
which case ordering dependencies for all listed names are
created. C<After> is the inverse of
C<Before>, i.e. while
C<After> ensures that the configured unit is
started after the listed unit finished starting up,
C<Before> ensures the opposite, i.e. that the
configured unit is fully started up before the listed unit is
started. Note that when two units with an ordering dependency
between them are shut down, the inverse of the start-up order
is applied. i.e. if a unit is configured with
C<After> on another unit, the former is
stopped before the latter if both are shut down. Given two units
with any ordering dependency between them, if one unit is shut
down and the other is started up, the shutdown is ordered
before the start-up. It doesn\'t matter if the ordering
dependency is C<After> or
C<Before>. It also doesn\'t matter which of the
two is shut down, as long as one is shut down and the other is
started up. The shutdown is ordered before the start-up in all
cases. If two units have no ordering dependencies between them,
they are shut down or started up simultaneously, and no ordering
takes place.
',
        'type' => 'list'
      },
      'OnFailure',
      {
        'description' => 'A space-separated list of one or more units
that are activated when this unit enters the
C<failed> state.',
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
        'description' => 'For units that start processes (such as
service units), lists one or more other units whose network
and/or temporary file namespace to join. This only applies to
unit types which support the
C<PrivateNetwork> and
C<PrivateTmp> directives (see
L<systemd.exec(5)>
for details). If a unit that has this setting set is started,
its processes will see the same /tmp,
/var/tmp and network namespace as one
listed unit that is started. If multiple listed units are
already started, it is not defined which namespace is joined.
Note that this setting only has an effect if
C<PrivateNetwork> and/or
C<PrivateTmp> is enabled for both the unit
that joins the namespace and the unit whose namespace is
joined.',
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
mounted automatically and will be ignored for the purposes of
this option. If such a mount should be a requirement for this
unit, direct dependencies on the mount units may be added
(C<Requires> and C<After> or
some other combination). ',
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
C<OnFailure>..',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IgnoreOnIsolate',
      {
        'description' => 'Takes a boolean argument. If
C<true>, this unit will not be stopped when
isolating another unit. Defaults to
C<false>.',
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
C<true>, (the default), a few default
dependencies will implicitly be created for the unit. The
actual dependencies created depend on the unit type. For
example, for service units, these dependencies ensure that the
service is started only after basic system initialization is
completed and is properly terminated on system shutdown. See
the respective man pages for details. Generally, only services
involved with early boot or late shutdown should set this
option to C<false>. It is highly recommended to
leave this option enabled for the majority of common units. If
set to C<false>, this option does not disable
all implicit dependencies, just non-essential
ones.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'JobTimeoutSec',
      {
        'description' => 'When a job for this unit is queued, a time-out may be configured. If this time limit is
reached, the job will be cancelled, the unit however will not change state or even enter the
C<failed> mode. This value defaults to C<infinity> (job timeouts disabled),
except for device units. NB: this timeout is independent from any unit-specific timeout (for example, the
timeout set with C<TimeoutStartSec> in service units) as the job timeout has no effect on the
unit itself, only on the job that might be pending for it. Or in other words: unit-specific timeouts are useful
to abort unit state changes, and revert them. The job timeout set with this option however is useful to abort
only the job waiting for the unit state to change.

C<JobTimeoutAction>
optionally configures an additional
action to take when the time-out is
hit. It takes the same values as the
per-service
C<StartLimitAction>
setting, see
L<systemd.service(5)>
for details. Defaults to
C<none>. C<JobTimeoutRebootArgument>
configures an optional reboot string
to pass to the
L<reboot(2)>
system call.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'JobTimeoutAction',
      {
        'description' => 'When a job for this unit is queued, a time-out may be configured. If this time limit is
reached, the job will be cancelled, the unit however will not change state or even enter the
C<failed> mode. This value defaults to C<infinity> (job timeouts disabled),
except for device units. NB: this timeout is independent from any unit-specific timeout (for example, the
timeout set with C<TimeoutStartSec> in service units) as the job timeout has no effect on the
unit itself, only on the job that might be pending for it. Or in other words: unit-specific timeouts are useful
to abort unit state changes, and revert them. The job timeout set with this option however is useful to abort
only the job waiting for the unit state to change.

C<JobTimeoutAction>
optionally configures an additional
action to take when the time-out is
hit. It takes the same values as the
per-service
C<StartLimitAction>
setting, see
L<systemd.service(5)>
for details. Defaults to
C<none>. C<JobTimeoutRebootArgument>
configures an optional reboot string
to pass to the
L<reboot(2)>
system call.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'JobTimeoutRebootArgument',
      {
        'description' => 'When a job for this unit is queued, a time-out may be configured. If this time limit is
reached, the job will be cancelled, the unit however will not change state or even enter the
C<failed> mode. This value defaults to C<infinity> (job timeouts disabled),
except for device units. NB: this timeout is independent from any unit-specific timeout (for example, the
timeout set with C<TimeoutStartSec> in service units) as the job timeout has no effect on the
unit itself, only on the job that might be pending for it. Or in other words: unit-specific timeouts are useful
to abort unit state changes, and revert them. The job timeout set with this option however is useful to abort
only the job waiting for the unit state to change.

C<JobTimeoutAction>
optionally configures an additional
action to take when the time-out is
hit. It takes the same values as the
per-service
C<StartLimitAction>
setting, see
L<systemd.service(5)>
for details. Defaults to
C<none>. C<JobTimeoutRebootArgument>
configures an optional reboot string
to pass to the
L<reboot(2)>
system call.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartLimitIntervalSec',
      {
        'description' => 'Configure unit start rate limiting. By default, units which are started more than 5 times
within 10 seconds are not permitted to start any more times until the 10 second interval ends. With these two
options, this rate limiting may be modified. Use C<StartLimitIntervalSec> to configure the
checking interval (defaults to C<DefaultStartLimitIntervalSec> in manager configuration file,
set to 0 to disable any kind of rate limiting). Use C<StartLimitBurst> to configure how many
starts per interval are allowed (defaults to C<DefaultStartLimitBurst> in manager
configuration file). These configuration options are particularly useful in conjunction with the service
setting C<Restart> (see
L<systemd.service(5)>); however,
they apply to all kinds of starts (including manual), not just those triggered by the
C<Restart> logic. Note that units which are configured for C<Restart> and
which reach the start limit are not attempted to be restarted anymore; however, they may still be restarted
manually at a later point, from which point on, the restart logic is again activated. Note that
systemctl reset-failed will cause the restart rate counter for a service to be flushed,
which is useful if the administrator wants to manually start a unit and the start limit interferes with
that. Note that this rate-limiting is enforced after any unit condition checks are executed, and hence unit
activations with failing conditions are not counted by this rate limiting. Slice, target, device and scope
units do not enforce this setting, as they are unit types whose activation may either never fail, or may
succeed only a single time.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartLimitBurst',
      {
        'description' => 'Configure unit start rate limiting. By default, units which are started more than 5 times
within 10 seconds are not permitted to start any more times until the 10 second interval ends. With these two
options, this rate limiting may be modified. Use C<StartLimitIntervalSec> to configure the
checking interval (defaults to C<DefaultStartLimitIntervalSec> in manager configuration file,
set to 0 to disable any kind of rate limiting). Use C<StartLimitBurst> to configure how many
starts per interval are allowed (defaults to C<DefaultStartLimitBurst> in manager
configuration file). These configuration options are particularly useful in conjunction with the service
setting C<Restart> (see
L<systemd.service(5)>); however,
they apply to all kinds of starts (including manual), not just those triggered by the
C<Restart> logic. Note that units which are configured for C<Restart> and
which reach the start limit are not attempted to be restarted anymore; however, they may still be restarted
manually at a later point, from which point on, the restart logic is again activated. Note that
systemctl reset-failed will cause the restart rate counter for a service to be flushed,
which is useful if the administrator wants to manually start a unit and the start limit interferes with
that. Note that this rate-limiting is enforced after any unit condition checks are executed, and hence unit
activations with failing conditions are not counted by this rate limiting. Slice, target, device and scope
units do not enforce this setting, as they are unit types whose activation may either never fail, or may
succeed only a single time.',
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
          'poweroff-immediate'
        ],
        'description' => 'Configure the action to take if the rate limit configured with
C<StartLimitIntervalSec> and C<StartLimitBurst> is hit. Takes one of
C<none>, C<reboot>, C<reboot-force>,
C<reboot-immediate>, C<poweroff>, C<poweroff-force> or
C<poweroff-immediate>. If C<none> is set, hitting the rate limit will trigger no
action besides that the start will not be permitted. C<reboot> causes a reboot following the
normal shutdown procedure (i.e. equivalent to systemctl reboot).
C<reboot-force> causes a forced reboot which will terminate all processes forcibly but should
cause no dirty file systems on reboot (i.e. equivalent to systemctl reboot -f) and
C<reboot-immediate> causes immediate execution of the
L<reboot(2)> system call, which
might result in data loss. Similarly, C<poweroff>, C<poweroff-force>,
C<poweroff-immediate> have the effect of powering down the system with similar
semantics. Defaults to C<none>.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'RebootArgument',
      {
        'description' => 'Configure the optional argument for the
L<reboot(2)> system call if
C<StartLimitAction> or a service\'s C<FailureAction> is a reboot action. This
works just like the optional argument to systemctl reboot command.',
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
            'm86k',
            'tilegx',
            'cris'
          ],
          'type' => 'leaf',
          'value_type' => 'enum'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionArchitecture=> may be used to
check whether the system is running on a specific
architecture. Takes one of
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
C<m86k>,
C<tilegx>,
C<cris> to test
against a specific architecture. The architecture is
determined from the information returned by
L<uname(2)>
and is thus subject to
L<personality(2)>.
Note that a C<Personality=> setting in the
same unit file has no effect on this condition. A special
architecture name C<native> is mapped to the
architecture the system manager itself is compiled for. The
test may be negated by prepending an exclamation mark.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionVirtualization',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionVirtualization=> may be used
to check whether the system is executed in a virtualized
environment and optionally test whether it is a specific
implementation. Takes either boolean value to check if being
executed in any virtualized environment, or one of
C<vm> and
C<container> to test against a generic type of
virtualization solution, or one of
C<qemu>,
C<kvm>,
C<zvm>,
C<vmware>,
C<microsoft>,
C<oracle>,
C<xen>,
C<bochs>,
C<uml>,
C<openvz>,
C<lxc>,
C<lxc-libvirt>,
C<systemd-nspawn>,
C<docker>,
C<rkt> to test
against a specific implementation, or
C<private-users> to check whether we are running in a user namespace. See
L<systemd-detect-virt(1)>
for a full list of known virtualization technologies and their
identifiers. If multiple virtualization technologies are
nested, only the innermost is considered. The test may be
negated by prepending an exclamation mark.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionHost',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionHost=> may be used to match
against the hostname or machine ID of the host. This either
takes a hostname string (optionally with shell style globs)
which is tested against the locally set hostname as returned
by
L<gethostname(2)>,
or a machine ID formatted as string (see
L<machine-id(5)>).
The test may be negated by prepending an exclamation
mark.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionKernelCommandLine',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionKernelCommandLine=> may be
used to check whether a specific kernel command line option is
set (or if prefixed with the exclamation mark unset). The
argument must either be a single word, or an assignment (i.e.
two words, separated C<=>). In the former case
the kernel command line is searched for the word appearing as
is, or as left hand side of an assignment. In the latter case,
the exact assignment is looked for with right and left hand
side matching.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionSecurity',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionSecurity=> may be used to
check whether the given security module is enabled on the
system. Currently, the recognized values are
C<selinux>,
C<apparmor>,
C<ima>,
C<smack> and
C<audit>. The test may be negated by
prepending an exclamation mark.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionCapability',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionCapability=> may be used to
check whether the given capability exists in the capability
bounding set of the service manager (i.e. this does not check
whether capability is actually available in the permitted or
effective sets, see
L<capabilities(7)>
for details). Pass a capability name such as
C<CAP_MKNOD>, possibly prefixed with an
exclamation mark to negate the check.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionACPower',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionACPower=> may be used to
check whether the system has AC power, or is exclusively
battery powered at the time of activation of the unit. This
takes a boolean argument. If set to C<true>,
the condition will hold only if at least one AC connector of
the system is connected to a power source, or if no AC
connectors are known. Conversely, if set to
C<false>, the condition will hold only if
there is at least one AC connector known and all AC connectors
are disconnected from a power source.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionNeedsUpdate',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionNeedsUpdate=> takes one of
/var or /etc as
argument, possibly prefixed with a C<!> (for
inverting the condition). This condition may be used to
conditionalize units on whether the specified directory
requires an update because /usr's
modification time is newer than the stamp file
.updated in the specified directory. This
is useful to implement offline updates of the vendor operating
system resources in /usr that require
updating of /etc or
/var on the next following boot. Units
making use of this condition should order themselves before
L<systemd-update-done.service(8)>,
to make sure they run before the stamp file's modification
time gets reset indicating a completed update.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionFirstBoot',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionFirstBoot=> takes a boolean
argument. This condition may be used to conditionalize units
on whether the system is booting up with an unpopulated
/etc directory. This may be used to
populate /etc on the first boot after
factory reset, or when a new system instances boots up for the
first time.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionPathExists',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

With C<ConditionPathExists=> a file
existence condition is checked before a unit is started. If
the specified absolute path name does not exist, the condition
will fail. If the absolute path name passed to
C<ConditionPathExists=> is prefixed with an
exclamation mark (C<!>), the test is negated,
and the unit is only started if the path does not
exist.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionPathExistsGlob',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionPathExistsGlob=> is similar
to C<ConditionPathExists=>, but checks for the
existence of at least one file or directory matching the
specified globbing pattern.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionPathIsDirectory',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionPathIsDirectory=> is similar
to C<ConditionPathExists=> but verifies
whether a certain path exists and is a directory.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionPathIsSymbolicLink',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionPathIsSymbolicLink=> is
similar to C<ConditionPathExists=> but
verifies whether a certain path exists and is a symbolic
link.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionPathIsMountPoint',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionPathIsMountPoint=> is similar
to C<ConditionPathExists=> but verifies
whether a certain path exists and is a mount point.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionPathIsReadWrite',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionPathIsReadWrite=> is similar
to C<ConditionPathExists=> but verifies
whether the underlying file system is readable and writable
(i.e. not mounted read-only).

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionDirectoryNotEmpty',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionDirectoryNotEmpty=> is
similar to C<ConditionPathExists=> but
verifies whether a certain path exists and is a non-empty
directory.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionFileNotEmpty',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionFileNotEmpty=> is similar to
C<ConditionPathExists=> but verifies whether a
certain path exists and refers to a regular file with a
non-zero size.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'ConditionFileIsExecutable',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Before starting a unit, verify that the specified condition is true. If it is not true, the
starting of the unit will be (mostly silently) skipped, however all ordering dependencies of it are still
respected. A failing condition will not result in the unit being moved into a failure state. The condition is
checked at the time the queued start job is to be executed. Use condition expressions in order to silently skip
units that do not apply to the local running system, for example because the kernel or runtime environment
doesn't require its functionality. Use the various C<AssertArchitecture=>,
C<AssertVirtualization=>, \x{2026} options for a similar mechanism that puts the unit in a failure
state and logs about the failed check (see below).

C<ConditionFileIsExecutable=> is similar
to C<ConditionPathExists=> but verifies
whether a certain path exists, is a regular file and marked
executable.

If multiple conditions are specified, the unit will be
executed if all of them apply (i.e. a logical AND is applied).
Condition checks can be prefixed with a pipe symbol (|) in
which case a condition becomes a triggering condition. If at
least one triggering condition is defined for a unit, then the
unit will be executed if at least one of the triggering
conditions apply and all of the non-triggering conditions. If
you prefix an argument with the pipe symbol and an exclamation
mark, the pipe symbol must be passed first, the exclamation
second. Except for
C<ConditionPathIsSymbolicLink=>, all path
checks follow symlinks. If any of these options is assigned
the empty string, the list of conditions is reset completely,
all previous condition settings (of any kind) will have no
effect.",
        'type' => 'list'
      },
      'AssertArchitecture',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertVirtualization',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertHost',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertKernelCommandLine',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertSecurity',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertCapability',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertACPower',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertNeedsUpdate',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertFirstBoot',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathExists',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathExistsGlob',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsDirectory',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsSymbolicLink',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsMountPoint',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertPathIsReadWrite',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertDirectoryNotEmpty',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertFileNotEmpty',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AssertFileIsExecutable',
      {
        'description' => "Similar to the C<ConditionArchitecture>,
C<ConditionVirtualization>, \x{2026}, condition settings described above, these settings add
assertion checks to the start-up of the unit. However, unlike the conditions settings, any assertion setting
that is not met results in failure of the start job (which means this is logged loudly). Use assertion
expressions for units that cannot operate when specific requirements are not met, and when this is something
the administrator or user should look into.",
        'type' => 'leaf',
        'value_type' => 'uniline'
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
      }
    ],
    'generated_by' => 'parse-man.pl from systemd doc',
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Section::Unit'
  }
]
;


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
        'value_type' => 'uniline',
        'warn' => 'Unknown parameter'
      }
    ],
    'class_description' => 'Unit configuration files for services, sockets, mount
points, and swap devices share a subset of configuration options
which define the execution environment of spawned
processes.

This man page lists the configuration options shared by
these four unit types. See
L<systemd.unit(5)>
for the common options of all unit configuration files, and
L<systemd.service(5)>,
L<systemd.socket(5)>,
L<systemd.swap(5)>,
and
L<systemd.mount(5)>
for more information on the specific unit configuration files. The
execution specific configuration options are configured in the
[Service], [Socket], [Mount], or [Swap] sections, depending on the
unit type.

In addition, options which control resources through Linux Control Groups (cgroups) are listed in
L<systemd.resource-control(5)>.
Those options complement options listed here.
This configuration class was generated from systemd documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>
',
    'copyright' => [
      '2010-2016 Lennart Poettering and others',
      '2016 Dominique Dumont'
    ],
    'element' => [
      'WorkingDirectory',
      {
        'description' => 'Takes a directory path relative to the service\'s root directory specified by
C<RootDirectory>, or the special value C<~>. Sets the working directory for
executed processes. If set to C<~>, the home directory of the user specified in
C<User> is used. If not set, defaults to the root directory when systemd is running as a
system instance and the respective user\'s home directory if run as user. If the setting is prefixed with the
C<-> character, a missing working directory is not considered fatal. If
C<RootDirectory> is not set, then C<WorkingDirectory> is relative to the root
of the system running the service manager.  Note that setting this parameter might result in additional
dependencies to be added to the unit (see above).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootDirectory',
      {
        'description' => 'Takes a directory path relative to the host\'s root directory (i.e. the root of the system
running the service manager). Sets the root directory for executed processes, with the L<chroot(2)> system
call. If this is used, it must be ensured that the process binary and all its auxiliary files are available in
the chroot() jail. Note that setting this parameter might result in additional
dependencies to be added to the unit (see above).

The C<PrivateUsers> setting is particularly useful in conjunction with
C<RootDirectory>. For details, see below.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'User',
      {
        'description' => 'Set the UNIX user or group that the processes are executed as, respectively. Takes a single
user or group name, or numeric ID as argument. For system services (services run by the system service manager,
i.e. managed by PID 1) and for user services of the root user (services managed by root\'s instance of
systemd --user), the default is C<root>, but C<User> may be
used to specify a different user. For user services of any other user, switching user identity is not
permitted, hence the only valid setting is the same user the user\'s service manager is running as. If no group
is set, the default group of the user is used. This setting does not affect commands whose command line is
prefixed with C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Group',
      {
        'description' => 'Set the UNIX user or group that the processes are executed as, respectively. Takes a single
user or group name, or numeric ID as argument. For system services (services run by the system service manager,
i.e. managed by PID 1) and for user services of the root user (services managed by root\'s instance of
systemd --user), the default is C<root>, but C<User> may be
used to specify a different user. For user services of any other user, switching user identity is not
permitted, hence the only valid setting is the same user the user\'s service manager is running as. If no group
is set, the default group of the user is used. This setting does not affect commands whose command line is
prefixed with C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DynamicUser',
      {
        'description' => "Takes a boolean parameter. If set, a UNIX user and group pair is allocated dynamically when the
unit is started, and released as soon as it is stopped. The user and group will not be added to
/etc/passwd or /etc/group, but are managed transiently during
runtime. The L<nss-systemd(8)>
glibc NSS module provides integration of these dynamic users/groups into the system's user and group
databases. The user and group name to use may be configured via C<User> and
C<Group> (see above). If these options are not used and dynamic user/group allocation is
enabled for a unit, the name of the dynamic user/group is implicitly derived from the unit name. If the unit
name without the type suffix qualifies as valid user name it is used directly, otherwise a name incorporating a
hash of it is used. If a statically allocated user or group of the configured name already exists, it is used
and no dynamic user/group is allocated. Dynamic users/groups are allocated from the UID/GID range
61184\x{2026}65519. It is recommended to avoid this range for regular system or login users.  At any point in time
each UID/GID from this range is only assigned to zero or one dynamically allocated users/groups in
use. However, UID/GIDs are recycled after a unit is terminated. Care should be taken that any processes running
as part of a unit for which dynamic users/groups are enabled do not leave files or directories owned by these
users/groups around, as a different unit might get the same UID/GID assigned later on, and thus gain access to
these files or directories. If C<DynamicUser> is enabled, C<RemoveIPC>,
C<PrivateTmp> are implied. This ensures that the lifetime of IPC objects and temporary files
created by the executed processes is bound to the runtime of the service, and hence the lifetime of the dynamic
user/group. Since /tmp and /var/tmp are usually the only
world-writable directories on a system this ensures that a unit making use of dynamic user/group allocation
cannot leave files around after unit termination. Moreover C<ProtectSystem=strict> and
C<ProtectHome=read-only> are implied, thus prohibiting the service to write to arbitrary file
system locations. In order to allow the service to write to certain directories, they have to be whitelisted
using C<ReadWritePaths>, but care must be taken so that UID/GID recycling doesn't
create security issues involving files created by the service. Use C<RuntimeDirectory> (see
below) in order to assign a writable runtime directory to a service, owned by the dynamic user/group and
removed automatically when the unit is terminated. Defaults to off.",
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'SupplementaryGroups',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets the supplementary Unix groups the
processes are executed as. This takes a space-separated list
of group names or IDs. This option may be specified more than
once, in which case all listed groups are set as supplementary
groups. When the empty string is assigned, the list of
supplementary groups is reset, and all assignments prior to
this one will have no effect. In any way, this option does not
override, but extends the list of supplementary groups
configured in the system group database for the
user. This does not affect commands prefixed with C<+>.',
        'type' => 'list'
      },
      'RemoveIPC',
      {
        'description' => 'Takes a boolean parameter. If set, all System V and POSIX IPC objects owned by the user and
group the processes of this unit are run as are removed when the unit is stopped. This setting only has an
effect if at least one of C<User>, C<Group> and
C<DynamicUser> are used. It has no effect on IPC objects owned by the root user. Specifically,
this removes System V semaphores, as well as System V and POSIX shared memory segments and message queues. If
multiple units use the same user or group the IPC objects are removed when the last of these units is
stopped. This setting is implied if C<DynamicUser> is set.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Nice',
      {
        'description' => 'Sets the default nice level (scheduling
priority) for executed processes. Takes an integer between -20
(highest priority) and 19 (lowest priority). See
L<setpriority(2)>
for details.',
        'max' => '19',
        'min' => '-20',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'OOMScoreAdjust',
      {
        'description' => 'Sets the adjustment level for the
Out-Of-Memory killer for executed processes. Takes an integer
between -1000 (to disable OOM killing for this process) and
1000 (to make killing of this process under memory pressure
very likely). See proc.txt
for details.',
        'max' => '1000',
        'min' => '-1000',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'IOSchedulingClass',
      {
        'choice' => [
          '0',
          '1',
          '2',
          '3',
          'none',
          'realtime',
          'best-effort',
          'idle'
        ],
        'description' => 'Sets the I/O scheduling class for executed
processes. Takes an integer between 0 and 3 or one of the
strings C<none>, C<realtime>,
C<best-effort> or C<idle>. See
L<ioprio_set(2)>
for details.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'IOSchedulingPriority',
      {
        'description' => 'Sets the I/O scheduling priority for executed
processes. Takes an integer between 0 (highest priority) and 7
(lowest priority). The available priorities depend on the
selected I/O scheduling class (see above). See
L<ioprio_set(2)>
for details.',
        'max' => '7',
        'min' => '0',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'CPUSchedulingPolicy',
      {
        'choice' => [
          'other',
          'batch',
          'idle',
          'fifo',
          'rr'
        ],
        'description' => 'Sets the CPU scheduling policy for executed
processes. Takes one of
C<other>,
C<batch>,
C<idle>,
C<fifo> or
C<rr>. See
L<sched_setscheduler(2)>
for details.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'CPUSchedulingPriority',
      {
        'description' => 'Sets the CPU scheduling priority for executed
processes. The available priority range depends on the
selected CPU scheduling policy (see above). For real-time
scheduling policies an integer between 1 (lowest priority) and
99 (highest priority) can be used. See
L<sched_setscheduler(2)>
for details. ',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CPUSchedulingResetOnFork',
      {
        'description' => 'Takes a boolean argument. If true, elevated
CPU scheduling priorities and policies will be reset when the
executed processes fork, and can hence not leak into child
processes. See
L<sched_setscheduler(2)>
for details. Defaults to false.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'CPUAffinity',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Controls the CPU affinity of the executed
processes. Takes a list of CPU indices or ranges separated by
either whitespace or commas. CPU ranges are specified by the
lower and upper CPU indices separated by a dash.
This option may be specified more than once, in which case the
specified CPU affinity masks are merged. If the empty string
is assigned, the mask is reset, all assignments prior to this
will have no effect. See
L<sched_setaffinity(2)>
for details.',
        'type' => 'list'
      },
      'UMask',
      {
        'description' => 'Controls the file mode creation mask. Takes an
access mode in octal notation. See
L<umask(2)>
for details. Defaults to 0022.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Environment',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets environment variables for executed
processes. Takes a space-separated list of variable
assignments. This option may be specified more than once, in
which case all listed variables will be set. If the same
variable is set twice, the later setting will override the
earlier setting. If the empty string is assigned to this
option, the list of environment variables is reset, all prior
assignments have no effect. Variable expansion is not
performed inside the strings, however, specifier expansion is
possible. The $ character has no special meaning. If you need
to assign a value containing spaces to a variable, use double
quotes (") for the assignment.

Example:

    Environment="VAR1=word1 word2" VAR2=word3 "VAR3=$word 5 6"

gives three variables C<VAR1>,
C<VAR2>, C<VAR3>
with the values C<word1 word2>,
C<word3>, C<$word 5 6>.

See
L<environ(7)>
for details about environment variables.',
        'type' => 'list'
      },
      'EnvironmentFile',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Similar to C<Environment> but
reads the environment variables from a text file. The text
file should contain new-line-separated variable assignments.
Empty lines, lines without an C<=> separator,
or lines starting with ; or # will be ignored,
which may be used for commenting. A line ending with a
backslash will be concatenated with the following one,
allowing multiline variable definitions. The parser strips
leading and trailing whitespace from the values of
assignments, unless you use double quotes (").

The argument passed should be an absolute filename or
wildcard expression, optionally prefixed with
C<->, which indicates that if the file does
not exist, it will not be read and no error or warning message
is logged. This option may be specified more than once in
which case all specified files are read. If the empty string
is assigned to this option, the list of file to read is reset,
all prior assignments have no effect.

The files listed with this directive will be read
shortly before the process is executed (more specifically,
after all processes from a previous unit state terminated.
This means you can generate these files in one unit state, and
read it with this option in the next).

Settings from these
files override settings made with
C<Environment>. If the same variable is set
twice from these files, the files will be read in the order
they are specified and the later setting will override the
earlier setting.',
        'type' => 'list'
      },
      'PassEnvironment',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Pass environment variables from the systemd system
manager to executed processes. Takes a space-separated list of variable
names. This option may be specified more than once, in which case all
listed variables will be set. If the empty string is assigned to this
option, the list of environment variables is reset, all prior
assignments have no effect. Variables that are not set in the system
manager will not be passed and will be silently ignored.

Variables passed from this setting are overridden by those passed
from C<Environment> or
C<EnvironmentFile>.

Example:

    PassEnvironment=VAR1 VAR2 VAR3

passes three variables C<VAR1>,
C<VAR2>, C<VAR3>
with the values set for those variables in PID1.

See
L<environ(7)>
for details about environment variables.',
        'type' => 'list'
      },
      'StandardInput',
      {
        'choice' => [
          'null',
          'tty',
          'tty-force',
          'tty-fail',
          'socket',
          'fd'
        ],
        'description' => 'Controls where file descriptor 0 (STDIN) of
the executed processes is connected to. Takes one of
C<null>,
C<tty>,
C<tty-force>,
C<tty-fail>,
C<socket> or
C<fd>.

If C<null> is selected, standard input
will be connected to /dev/null, i.e. all
read attempts by the process will result in immediate
EOF.

If C<tty> is selected, standard input is
connected to a TTY (as configured by
C<TTYPath>, see below) and the executed
process becomes the controlling process of the terminal. If
the terminal is already being controlled by another process,
the executed process waits until the current controlling
process releases the terminal.

C<tty-force> is similar to
C<tty>, but the executed process is forcefully
and immediately made the controlling process of the terminal,
potentially removing previous controlling processes from the
terminal.

C<tty-fail> is similar to
C<tty> but if the terminal already has a
controlling process start-up of the executed process
fails.

The C<socket> option is only valid in
socket-activated services, and only when the socket
configuration file (see
L<systemd.socket(5)>
for details) specifies a single socket only. If this option is
set, standard input will be connected to the socket the
service was activated from, which is primarily useful for
compatibility with daemons designed for use with the
traditional
L<inetd(8)>
daemon.

The C<fd> option connects
the input stream to a single file descriptor provided by a socket unit.
A custom named file descriptor can be specified as part of this option,
after a C<:> (e.g. C<fd:foobar>).
If no name is specified, C<stdin> is assumed
(i.e. C<fd> is equivalent to C<fd:stdin>).
At least one socket unit defining such name must be explicitly provided via the
C<Sockets> option, and file descriptor name may differ
from the name of its containing socket unit.
If multiple matches are found, the first one will be used.
See C<FileDescriptorName> in
L<systemd.socket(5)>
for more details about named descriptors and ordering.

This setting defaults to
C<null>.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'StandardOutput',
      {
        'choice' => [
          'inherit',
          'null',
          'tty',
          'journal',
          'syslog',
          'kmsg',
          'journal+console',
          'syslog+console',
          'kmsg+console',
          'socket',
          'fd'
        ],
        'description' => 'Controls where file descriptor 1 (STDOUT) of
the executed processes is connected to. Takes one of
C<inherit>,
C<null>,
C<tty>,
C<journal>,
C<syslog>,
C<kmsg>,
C<journal+console>,
C<syslog+console>,
C<kmsg+console>,
C<socket> or
C<fd>.

C<inherit> duplicates the file descriptor
of standard input for standard output.

C<null> connects standard output to
/dev/null, i.e. everything written to it
will be lost.

C<tty> connects standard output to a tty
(as configured via C<TTYPath>, see below). If
the TTY is used for output only, the executed process will not
become the controlling process of the terminal, and will not
fail or wait for other processes to release the
terminal.

C<journal> connects standard output with
the journal which is accessible via
L<journalctl(1)>.
Note that everything that is written to syslog or kmsg (see
below) is implicitly stored in the journal as well, the
specific two options listed below are hence supersets of this
one.

C<syslog> connects standard output to the
L<syslog(3)>
system syslog service, in addition to the journal. Note that
the journal daemon is usually configured to forward everything
it receives to syslog anyway, in which case this option is no
different from C<journal>.

C<kmsg> connects standard output with the
kernel log buffer which is accessible via
L<dmesg(1)>,
in addition to the journal. The journal daemon might be
configured to send all logs to kmsg anyway, in which case this
option is no different from C<journal>.

C<journal+console>,
C<syslog+console> and
C<kmsg+console> work in a similar way as the
three options above but copy the output to the system console
as well.

C<socket> connects standard output to a
socket acquired via socket activation. The semantics are
similar to the same option of
C<StandardInput>.

The C<fd> option connects
the output stream to a single file descriptor provided by a socket unit.
A custom named file descriptor can be specified as part of this option,
after a C<:> (e.g. C<fd:foobar>).
If no name is specified, C<stdout> is assumed
(i.e. C<fd> is equivalent to C<fd:stdout>).
At least one socket unit defining such name must be explicitly provided via the
C<Sockets> option, and file descriptor name may differ
from the name of its containing socket unit.
If multiple matches are found, the first one will be used.
See C<FileDescriptorName> in
L<systemd.socket(5)>
for more details about named descriptors and ordering.

If the standard output (or error output, see below) of a unit is connected to the journal, syslog or the
kernel log buffer, the unit will implicitly gain a dependency of type C<After> on
systemd-journald.socket (also see the automatic dependencies section above).

This setting defaults to the value set with
C<DefaultStandardOutput> in
L<systemd-system.conf(5)>,
which defaults to C<journal>. Note that setting
this parameter might result in additional dependencies to be
added to the unit (see above).',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'StandardError',
      {
        'description' => 'Controls where file descriptor 2 (STDERR) of
the executed processes is connected to. The available options
are identical to those of C<StandardOutput>,
with some exceptions: if set to C<inherit> the
file descriptor used for standard output is duplicated for
standard error, while C<fd> operates on the error
stream and will look by default for a descriptor named
C<stderr>.

This setting defaults to the value set with
C<DefaultStandardError> in
L<systemd-system.conf(5)>,
which defaults to C<inherit>. Note that setting
this parameter might result in additional dependencies to be
added to the unit (see above).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TTYPath',
      {
        'description' => 'Sets the terminal device node to use if
standard input, output, or error are connected to a TTY (see
above). Defaults to
/dev/console.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TTYReset',
      {
        'description' => 'Reset the terminal device specified with
C<TTYPath> before and after execution.
Defaults to C<no>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TTYVHangup',
      {
        'description' => 'Disconnect all clients which have opened the
terminal device specified with C<TTYPath>
before and after execution. Defaults to
C<no>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TTYVTDisallocate',
      {
        'description' => 'If the terminal device specified with
C<TTYPath> is a virtual console terminal, try
to deallocate the TTY before and after execution. This ensures
that the screen and scrollback buffer is cleared. Defaults to
C<no>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogIdentifier',
      {
        'description' => 'Sets the process name to prefix log lines sent
to the logging system or the kernel log buffer with. If not
set, defaults to the process name of the executed process.
This option is only useful when
C<StandardOutput> or
C<StandardError> are set to
C<syslog>, C<journal> or
C<kmsg> (or to the same settings in combination
with C<+console>).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogFacility',
      {
        'description' => 'Sets the syslog facility to use when logging
to syslog. One of C<kern>,
C<user>, C<mail>,
C<daemon>, C<auth>,
C<syslog>, C<lpr>,
C<news>, C<uucp>,
C<cron>, C<authpriv>,
C<ftp>, C<local0>,
C<local1>, C<local2>,
C<local3>, C<local4>,
C<local5>, C<local6> or
C<local7>. See
L<syslog(3)>
for details. This option is only useful when
C<StandardOutput> or
C<StandardError> are set to
C<syslog>. Defaults to
C<daemon>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogLevel',
      {
        'description' => 'The default syslog level to use when logging to
syslog or the kernel log buffer. One of
C<emerg>,
C<alert>,
C<crit>,
C<err>,
C<warning>,
C<notice>,
C<info>,
C<debug>. See
L<syslog(3)>
for details. This option is only useful when
C<StandardOutput> or
C<StandardError> are set to
C<syslog> or C<kmsg>. Note that
individual lines output by the daemon might be prefixed with a
different log level which can be used to override the default
log level specified here. The interpretation of these prefixes
may be disabled with C<SyslogLevelPrefix>,
see below. For details, see
L<sd-daemon(3)>.
Defaults to
C<info>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SyslogLevelPrefix',
      {
        'description' => 'Takes a boolean argument. If true and
C<StandardOutput> or
C<StandardError> are set to
C<syslog>, C<kmsg> or
C<journal>, log lines written by the executed
process that are prefixed with a log level will be passed on
to syslog with this log level set but the prefix removed. If
set to false, the interpretation of these prefixes is disabled
and the logged lines are passed on as-is. For details about
this prefixing see
L<sd-daemon(3)>.
Defaults to true.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'TimerSlackNSec',
      {
        'description' => 'Sets the timer slack in nanoseconds for the
executed processes. The timer slack controls the accuracy of
wake-ups triggered by timers. See
L<prctl(2)>
for more information. Note that in contrast to most other time
span definitions this parameter takes an integer value in
nano-seconds if no unit is specified. The usual time units are
understood too.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitCPU',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitFSIZE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitDATA',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitSTACK',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitCORE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitRSS',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitNOFILE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitAS',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitNPROC',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitMEMLOCK',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitLOCKS',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitSIGPENDING',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitMSGQUEUE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitNICE',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitRTPRIO',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LimitRTTIME',
      {
        'description' => "Set soft and hard limits on various resources for executed processes. See
L<setrlimit(2)> for details on
the resource limit concept. Resource limits may be specified in two formats: either as single value to set a
specific soft and hard limit to the same value, or as colon-separated pair C<soft:hard> to set
both limits individually (e.g. C<LimitAS=4G:16G>).  Use the string C<infinity>
to configure no limit on a specific resource. The multiplicative suffixes K, M, G, T, P and E (to the base
1024) may be used for resource limits measured in bytes (e.g. LimitAS=16G). For the limits referring to time
values, the usual time units ms, s, min, h and so on may be used (see
L<systemd.time(7)> for
details). Note that if no time unit is specified for C<LimitCPU> the default unit of seconds
is implied, while for C<LimitRTTIME> the default unit of microseconds is implied. Also, note
that the effective granularity of the limits might influence their enforcement. For example, time limits
specified for C<LimitCPU> will be rounded up implicitly to multiples of 1s. For
C<LimitNICE> the value may be specified in two syntaxes: if prefixed with C<+>
or C<->, the value is understood as regular Linux nice value in the range -20..19. If not
prefixed like this the value is understood as raw resource limit parameter in the range 0..40 (with 0 being
equivalent to 1).

Note that most process resource limits configured with
these options are per-process, and processes may fork in order
to acquire a new set of resources that are accounted
independently of the original process, and may thus escape
limits set. Also note that C<LimitRSS> is not
implemented on Linux, and setting it has no effect. Often it
is advisable to prefer the resource controls listed in
L<systemd.resource-control(5)>
over these per-process limits, as they apply to services as a
whole, may be altered dynamically at runtime, and are
generally more expressive. For example,
C<MemoryLimit> is a more powerful (and
working) replacement for C<LimitRSS>.

For system units these resource limits may be chosen freely. For user units however (i.e. units run by a
per-user instance of
L<systemd(1)>), these limits are
bound by (possibly more restrictive) per-user limits enforced by the OS.

Resource limits not configured explicitly for a unit default to the value configured in the various
C<DefaultLimitCPU>, C<DefaultLimitFSIZE>, \x{2026} options available in
L<systemd-system.conf(5)>, and \x{2013}
if not configured there \x{2013} the kernel or per-user defaults, as defined by the OS (the latter only for user
services, see above).",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PAMName',
      {
        'description' => 'Sets the PAM service name to set up a session
as. If set, the executed process will be registered as a PAM
session under the specified service name. This is only useful
in conjunction with the C<User> setting. If
not set, no PAM session will be opened for the executed
processes. See
L<pam(8)>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'CapabilityBoundingSet',
      {
        'description' => 'Controls which capabilities to include in the capability bounding set for the executed
process. See L<capabilities(7)> for
details. Takes a whitespace-separated list of capability names, e.g. C<CAP_SYS_ADMIN>,
C<CAP_DAC_OVERRIDE>, C<CAP_SYS_PTRACE>. Capabilities listed will be
included in the bounding set, all others are removed. If the list of capabilities is prefixed with
C<~>, all but the listed capabilities will be included, the effect of the assignment
inverted. Note that this option also affects the respective capabilities in the effective, permitted and
inheritable capability sets. If this option is not used, the capability bounding set is not modified on process
execution, hence no limits on the capabilities of the process are enforced. This option may appear more than
once, in which case the bounding sets are merged. If the empty string is assigned to this option, the bounding
set is reset to the empty capability set, and all prior settings have no effect.  If set to
C<~> (without any further argument), the bounding set is reset to the full set of available
capabilities, also undoing any previous settings. This does not affect commands prefixed with
C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AmbientCapabilities',
      {
        'description' => 'Controls which capabilities to include in the ambient capability set for the executed
process. Takes a whitespace-separated list of capability names, e.g. C<CAP_SYS_ADMIN>,
C<CAP_DAC_OVERRIDE>, C<CAP_SYS_PTRACE>. This option may appear more than
once in which case the ambient capability sets are merged.  If the list of capabilities is prefixed with
C<~>, all but the listed capabilities will be included, the effect of the assignment
inverted. If the empty string is assigned to this option, the ambient capability set is reset to the empty
capability set, and all prior settings have no effect.  If set to C<~> (without any further
argument), the ambient capability set is reset to the full set of available capabilities, also undoing any
previous settings. Note that adding capabilities to ambient capability set adds them to the process\'s inherited
capability set.  

 Ambient capability sets are useful if you want to execute a process as a
non-privileged user but still want to give it some capabilities.  Note that in this case option
C<keep-caps> is automatically added to C<SecureBits> to retain the
capabilities over the user change. C<AmbientCapabilities> does not affect commands prefixed
with C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SecureBits',
      {
        'description' => 'Controls the secure bits set for the executed
process. Takes a space-separated combination of options from
the following list:
C<keep-caps>,
C<keep-caps-locked>,
C<no-setuid-fixup>,
C<no-setuid-fixup-locked>,
C<noroot>, and
C<noroot-locked>.
This option may appear more than once, in which case the secure
bits are ORed. If the empty string is assigned to this option,
the bits are reset to 0. This does not affect commands prefixed with C<+>.
See L<capabilities(7)>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ReadWritePaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used to limit
access a process might have to the file system hierarchy. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager).  Note that if paths
contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace with the same
access modes as from outside of it. Paths listed in C<ReadOnlyPaths> are accessible for
reading only, writing will be refused even if the usual file access controls would permit this. Nest
C<ReadWritePaths> inside of C<ReadOnlyPaths> in order to provide writable
subdirectories within read-only directories. Use C<ReadWritePaths> in order to whitelist
specific paths for write access if C<ProtectSystem=strict> is used. Paths listed in
C<InaccessiblePaths> will be made inaccessible for processes inside the namespace (along with
everything below them in the file system hierarchy).

Note that restricting access with these options does not extend to submounts of a directory that are
created later on.  Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths> and
C<InaccessiblePaths> may be prefixed with C<->, in which case they will be ignored
when they do not exist. Note that using this setting will disconnect propagation of mounts from the service to
the host (propagation in the opposite direction continues to work). This means that this setting may not be used
for services which shall be able to install mount points in the main mount namespace. Note that the effect of
these settings may be undone by privileged processes. In order to set up an effective sandboxed environment for
a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or C<SystemCallFilter=~@mount>.',
        'type' => 'list'
      },
      'ReadOnlyPaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used to limit
access a process might have to the file system hierarchy. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager).  Note that if paths
contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace with the same
access modes as from outside of it. Paths listed in C<ReadOnlyPaths> are accessible for
reading only, writing will be refused even if the usual file access controls would permit this. Nest
C<ReadWritePaths> inside of C<ReadOnlyPaths> in order to provide writable
subdirectories within read-only directories. Use C<ReadWritePaths> in order to whitelist
specific paths for write access if C<ProtectSystem=strict> is used. Paths listed in
C<InaccessiblePaths> will be made inaccessible for processes inside the namespace (along with
everything below them in the file system hierarchy).

Note that restricting access with these options does not extend to submounts of a directory that are
created later on.  Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths> and
C<InaccessiblePaths> may be prefixed with C<->, in which case they will be ignored
when they do not exist. Note that using this setting will disconnect propagation of mounts from the service to
the host (propagation in the opposite direction continues to work). This means that this setting may not be used
for services which shall be able to install mount points in the main mount namespace. Note that the effect of
these settings may be undone by privileged processes. In order to set up an effective sandboxed environment for
a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or C<SystemCallFilter=~@mount>.',
        'type' => 'list'
      },
      'InaccessiblePaths',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Sets up a new file system namespace for executed processes. These options may be used to limit
access a process might have to the file system hierarchy. Each setting takes a space-separated list of paths
relative to the host\'s root directory (i.e. the system running the service manager).  Note that if paths
contain symlinks, they are resolved relative to the root directory set with
C<RootDirectory>.

Paths listed in C<ReadWritePaths> are accessible from within the namespace with the same
access modes as from outside of it. Paths listed in C<ReadOnlyPaths> are accessible for
reading only, writing will be refused even if the usual file access controls would permit this. Nest
C<ReadWritePaths> inside of C<ReadOnlyPaths> in order to provide writable
subdirectories within read-only directories. Use C<ReadWritePaths> in order to whitelist
specific paths for write access if C<ProtectSystem=strict> is used. Paths listed in
C<InaccessiblePaths> will be made inaccessible for processes inside the namespace (along with
everything below them in the file system hierarchy).

Note that restricting access with these options does not extend to submounts of a directory that are
created later on.  Non-directory paths may be specified as well. These options may be specified more than once,
in which case all paths listed will have limited access from within the namespace. If the empty string is
assigned to this option, the specific list is reset, and all prior assignments have no effect.

Paths in C<ReadWritePaths>, C<ReadOnlyPaths> and
C<InaccessiblePaths> may be prefixed with C<->, in which case they will be ignored
when they do not exist. Note that using this setting will disconnect propagation of mounts from the service to
the host (propagation in the opposite direction continues to work). This means that this setting may not be used
for services which shall be able to install mount points in the main mount namespace. Note that the effect of
these settings may be undone by privileged processes. In order to set up an effective sandboxed environment for
a unit it is thus recommended to combine these settings with either
C<CapabilityBoundingSet=~CAP_SYS_ADMIN> or C<SystemCallFilter=~@mount>.',
        'type' => 'list'
      },
      'PrivateTmp',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new file system namespace for the executed
processes and mounts private /tmp and /var/tmp directories inside it
that is not shared by processes outside of the namespace. This is useful to secure access to temporary files of
the process, but makes sharing between processes via /tmp or /var/tmp
impossible. If this is enabled, all temporary files created by a service in these directories will be removed
after the service is stopped.  Defaults to false. It is possible to run two or more units within the same
private /tmp and /var/tmp namespace by using the
C<JoinsNamespaceOf> directive, see
L<systemd.unit(5)> for
details. This setting is implied if C<DynamicUser> is set. For this setting the same
restrictions regarding mount propagation and privileges apply as for C<ReadOnlyPaths> and
related calls, see above.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PrivateDevices',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new /dev namespace for the executed processes and
only adds API pseudo devices such as /dev/null, /dev/zero or
/dev/random (as well as the pseudo TTY subsystem) to it, but no physical devices such as
/dev/sda, system memory /dev/mem, system ports
/dev/port and others. This is useful to securely turn off physical device access by the
executed process. Defaults to false. Enabling this option will install a system call filter to block low-level
I/O system calls that are grouped in the C<@raw-io> set, will also remove
C<CAP_MKNOD> and C<CAP_SYS_RAWIO> from the capability bounding set for
the unit (see above), and set C<DevicePolicy=closed> (see
L<systemd.resource-control(5)>
for details). Note that using this setting will disconnect propagation of mounts from the service to the host
(propagation in the opposite direction continues to work).  This means that this setting may not be used for
services which shall be able to install mount points in the main mount namespace. The /dev namespace will be
mounted read-only and \'noexec\'.  The latter may break old programs which try to set up executable memory by
using L<mmap(2)> of
/dev/zero instead of using C<MAP_ANON>. This setting is implied if
C<DynamicUser> is set. For this setting the same restrictions regarding mount propagation and
privileges apply as for C<ReadOnlyPaths> and related calls, see above.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PrivateNetwork',
      {
        'description' => 'Takes a boolean argument. If true, sets up a
new network namespace for the executed processes and
configures only the loopback network device
C<lo> inside it. No other network devices will
be available to the executed process. This is useful to
securely turn off network access by the executed process.
Defaults to false. It is possible to run two or more units
within the same private network namespace by using the
C<JoinsNamespaceOf> directive, see
L<systemd.unit(5)>
for details. Note that this option will disconnect all socket
families from the host, this includes AF_NETLINK and AF_UNIX.
The latter has the effect that AF_UNIX sockets in the abstract
socket namespace will become unavailable to the processes
(however, those located in the file system will continue to be
accessible).',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PrivateUsers',
      {
        'description' => 'Takes a boolean argument. If true, sets up a new user namespace for the executed processes and
configures a minimal user and group mapping, that maps the C<root> user and group as well as
the unit\'s own user and group to themselves and everything else to the C<nobody> user and
group. This is useful to securely detach the user and group databases used by the unit from the rest of the
system, and thus to create an effective sandbox environment. All files, directories, processes, IPC objects and
other resources owned by users/groups not equaling C<root> or the unit\'s own will stay visible
from within the unit but appear owned by the C<nobody> user and group. If this mode is enabled,
all unit processes are run without privileges in the host user namespace (regardless if the unit\'s own
user/group is C<root> or not). Specifically this means that the process will have zero process
capabilities on the host\'s user namespace, but full capabilities within the service\'s user namespace. Settings
such as C<CapabilityBoundingSet> will affect only the latter, and there\'s no way to acquire
additional capabilities in the host\'s user namespace. Defaults to off.

This setting is particularly useful in conjunction with C<RootDirectory>, as the need to
synchronize the user and group databases in the root directory and on the host is reduced, as the only users
and groups who need to be matched are C<root>, C<nobody> and the unit\'s own
user and group.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectSystem',
      {
        'choice' => [
          'no',
          'yes',
          'full',
          'strict'
        ],
        'description' => 'Takes a boolean argument or the special values C<full> or
C<strict>. If true, mounts the /usr and /boot
directories read-only for processes invoked by this unit. If set to C<full>, the
/etc directory is mounted read-only, too. If set to C<strict> the entire
file system hierarchy is mounted read-only, except for the API file system subtrees /dev,
/proc and /sys (protect these directories using
C<PrivateDevices>, C<ProtectKernelTunables>,
C<ProtectControlGroups>). This setting ensures that any modification of the vendor-supplied
operating system (and optionally its configuration, and local mounts) is prohibited for the service.  It is
recommended to enable this setting for all long-running services, unless they are involved with system updates
or need to modify the operating system in other ways. If this option is used,
C<ReadWritePaths> may be used to exclude specific directories from being made read-only. This
setting is implied if C<DynamicUser> is set. For this setting the same restrictions regarding
mount propagation and privileges apply as for C<ReadOnlyPaths> and related calls, see
above. Defaults to off.',
        'replace' => {
          '0' => 'no',
          '1' => 'yes',
          'false' => 'no',
          'true' => 'yes'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'ProtectHome',
      {
        'choice' => [
          'no',
          'yes',
          'read-only'
        ],
        'description' => 'Takes a boolean argument or C<read-only>. If true, the directories
/home, /root and /run/user are made inaccessible
and empty for processes invoked by this unit. If set to C<read-only>, the three directories are
made read-only instead. It is recommended to enable this setting for all long-running services (in particular
network-facing ones), to ensure they cannot get access to private user data, unless the services actually
require access to the user\'s private data. This setting is implied if C<DynamicUser> is
set. For this setting the same restrictions regarding mount propagation and privileges apply as for
C<ReadOnlyPaths> and related calls, see above.',
        'replace' => {
          '0' => 'no',
          '1' => 'yes',
          'false' => 'no',
          'true' => 'yes'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'ProtectKernelTunables',
      {
        'description' => 'Takes a boolean argument. If true, kernel variables accessible through
/proc/sys, /sys, /proc/sysrq-trigger,
/proc/latency_stats, /proc/acpi,
/proc/timer_stats, /proc/fs and /proc/irq will
be made read-only to all processes of the unit. Usually, tunable kernel variables should only be written at
boot-time, with the L<sysctl.d(5)>
mechanism. Almost no services need to write to these at runtime; it is hence recommended to turn this on for
most services. For this setting the same restrictions regarding mount propagation and privileges apply as for
C<ReadOnlyPaths> and related calls, see above. Defaults to off.
Note that this option does not prevent kernel tuning through IPC interfaces and external programs. However
C<InaccessiblePaths> can be used to make some IPC file system objects
inaccessible.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'ProtectControlGroups',
      {
        'description' => 'Takes a boolean argument. If true, the Linux Control Groups (L<cgroups(7)>) hierarchies
accessible through /sys/fs/cgroup will be made read-only to all processes of the
unit. Except for container managers no services should require write access to the control groups hierarchies;
it is hence recommended to turn this on for most services. For this setting the same restrictions regarding
mount propagation and privileges apply as for C<ReadOnlyPaths> and related calls, see
above. Defaults to off.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'MountFlags',
      {
        'description' => 'Takes a mount propagation flag: C<shared>, C<slave> or
C<private>, which control whether mounts in the file system namespace set up for this unit\'s
processes will receive or propagate mounts or unmounts. See L<mount(2)> for
details. Defaults to C<shared>. Use C<shared> to ensure that mounts and unmounts
are propagated from the host to the container and vice versa. Use C<slave> to run processes so
that none of their mounts and unmounts will propagate to the host. Use C<private> to also ensure
that no mounts and unmounts from the host will propagate into the unit processes\' namespace. Note that
C<slave> means that file systems mounted on the host might stay mounted continuously in the
unit\'s namespace, and thus keep the device busy. Note that the file system namespace related options
(C<PrivateTmp>, C<PrivateDevices>, C<ProtectSystem>,
C<ProtectHome>, C<ProtectKernelTunables>,
C<ProtectControlGroups>, C<ReadOnlyPaths>,
C<InaccessiblePaths>, C<ReadWritePaths>) require that mount and unmount
propagation from the unit\'s file system namespace is disabled, and hence downgrade C<shared> to
C<slave>. ',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UtmpIdentifier',
      {
        'description' => 'Takes a four character identifier string for
an L<utmp(5)>
and wtmp entry for this service. This should only be
set for services such as getty
implementations (such as L<agetty(8)>)
where utmp/wtmp entries must be created and cleared before and
after execution, or for services that shall be executed as if
they were run by a getty process (see
below). If the configured string is longer than four
characters, it is truncated and the terminal four characters
are used. This setting interprets %I style string
replacements. This setting is unset by default, i.e. no
utmp/wtmp entries are created or cleaned up for this
service.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UtmpMode',
      {
        'choice' => [
          'init',
          'login',
          'user'
        ],
        'description' => 'Takes one of C<init>,
C<login> or C<user>. If
C<UtmpIdentifier> is set, controls which
type of L<utmp(5)>/wtmp
entries for this service are generated. This setting has no
effect unless C<UtmpIdentifier> is set
too. If C<init> is set, only an
C<INIT_PROCESS> entry is generated and the
invoked process must implement a
getty-compatible utmp/wtmp logic. If
C<login> is set, first an
C<INIT_PROCESS> entry, followed by a
C<LOGIN_PROCESS> entry is generated. In
this case, the invoked process must implement a L<login(1)>-compatible
utmp/wtmp logic. If C<user> is set, first an
C<INIT_PROCESS> entry, then a
C<LOGIN_PROCESS> entry and finally a
C<USER_PROCESS> entry is generated. In this
case, the invoked process may be any process that is suitable
to be run as session leader. Defaults to
C<init>.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'SELinuxContext',
      {
        'description' => 'Set the SELinux security context of the
executed process. If set, this will override the automated
domain transition. However, the policy still needs to
authorize the transition. This directive is ignored if SELinux
is disabled. If prefixed by C<->, all errors
will be ignored. This does not affect commands prefixed with C<+>.
See L<setexeccon(3)>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AppArmorProfile',
      {
        'description' => 'Takes a profile name as argument. The process
executed by the unit will switch to this profile when started.
Profiles must already be loaded in the kernel, or the unit
will fail. This result in a non operation if AppArmor is not
enabled. If prefixed by C<->, all errors will
be ignored. This does not affect commands prefixed with C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SmackProcessLabel',
      {
        'description' => 'Takes a C<SMACK64> security
label as argument. The process executed by the unit will be
started under this label and SMACK will decide whether the
process is allowed to run or not, based on it. The process
will continue to run under the label specified here unless the
executable has its own C<SMACK64EXEC> label, in
which case the process will transition to run under that
label. When not specified, the label that systemd is running
under is used. This directive is ignored if SMACK is
disabled.

The value may be prefixed by C<->, in
which case all errors will be ignored. An empty value may be
specified to unset previous assignments. This does not affect
commands prefixed with C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IgnoreSIGPIPE',
      {
        'description' => 'Takes a boolean argument. If true, causes
C<SIGPIPE> to be ignored in the executed
process. Defaults to true because C<SIGPIPE>
generally is useful only in shell pipelines.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'NoNewPrivileges',
      {
        'description' => 'Takes a boolean argument. If true, ensures that the service
process and all its children can never gain new privileges. This option is more
powerful than the respective secure bits flags (see above), as it also prohibits
UID changes of any kind. This is the simplest and most effective way to ensure that
a process and its children can never elevate privileges again. Defaults to false,
but in the user manager instance certain settings force
C<NoNewPrivileges=yes>, ignoring the value of this setting.
Those is the case when C<SystemCallFilter>,
C<SystemCallArchitectures>,
C<RestrictAddressFamilies>,
C<PrivateDevices>,
C<ProtectKernelTunables>,
C<ProtectKernelModules>,
C<MemoryDenyWriteExecute>, or
C<RestrictRealtime> are specified.
',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'SystemCallFilter',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Takes a space-separated list of system call names. If this setting is used, all system calls
executed by the unit processes except for the listed ones will result in immediate process termination with the
C<SIGSYS> signal (whitelisting). If the first character of the list is C<~>,
the effect is inverted: only the listed system calls will result in immediate process termination
(blacklisting). If running in user mode, or in system mode, but without the C<CAP_SYS_ADMIN>
capability (e.g. setting C<User=nobody>), C<NoNewPrivileges=yes> is
implied. This feature makes use of the Secure Computing Mode 2 interfaces of the kernel ('seccomp filtering')
and is useful for enforcing a minimal sandboxing environment. Note that the execve,
exit, exit_group, getrlimit,
rt_sigreturn, sigreturn system calls and the system calls for
querying time and sleeping are implicitly whitelisted and do not need to be listed explicitly. This option may
be specified more than once, in which case the filter masks are merged. If the empty string is assigned, the
filter is reset, all prior assignments will have no effect. This does not affect commands prefixed with
C<+>.

Note that strict system call filters may impact execution and error handling code paths of the service
invocation. Specifically, access to the execve system call is required for the execution
of the service binary \x{2014} if it is blocked service invocation will necessarily fail. Also, if execution of the
service binary fails for some reason (for example: missing service executable), the error handling logic might
require access to an additional set of system calls in order to process and log this failure correctly. It
might be necessary to temporarily disable system call filters in order to simplify debugging of such
failures.

If you specify both types of this option (i.e.
whitelisting and blacklisting), the first encountered will
take precedence and will dictate the default action
(termination or approval of a system call). Then the next
occurrences of this option will add or delete the listed
system calls from the set of the filtered system calls,
depending of its type and the default action. (For example, if
you have started with a whitelisting of
read and write, and
right after it add a blacklisting of
write, then write
will be removed from the set.)

As the number of possible system
calls is large, predefined sets of system calls are provided.
A set starts with C<\@> character, followed by
name of the set.
Currently predefined system call setsSetDescription\@basic-ioSystem calls for basic I/O: reading, writing, seeking, file descriptor duplication and closing (L<read(2)>, L<write(2)>, and related calls)\@clockSystem calls for changing the system clock (L<adjtimex(2)>, L<settimeofday(2)>, and related calls)\@cpu-emulationSystem calls for CPU emulation functionality (L<vm86(2)> and related calls)\@debugDebugging, performance monitoring and tracing functionality (L<ptrace(2)>, L<perf_event_open(2)> and related calls)\@io-eventEvent loop system calls (L<poll(2)>, L<select(2)>, L<epoll(7)>, L<eventfd(2)> and related calls)\@ipcPipes, SysV IPC, POSIX Message Queues and other IPC (L<mq_overview(7)>, L<svipc(7)>)\@keyringKernel keyring access (L<keyctl(2)> and related calls)\@moduleKernel module control (L<init_module(2)>, L<delete_module(2)> and related calls)\@mountFile system mounting and unmounting (L<mount(2)>, L<chroot(2)>, and related calls)\@network-ioSocket I/O (including local AF_UNIX): L<socket(7)>, L<unix(7)>\@obsoleteUnusual, obsolete or unimplemented (L<create_module(2)>, L<gtty(2)>, \x{2026})\@privilegedAll system calls which need super-user capabilities (L<capabilities(7)>)\@processProcess control, execution, namespaces (L<clone(2)>, L<kill(2)>, L<namespaces(7)>, \x{2026}\@raw-ioRaw I/O port access (L<ioperm(2)>, L<iopl(2)>, pciconfig_read(), \x{2026})\@resourcesSystem calls for changing resource limits, memory and scheduling parameters (L<setrlimit(2)>, L<setpriority(2)>, \x{2026})
Note that as new system calls are added to the kernel, additional system calls might be added to the groups
above, so the contents of the sets may change between systemd versions.

It is recommended to combine the file system namespacing related options with
C<SystemCallFilter=~\@mount>, in order to prohibit the unit's processes to undo the
mappings. Specifically these are the options C<PrivateTmp>,
C<PrivateDevices>, C<ProtectSystem>, C<ProtectHome>,
C<ProtectKernelTunables>, C<ProtectControlGroups>,
C<ReadOnlyPaths>, C<InaccessiblePaths> and
C<ReadWritePaths>.",
        'type' => 'list'
      },
      'SystemCallErrorNumber',
      {
        'description' => 'Takes an C<errno> error number
name to return when the system call filter configured with
C<SystemCallFilter> is triggered, instead of
terminating the process immediately. Takes an error name such
as C<EPERM>, C<EACCES> or
C<EUCLEAN>. When this setting is not used,
or when the empty string is assigned, the process will be
terminated immediately when the filter is
triggered.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SystemCallArchitectures',
      {
        'description' => 'Takes a space-separated list of architecture identifiers to
include in the system call filter. The known architecture identifiers are the same
as for C<ConditionArchitecture> described in
L<systemd.unit(5)>,
as well as C<x32>, C<mips64-n32>,
C<mips64-le-n32>, and the special identifier
C<native>. Only system calls of the specified architectures will
be permitted to processes of this unit. This is an effective way to disable
compatibility with non-native architectures for processes, for example to prohibit
execution of 32-bit x86 binaries on 64-bit x86-64 systems. The special
C<native> identifier implicitly maps to the native architecture
of the system (or more strictly: to the architecture the system manager is
compiled for). If running in user mode, or in system mode, but without the
C<CAP_SYS_ADMIN> capability (e.g. setting
C<User=nobody>), C<NoNewPrivileges=yes> is
implied. Note that setting this option to a non-empty list implies that
C<native> is included too. By default, this option is set to the
empty list, i.e. no architecture system call filtering is applied.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestrictAddressFamilies',
      {
        'description' => 'Restricts the set of socket address families
accessible to the processes of this unit. Takes a
space-separated list of address family names to whitelist,
such as
C<AF_UNIX>,
C<AF_INET> or
C<AF_INET6>. When
prefixed with C<~> the listed address
families will be applied as blacklist, otherwise as whitelist.
Note that this restricts access to the
L<socket(2)>
system call only. Sockets passed into the process by other
means (for example, by using socket activation with socket
units, see
L<systemd.socket(5)>)
are unaffected. Also, sockets created with
socketpair() (which creates connected
AF_UNIX sockets only) are unaffected. Note that this option
has no effect on 32-bit x86 and is ignored (but works
correctly on x86-64). If running in user mode, or in system
mode, but without the C<CAP_SYS_ADMIN>
capability (e.g. setting C<User=nobody>),
C<NoNewPrivileges=yes> is implied. By
default, no restriction applies, all address families are
accessible to processes. If assigned the empty string, any
previous list changes are undone.

Use this option to limit exposure of processes to remote
systems, in particular via exotic network protocols. Note that
in most cases, the local C<AF_UNIX> address
family should be included in the configured whitelist as it is
frequently used for local communication, including for
L<syslog(2)>
logging. This does not affect commands prefixed with C<+>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ProtectKernelModules',
      {
        'description' => 'Takes a boolean argument. If true, explicit module loading will
be denied. This allows to turn off module load and unload operations on modular
kernels. It is recommended to turn this on for most services that do not need special
file systems or extra kernel modules to work. Default to off. Enabling this option
removes C<CAP_SYS_MODULE> from the capability bounding set for
the unit, and installs a system call filter to block module system calls,
also /usr/lib/modules is made inaccessible. For this
setting the same restrictions regarding mount propagation and privileges
apply as for C<ReadOnlyPaths> and related calls, see above.
Note that limited automatic module loading due to user configuration or kernel
mapping tables might still happen as side effect of requested user operations,
both privileged and unprivileged. To disable module auto-load feature please see
L<sysctl.d(5)>C<kernel.modules_disabled> mechanism and
/proc/sys/kernel/modules_disabled documentation.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Personality',
      {
        'choice' => [
          'x86',
          'x86-64',
          'ppc',
          'ppc-le',
          'ppc64',
          'ppc64-le',
          's390',
          's390x'
        ],
        'description' => 'Controls which kernel architecture L<uname(2)> shall report,
when invoked by unit processes. Takes one of the architecture identifiers C<x86>,
C<x86-64>, C<ppc>, C<ppc-le>, C<ppc64>,
C<ppc64-le>, C<s390> or C<s390x>. Which personality
architectures are supported depends on the system architecture. Usually the 64bit versions of the various
system architectures support their immediate 32bit personality architecture counterpart, but no others. For
example, C<x86-64> systems support the C<x86-64> and
C<x86> personalities but no others. The personality feature is useful when running 32-bit
services on a 64-bit host system. If not specified, the personality is left unmodified and thus reflects the
personality of the host system\'s kernel.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'RuntimeDirectory',
      {
        'description' => 'Takes a list of directory names. If set, one
or more directories by the specified names will be created
below /run (for system services) or below
C<$XDG_RUNTIME_DIR> (for user services) when
the unit is started, and removed when the unit is stopped. The
directories will have the access mode specified in
C<RuntimeDirectoryMode>, and will be owned by
the user and group specified in C<User> and
C<Group>. Use this to manage one or more
runtime directories of the unit and bind their lifetime to the
daemon runtime. The specified directory names must be
relative, and may not include a C</>, i.e.
must refer to simple directories to create or remove. This is
particularly useful for unprivileged daemons that cannot
create runtime directories in /run due to
lack of privileges, and to make sure the runtime directory is
cleaned up automatically after use. For runtime directories
that require more complex or different configuration or
lifetime guarantees, please consider using
L<tmpfiles.d(5)>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RuntimeDirectoryMode',
      {
        'description' => 'Takes a list of directory names. If set, one
or more directories by the specified names will be created
below /run (for system services) or below
C<$XDG_RUNTIME_DIR> (for user services) when
the unit is started, and removed when the unit is stopped. The
directories will have the access mode specified in
C<RuntimeDirectoryMode>, and will be owned by
the user and group specified in C<User> and
C<Group>. Use this to manage one or more
runtime directories of the unit and bind their lifetime to the
daemon runtime. The specified directory names must be
relative, and may not include a C</>, i.e.
must refer to simple directories to create or remove. This is
particularly useful for unprivileged daemons that cannot
create runtime directories in /run due to
lack of privileges, and to make sure the runtime directory is
cleaned up automatically after use. For runtime directories
that require more complex or different configuration or
lifetime guarantees, please consider using
L<tmpfiles.d(5)>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MemoryDenyWriteExecute',
      {
        'description' => 'Takes a boolean argument. If set, attempts to create memory mappings that are writable and
executable at the same time, or to change existing memory mappings to become executable, or mapping shared memory
segments as executable are prohibited.
Specifically, a system call filter is added that rejects
L<mmap(2)>
system calls with both C<PROT_EXEC> and C<PROT_WRITE> set,
L<mprotect(2)>
system calls with C<PROT_EXEC> set and
L<shmat(2)>
system calls with C<SHM_EXEC> set. Note that this option is incompatible with programs
that generate program code dynamically at runtime, such as JIT execution engines, or programs compiled making
use of the code "trampoline" feature of various C compilers. This option improves service security, as it makes
harder for software exploits to change running code dynamically.
',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RestrictRealtime',
      {
        'description' => 'Takes a boolean argument. If set, any attempts to enable realtime scheduling in a process of
the unit are refused. This restricts access to realtime task scheduling policies such as
C<SCHED_FIFO>, C<SCHED_RR> or C<SCHED_DEADLINE>. See
L<sched(7)> for details about
these scheduling policies. Realtime scheduling policies may be used to monopolize CPU time for longer periods
of time, and may hence be used to lock up or otherwise trigger Denial-of-Service situations on the system. It
is hence recommended to restrict access to realtime scheduling to the few programs that actually require
them. Defaults to off.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      }
    ],
    'generated_by' => 'parse-man.pl from systemd doc',
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Common::Exec'
  }
]
;


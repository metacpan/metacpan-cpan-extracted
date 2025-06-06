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
    'class_description' => 'A unit configuration file whose name ends in
C<.service> encodes information about a process
controlled and supervised by systemd.

This man page lists the configuration options specific to
this unit type. See
L<systemd.unit(5)>
for the common options of all unit configuration files. The common
configuration items are configured in the generic
[Unit] and [Install]
sections. The service specific configuration options are
configured in the [Service] section.

Additional options are listed in
L<systemd.exec(5)>,
which define the execution environment the commands are executed
in, and in
L<systemd.kill(5)>,
which define the way the processes of the service are terminated,
and in
L<systemd.resource-control(5)>,
which configure resource control settings for the processes of the
service.

If SysV init compat is enabled, systemd automatically creates service units that wrap SysV init
scripts (the service name is the same as the name of the script, with a C<.service>
suffix added); see
L<systemd-sysv-generator(8)>.


The L<systemd-run(1)>
command allows creating C<.service> and C<.scope> units dynamically
and transiently from the command line.
This configuration class was generated from systemd documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>
',
    'copyright' => [
      '2010-2016 Lennart Poettering and others',
      '2016 Dominique Dumont'
    ],
    'element' => [
      'Type',
      {
        'description' => "Configures the mechanism via which the service notifies the manager that the service start-up
has finished. One of C<simple>, C<exec>, C<forking>,
C<oneshot>, C<dbus>, C<notify>,
C<notify-reload>, or C<idle>:

It is recommended to use C<Type>=C<exec> for long-running
services, as it ensures that process setup errors (e.g. errors such as a missing service
executable, or missing user) are properly tracked. However, as this service type won't propagate
the failures in the service's own startup code (as opposed to failures in the preparatory steps the
service manager executes before execve()) and doesn't allow ordering of other
units against completion of initialization of the service code itself (which for example is useful
if clients need to connect to the service through some form of IPC, and the IPC channel is only
established by the service itself \x{2014} in contrast to doing this ahead of time through socket or bus
activation or similar), it might not be sufficient for many cases. If so, C<notify>,
C<notify-reload>, or C<dbus> (the latter only in case the service
provides a D-Bus interface) are the preferred options as they allow service program code to
precisely schedule when to consider the service started up successfully and when to proceed with
follow-up units. The C<notify>/C<notify-reload> service types require
explicit support in the service codebase (as sd_notify() or an equivalent API
needs to be invoked by the service at the appropriate time) \x{2014} if it's not supported, then
C<forking> is an alternative: it supports the traditional heavy-weight UNIX service
start-up protocol. Note that using any type other than C<simple> possibly delays the
boot process, as the service manager needs to wait for at least some service initialization to
complete. (Also note it is generally not recommended to use C<idle> or
C<oneshot> for long-running services.)

Note that various service settings (e.g. C<User>, C<Group>
through libc NSS) might result in \"hidden\" blocking IPC calls to other services when
used. Sometimes it might be advisable to use the C<simple> service type to ensure
that the service manager's transaction logic is not affected by such potentially slow operations
and hidden dependencies, as this is the only service type where the service manager will not wait
for such service execution setup operations to complete before proceeding.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ExitType',
      {
        'description' => 'Specifies when the manager should consider the service to be finished. One of C<main> or
C<cgroup>:

It is generally recommended to use C<ExitType>=C<main> when a service has
a known forking model and a main process can reliably be determined. C<ExitType>=C<cgroup> is meant for applications
whose forking model is not known ahead of time and which
might not have a specific main process. It is well suited for transient or automatically generated services,
such as graphical applications inside of a desktop environment.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RemainAfterExit',
      {
        'description' => 'Takes a boolean value that specifies whether
the service shall be considered active even when all its
processes exited. Defaults to C<no>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'GuessMainPID',
      {
        'description' => 'Takes a boolean value that specifies whether
systemd should try to guess the main PID of a service if it
cannot be determined reliably. This option is ignored unless
C<Type=forking> is set and
C<PIDFile> is unset because for the other types
or with an explicitly configured PID file, the main PID is
always known. The guessing algorithm might come to incorrect
conclusions if a daemon consists of more than one process. If
the main PID cannot be determined, failure detection and
automatic restarting of a service will not work reliably.
Defaults to C<yes>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PIDFile',
      {
        'description' => 'Takes a path referring to the PID file of the service. Usage of this option is recommended for
services where C<Type> is set to C<forking>. The path specified typically points
to a file below C</run/>. If a relative path is specified it is hence prefixed with
C</run/>. The service manager will read the PID of the main process of the service from this
file after start-up of the service. The service manager will not write to the file configured here, although it
will remove the file after the service has shut down if it still exists. The PID file does not need to be owned
by a privileged user, but if it is owned by an unprivileged user additional safety restrictions are enforced:
the file may not be a symlink to a file owned by a different user (neither directly nor indirectly), and the
PID file must refer to a process already belonging to the service.

Note that PID files should be avoided in modern projects. Use C<Type=notify>,
C<Type=notify-reload> or C<Type=simple> where possible, which does not
require use of PID files to determine the main process of a service and avoids needless
forking.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'BusName',
      {
        'description' => 'Takes a D-Bus destination name that this service shall use. This option is mandatory
for services where C<Type> is set to C<dbus>. It is recommended to
always set this property if known to make it easy to map the service name to the D-Bus destination.
In particular, systemctl service-log-level/service-log-target verbs make use of
this.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ExecStart',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Commands that are executed when this service is started.

Unless C<Type> is C<oneshot>, exactly one command must be
given. When C<Type=oneshot> is used, this setting may be used multiple times to
define multiple commands to execute. If the empty string is assigned to this option, the list of
commands to start is reset, prior assignments of this option will have no effect. If no
C<ExecStart> is specified, then the service must have
C<RemainAfterExit=yes> and at least one C<ExecStop> line
set. (Services lacking both C<ExecStart> and C<ExecStop> are not
valid.)

If more than one command is configured, the commands are invoked sequentially in the order they
appear in the unit file. If one of the commands fails (and is not prefixed with
C<->), other lines are not executed, and the unit is considered failed.

Unless C<Type=forking> is set, the process started via this command line will
be considered the main process of the daemon.',
        'type' => 'list'
      },
      'ExecStartPre',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Additional commands that are executed before or after the command in
C<ExecStart>, respectively. Syntax is the same as for C<ExecStart>.
Multiple command lines are allowed, regardless of the service type (i.e. C<Type>),
and the commands are executed one after the other, serially.

If any of those commands (not prefixed with
C<->) fail, the rest are not executed and the
unit is considered failed.

C<ExecStart> commands are only run after
all C<ExecStartPre> commands that were not prefixed
with a C<-> exit successfully.

C<ExecStartPost> commands are only run after the commands specified in
C<ExecStart> have been invoked successfully, as determined by
C<Type> (i.e. the process has been started for C<Type=simple> or
C<Type=idle>, the last C<ExecStart> process exited successfully for
C<Type=oneshot>, the initial process exited successfully for
C<Type=forking>, C<READY=1> is sent for
C<Type=notify>/C<Type=notify-reload>, or the
C<BusName> has been taken for C<Type=dbus>).

Note that C<ExecStartPre> may not be
used to start long-running processes. All processes forked
off by processes invoked via C<ExecStartPre> will
be killed before the next service process is run.

Note that if any of the commands specified in C<ExecStartPre>,
C<ExecStart>, or C<ExecStartPost> fail (and are not prefixed with
C<->, see above) or time out before the service is fully up, execution continues with commands
specified in C<ExecStopPost>, the commands in C<ExecStop> are skipped.

Note that the execution of C<ExecStartPost> is taken into account for the purpose of
C<Before>/C<After> ordering constraints.',
        'type' => 'list'
      },
      'ExecStartPost',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Additional commands that are executed before or after the command in
C<ExecStart>, respectively. Syntax is the same as for C<ExecStart>.
Multiple command lines are allowed, regardless of the service type (i.e. C<Type>),
and the commands are executed one after the other, serially.

If any of those commands (not prefixed with
C<->) fail, the rest are not executed and the
unit is considered failed.

C<ExecStart> commands are only run after
all C<ExecStartPre> commands that were not prefixed
with a C<-> exit successfully.

C<ExecStartPost> commands are only run after the commands specified in
C<ExecStart> have been invoked successfully, as determined by
C<Type> (i.e. the process has been started for C<Type=simple> or
C<Type=idle>, the last C<ExecStart> process exited successfully for
C<Type=oneshot>, the initial process exited successfully for
C<Type=forking>, C<READY=1> is sent for
C<Type=notify>/C<Type=notify-reload>, or the
C<BusName> has been taken for C<Type=dbus>).

Note that C<ExecStartPre> may not be
used to start long-running processes. All processes forked
off by processes invoked via C<ExecStartPre> will
be killed before the next service process is run.

Note that if any of the commands specified in C<ExecStartPre>,
C<ExecStart>, or C<ExecStartPost> fail (and are not prefixed with
C<->, see above) or time out before the service is fully up, execution continues with commands
specified in C<ExecStopPost>, the commands in C<ExecStop> are skipped.

Note that the execution of C<ExecStartPost> is taken into account for the purpose of
C<Before>/C<After> ordering constraints.',
        'type' => 'list'
      },
      'ExecCondition',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Optional commands that are executed before the commands in
C<ExecStartPre>. Syntax is the same as for C<ExecStart>. Multiple
command lines are allowed, regardless of the service type (i.e. C<Type>), and the
commands are executed one after the other, serially.

The behavior is like an C<ExecStartPre> and condition check hybrid: when an
C<ExecCondition> command exits with exit code 1 through 254 (inclusive), the remaining
commands are skipped and the unit is not marked as failed. However, if an
C<ExecCondition> command exits with 255 or abnormally (e.g. timeout, killed by a
signal, etc.), the unit will be considered failed (and remaining commands will be skipped). Exit code of 0 or
those matching C<SuccessExitStatus> will continue execution to the next commands.

The same recommendations about not running long-running processes in C<ExecStartPre>
also applies to C<ExecCondition>. C<ExecCondition> will also run the commands
in C<ExecStopPost>, as part of stopping the service, in the case of any non-zero or abnormal
exits, like the ones described above.',
        'type' => 'list'
      },
      'ExecReload',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Commands to execute to trigger a configuration reload in the service. This argument
takes multiple command lines, following the same scheme as described for
C<ExecStart> above. Use of this setting is optional. Specifier and environment
variable substitution is supported here following the same scheme as for
C<ExecStart>.

One additional, special environment variable is set: if known, C<$MAINPID> is
set to the main process of the daemon, and may be used for command lines like the following:

    ExecReload=kill -HUP $MAINPID

Note however that reloading a daemon by enqueuing a signal (as with the example line above) is
usually not a good choice, because this is an asynchronous operation and hence not suitable when
ordering reloads of multiple services against each other. It is thus strongly recommended to either
use C<Type>=C<notify-reload> in place of
C<ExecReload>, or to set C<ExecReload> to a command that not only
triggers a configuration reload of the daemon, but also synchronously waits for it to complete. For
example, L<dbus-broker(1)>
uses the following:

    ExecReload=busctl call org.freedesktop.DBus \\
    /org/freedesktop/DBus org.freedesktop.DBus \\
    ReloadConfig
',
        'type' => 'list'
      },
      'ExecStop',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Commands to execute to stop the service started via
C<ExecStart>. This argument takes multiple command lines, following the same scheme
as described for C<ExecStart> above. Use of this setting is optional. After the
commands configured in this option are run, it is implied that the service is stopped, and any
processes remaining for it are terminated according to the C<KillMode> setting (see
L<systemd.kill(5)>).
If this option is not specified, the process is terminated by sending the signal specified in
C<KillSignal> or C<RestartKillSignal> when service stop is
requested. Specifier and environment variable substitution is supported (including
C<$MAINPID>, see above).

Note that it is usually not sufficient to specify a command for this setting that only asks the
service to terminate (for example, by sending some form of termination signal to it), but does not
wait for it to do so. Since the remaining processes of the services are killed according to
C<KillMode> and C<KillSignal> or
C<RestartKillSignal> as described above immediately after the command exited, this
may not result in a clean stop. The specified command should hence be a synchronous operation, not an
asynchronous one.

Note that the commands specified in C<ExecStop> are only executed when the service
started successfully first. They are not invoked if the service was never started at all, or in case its
start-up failed, for example because any of the commands specified in C<ExecStart>,
C<ExecStartPre> or C<ExecStartPost> failed (and weren\'t prefixed with
C<->, see above) or timed out. Use C<ExecStopPost> to invoke commands when a
service failed to start up correctly and is shut down again. Also note that the stop operation is always
performed if the service started successfully, even if the processes in the service terminated on their
own or were killed. The stop commands must be prepared to deal with that case. C<$MAINPID>
will be unset if systemd knows that the main process exited by the time the stop commands are called.

Service restart requests are implemented as stop operations followed by start operations. This
means that C<ExecStop> and C<ExecStopPost> are executed during a
service restart operation.

It is recommended to use this setting for commands that communicate with the service requesting
clean termination. For post-mortem clean-up steps use C<ExecStopPost> instead.
',
        'type' => 'list'
      },
      'ExecStopPost',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "Additional commands that are executed after the service is stopped. This includes cases where
the commands configured in C<ExecStop> were used, where the service does not have any
C<ExecStop> defined, or where the service exited unexpectedly. This argument takes multiple
command lines, following the same scheme as described for C<ExecStart>. Use of these settings
is optional. Specifier and environment variable substitution is supported. Note that \x{2013} unlike
C<ExecStop> \x{2013} commands specified with this setting are invoked when a service failed to start
up correctly and is shut down again.

It is recommended to use this setting for clean-up operations that shall be executed even when
the service failed to start up correctly. Commands configured with this setting need to be able to
operate even if the service failed starting up half-way and left incompletely initialized data
around. As the service's processes have likely exited already when the commands specified with this
setting are executed they should not attempt to communicate with them.

Note that all commands that are configured with this setting are invoked with the result code of the
service, as well as the main process' exit code and status, set in the C<\$SERVICE_RESULT>,
C<\$EXIT_CODE> and C<\$EXIT_STATUS> environment variables, see
L<systemd.exec(5)> for
details.

Note that the execution of C<ExecStopPost> is taken into account for the purpose of
C<Before>/C<After> ordering constraints.",
        'type' => 'list'
      },
      'RestartSec',
      {
        'description' => 'Configures the time to sleep before restarting
a service (as configured with C<Restart>).
Takes a unit-less value in seconds, or a time span value such
as "5min 20s". Defaults to 100ms.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestartSteps',
      {
        'description' => 'Configures the number of steps to take to increase the interval
of auto-restarts from C<RestartSec> to C<RestartMaxDelaySec>.
Takes a positive integer or 0 to disable it. Defaults to 0.

This setting is effective only if C<RestartMaxDelaySec> is also set.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestartMaxDelaySec',
      {
        'description' => 'Configures the longest time to sleep before restarting a service
as the interval goes up with C<RestartSteps>. Takes a value
in the same format as C<RestartSec>, or C<infinity>
to disable the setting. Defaults to C<infinity>.

This setting is effective only if C<RestartSteps> is also set.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TimeoutStartSec',
      {
        'description' => "Configures the time to wait for start-up. If a daemon service does not signal
start-up completion within the configured time, the service will be considered failed and will be
shut down again. The precise action depends on the C<TimeoutStartFailureMode>
option. Takes a unit-less value in seconds, or a time span value such as \"5min 20s\". Pass
C<infinity> to disable the timeout logic. Defaults to
C<DefaultTimeoutStartSec> set in the manager, except when
C<Type=oneshot> is used, in which case the timeout is disabled by default (see
L<systemd-system.conf(5)>).

If a service of C<Type=notify>/C<Type=notify-reload> sends
C<EXTEND_TIMEOUT_USEC=\x{2026}>, this may cause the start time to be extended beyond
C<TimeoutStartSec>. The first receipt of this message must occur before
C<TimeoutStartSec> is exceeded, and once the start time has extended beyond
C<TimeoutStartSec>, the service manager will allow the service to continue to start,
provided the service repeats C<EXTEND_TIMEOUT_USEC=\x{2026}> within the interval specified
until the service startup status is finished by C<READY=1>. (see
L<sd_notify(3)>).

Note that the start timeout is also applied to service reloads, regardless if implemented
through C<ExecReload> or via the reload logic enabled via C<Type=notify-reload>.
If the reload does not complete within the configured time, the reload will be considered failed and
the service will continue running with the old configuration. This will not affect the running service,
but will be logged and will cause e.g. systemctl reload to fail.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TimeoutStopSec',
      {
        'description' => "This option serves two purposes. First, it configures the time to wait for each
C<ExecStop> command. If any of them times out, subsequent C<ExecStop> commands
are skipped and the service will be terminated by C<SIGTERM>. If no C<ExecStop>
commands are specified, the service gets the C<SIGTERM> immediately. This default behavior
can be changed by the C<TimeoutStopFailureMode> option. Second, it configures the time
to wait for the service itself to stop. If it doesn't terminate in the specified time, it will be forcibly terminated
by C<SIGKILL> (see C<KillMode> in
L<systemd.kill(5)>).
Takes a unit-less value in seconds, or a time span value such
as \"5min 20s\". Pass C<infinity> to disable the
timeout logic. Defaults to
C<DefaultTimeoutStopSec> from the manager
configuration file (see
L<systemd-system.conf(5)>).

If a service of C<Type=notify>/C<Type=notify-reload> sends
C<EXTEND_TIMEOUT_USEC=\x{2026}>, this may cause the stop time to be extended beyond
C<TimeoutStopSec>. The first receipt of this message must occur before
C<TimeoutStopSec> is exceeded, and once the stop time has extended beyond
C<TimeoutStopSec>, the service manager will allow the service to continue to stop,
provided the service repeats C<EXTEND_TIMEOUT_USEC=\x{2026}> within the interval specified,
or terminates itself (see
L<sd_notify(3)>).
",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TimeoutAbortSec',
      {
        'description' => "This option configures the time to wait for the service to terminate when it was aborted due to a
watchdog timeout (see C<WatchdogSec>). If the service has a short C<TimeoutStopSec>
this option can be used to give the system more time to write a core dump of the service. Upon expiration the service
will be forcibly terminated by C<SIGKILL> (see C<KillMode> in
L<systemd.kill(5)>). The core file will
be truncated in this case. Use C<TimeoutAbortSec> to set a sensible timeout for the core dumping per
service that is large enough to write all expected data while also being short enough to handle the service failure
in due time.

Takes a unit-less value in seconds, or a time span value such as \"5min 20s\". Pass an empty value to skip
the dedicated watchdog abort timeout handling and fall back C<TimeoutStopSec>. Pass
C<infinity> to disable the timeout logic. Defaults to C<DefaultTimeoutAbortSec> from
the manager configuration file (see
L<systemd-system.conf(5)>).

If a service of C<Type=notify>/C<Type=notify-reload> handles
C<SIGABRT> itself (instead of relying on the kernel to write a core dump) it can
send C<EXTEND_TIMEOUT_USEC=\x{2026}> to extended the abort time beyond
C<TimeoutAbortSec>. The first receipt of this message must occur before
C<TimeoutAbortSec> is exceeded, and once the abort time has extended beyond
C<TimeoutAbortSec>, the service manager will allow the service to continue to abort,
provided the service repeats C<EXTEND_TIMEOUT_USEC=\x{2026}> within the interval specified,
or terminates itself (see
L<sd_notify(3)>).
",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TimeoutSec',
      {
        'description' => 'A shorthand for configuring both
C<TimeoutStartSec> and
C<TimeoutStopSec> to the specified value.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TimeoutStartFailureMode',
      {
        'choice' => [
          'abort',
          'kill',
          'terminate'
        ],
        'description' => 'These options configure the action that is taken in case a daemon service does not signal
start-up within its configured C<TimeoutStartSec>, respectively if it does not stop within
C<TimeoutStopSec>. Takes one of C<terminate>, C<abort> and
C<kill>. Both options default to C<terminate>.

If C<terminate> is set the service will be gracefully terminated by sending the signal
specified in C<KillSignal> (defaults to C<SIGTERM>, see
L<systemd.kill(5)>). If the
service does not terminate the C<FinalKillSignal> is sent after
C<TimeoutStopSec>. If C<abort> is set, C<WatchdogSignal> is sent
instead and C<TimeoutAbortSec> applies before sending C<FinalKillSignal>.
This setting may be used to analyze services that fail to start-up or shut-down intermittently.
By using C<kill> the service is immediately terminated by sending
C<FinalKillSignal> without any further timeout. This setting can be used to expedite the
shutdown of failing services.
',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'TimeoutStopFailureMode',
      {
        'choice' => [
          'abort',
          'kill',
          'terminate'
        ],
        'description' => 'These options configure the action that is taken in case a daemon service does not signal
start-up within its configured C<TimeoutStartSec>, respectively if it does not stop within
C<TimeoutStopSec>. Takes one of C<terminate>, C<abort> and
C<kill>. Both options default to C<terminate>.

If C<terminate> is set the service will be gracefully terminated by sending the signal
specified in C<KillSignal> (defaults to C<SIGTERM>, see
L<systemd.kill(5)>). If the
service does not terminate the C<FinalKillSignal> is sent after
C<TimeoutStopSec>. If C<abort> is set, C<WatchdogSignal> is sent
instead and C<TimeoutAbortSec> applies before sending C<FinalKillSignal>.
This setting may be used to analyze services that fail to start-up or shut-down intermittently.
By using C<kill> the service is immediately terminated by sending
C<FinalKillSignal> without any further timeout. This setting can be used to expedite the
shutdown of failing services.
',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'RuntimeMaxSec',
      {
        'description' => "Configures a maximum time for the service to run. If this is used and the service has been
active for longer than the specified time it is terminated and put into a failure state. Note that this setting
does not have any effect on C<Type=oneshot> services, as they terminate immediately after
activation completed (use C<TimeoutStartSec> to limit their activation).
Pass C<infinity> (the default) to configure no runtime limit.

If a service of C<Type=notify>/C<Type=notify-reload> sends
C<EXTEND_TIMEOUT_USEC=\x{2026}>, this may cause the runtime to be extended beyond
C<RuntimeMaxSec>. The first receipt of this message must occur before
C<RuntimeMaxSec> is exceeded, and once the runtime has extended beyond
C<RuntimeMaxSec>, the service manager will allow the service to continue to run,
provided the service repeats C<EXTEND_TIMEOUT_USEC=\x{2026}> within the interval specified
until the service shutdown is achieved by C<STOPPING=1> (or termination). (see
L<sd_notify(3)>).
",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RuntimeRandomizedExtraSec',
      {
        'description' => 'This option modifies C<RuntimeMaxSec> by increasing the maximum runtime by an
evenly distributed duration between 0 and the specified value (in seconds). If C<RuntimeMaxSec> is
unspecified, then this feature will be disabled.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'WatchdogSec',
      {
        'description' => 'Configures the watchdog timeout for a service.
The watchdog is activated when the start-up is completed. The
service must call
L<sd_notify(3)>
regularly with C<WATCHDOG=1> (i.e. the
"keep-alive ping"). If the time between two such calls is
larger than the configured time, then the service is placed in
a failed state and it will be terminated with
C<SIGABRT> (or the signal specified by
C<WatchdogSignal>). By setting
C<Restart> to C<on-failure>,
C<on-watchdog>, C<on-abnormal> or
C<always>, the service will be automatically
restarted. The time configured here will be passed to the
executed service process in the
C<WATCHDOG_USEC> environment variable. This
allows daemons to automatically enable the keep-alive pinging
logic if watchdog support is enabled for the service. If this
option is used, C<NotifyAccess> (see below)
should be set to open access to the notification socket
provided by systemd. If C<NotifyAccess> is
not set, it will be implicitly set to C<main>.
Defaults to 0, which disables this feature. The service can
check whether the service manager expects watchdog keep-alive
notifications. See
L<sd_watchdog_enabled(3)>
for details.
L<sd_event_set_watchdog(3)>
may be used to enable automatic watchdog notification support.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Restart',
      {
        'choice' => [
          'always',
          'no',
          'on-abnormal',
          'on-abort',
          'on-failure',
          'on-success',
          'on-watchdog'
        ],
        'description' => 'Configures whether the service shall be restarted when the service process exits,
is killed, or a timeout is reached. The service process may be the main service process, but it may
also be one of the processes specified with C<ExecStartPre>,
C<ExecStartPost>, C<ExecStop>, C<ExecStopPost>,
or C<ExecReload>. When the death of the process is a result of systemd operation
(e.g. service stop or restart), the service will not be restarted. Timeouts include missing the watchdog
"keep-alive ping" deadline and a service start, reload, and stop operation timeouts.

Takes one of C<no>, C<on-success>, C<on-failure>,
C<on-abnormal>, C<on-watchdog>, C<on-abort>, or
C<always>. If set to C<no> (the default), the service will not be restarted.
If set to C<on-success>, it will be restarted only when the service process exits cleanly.
In this context, a clean exit means any of the following:
exit code of 0;for types other than C<Type=oneshot>, one of the signals
C<SIGHUP>, C<SIGINT>,
C<SIGTERM>, or C<SIGPIPE>;
exit statuses and signals specified in
C<SuccessExitStatus>.
If set to C<on-failure>, the service will be restarted when the process exits with
a non-zero exit code, is terminated by a signal (including on core dump, but excluding the aforementioned
four signals), when an operation (such as service reload) times out, and when the configured watchdog
timeout is triggered. If set to C<on-abnormal>, the service will be restarted when
the process is terminated by a signal (including on core dump, excluding the aforementioned four signals),
when an operation times out, or when the watchdog timeout is triggered. If set to C<on-abort>,
the service will be restarted only if the service process exits due to an uncaught signal not specified
as a clean exit status. If set to C<on-watchdog>, the service will be restarted
only if the watchdog timeout for the service expires. If set to C<always>, the service
will be restarted regardless of whether it exited cleanly or not, got terminated abnormally by
a signal, or hit a timeout. Note that C<Type=oneshot> services will never be restarted
on a clean exit status, i.e. C<always> and C<on-success> are rejected
for them.

As exceptions to the setting above, the service will not
be restarted if the exit code or signal is specified in
C<RestartPreventExitStatus> (see below) or
the service is stopped with systemctl stop
or an equivalent operation. Also, the services will always be
restarted if the exit code or signal is specified in
C<RestartForceExitStatus> (see below).

Note that service restart is subject to unit start rate
limiting configured with C<StartLimitIntervalSec>
and C<StartLimitBurst>, see
L<systemd.unit(5)>
for details.

Setting this to C<on-failure> is the
recommended choice for long-running services, in order to
increase reliability by attempting automatic recovery from
errors. For services that shall be able to terminate on their
own choice (and avoid immediate restarting),
C<on-abnormal> is an alternative choice.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'RestartMode',
      {
        'description' => 'Takes a string value that specifies how a service should restart:
If set to C<normal> (the default), the service restarts by going through
a failed/inactive state.If set to C<direct>, the service transitions to the activating
state directly during auto-restart, skipping failed/inactive state.
C<ExecStopPost> is still invoked.
C<OnSuccess> and C<OnFailure> are skipped.This option is useful in cases where a dependency can fail temporarily but we
don\'t
want these temporary failures to make the dependent units fail. Dependent units are not
notified of these temporary failures.If set to C<debug>, the service manager will log messages that are
related to this unit at debug level while automated restarts are attempted, until either the
service hits the rate limit or it succeeds, and the C<$DEBUG_INVOCATION=1>
environment variable will be set for the unit. This is useful to be able to get additional
information when a service fails to start, without needing to proactively or permanently
enable debug level logging in systemd, which is very verbose. This is otherwise equivalent
to C<normal> mode.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SuccessExitStatus',
      {
        'description' => 'Takes a list of exit status definitions that, when returned by the main service
process, will be considered successful termination, in addition to the normal successful exit status
0 and, except for C<Type=oneshot>, the signals C<SIGHUP>, C<SIGINT>,
C<SIGTERM>, and C<SIGPIPE>. Exit status definitions can be
numeric termination statuses, termination status names, or termination signal names, separated by
spaces. See the Process Exit Codes section in
L<systemd.exec(5)> for
a list of termination status names (for this setting only the part without the
C<EXIT_> or C<EX_> prefix should be used). See L<signal(7)> for
a list of signal names.

Note that this setting does not change the mapping between numeric exit statuses and their
names, i.e. regardless how this setting is used 0 will still be mapped to C<SUCCESS>
(and thus typically shown as C<0/SUCCESS> in tool outputs) and 1 to
C<FAILURE> (and thus typically shown as C<1/FAILURE>), and so on. It
only controls what happens as effect of these exit statuses, and how it propagates to the state of
the service as a whole.

This option may appear more than once, in which case the list of successful exit statuses is
merged. If the empty string is assigned to this option, the list is reset, all prior assignments of
this option will have no effect.

Note: systemd-analyze exit-status may be used to list exit statuses and
translate between numerical status values and names.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestartPreventExitStatus',
      {
        'description' => "Takes a list of exit status definitions that, when returned by the main service
process, will prevent automatic service restarts, regardless of the restart setting configured with
C<Restart>. Exit status definitions can be numeric termination statuses, termination
status names, or termination signal names, separated by spaces. Defaults to the empty list, so that,
by default, no exit status is excluded from the configured restart logic.
A service with the C<RestartPreventExitStatus> setting
    RestartPreventExitStatus=TEMPFAIL 250 SIGKILL
Exit status 75 (C<TEMPFAIL>), 250, and the termination signal
C<SIGKILL> will not result in automatic service restarting.
This option may appear more than once, in which case the list of restart-preventing statuses is merged.
If the empty string is assigned to this option, the list is reset and all prior assignments of this
option will have no effect.

Note that this setting has no effect on processes configured via
C<ExecStartPre>, C<ExecStartPost>, C<ExecStop>,
C<ExecStopPost> or C<ExecReload>, but only on the main service
process, i.e. either the one invoked by C<ExecStart> or (depending on
C<Type>, C<PIDFile>, \x{2026}) the otherwise configured main
process.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestartForceExitStatus',
      {
        'description' => 'Takes a list of exit status definitions that, when returned by the main service
process, will force automatic service restarts, regardless of the restart setting configured with
C<Restart>. The argument format is similar to C<RestartPreventExitStatus>.

Note that for C<Type=oneshot> services, a success exit status will prevent
them from auto-restarting, no matter whether the corresponding exit statuses are listed in this
option or not.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RootDirectoryStartOnly',
      {
        'description' => 'Takes a boolean argument. If true, the root
directory, as configured with the
C<RootDirectory> option (see
L<systemd.exec(5)>
for more information), is only applied to the process started
with C<ExecStart>, and not to the various
other C<ExecStartPre>,
C<ExecStartPost>,
C<ExecReload>, C<ExecStop>,
and C<ExecStopPost> commands. If false, the
setting is applied to all configured commands the same way.
Defaults to false.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'NonBlocking',
      {
        'description' => 'Set the C<O_NONBLOCK> flag for all file descriptors passed via
socket-based activation. If true, all file descriptors >= 3 (i.e. all except stdin, stdout, stderr),
excluding those passed in via the file descriptor storage logic (see
C<FileDescriptorStoreMax> for details), will have the
C<O_NONBLOCK> flag set and hence are in non-blocking mode. This option is only
useful in conjunction with a socket unit, as described in
L<systemd.socket(5)>
and has no effect on file descriptors which were previously saved in the file-descriptor store for
example.  Defaults to false.

Note that if the same socket unit is configured to be passed to multiple service units (via the
C<Sockets> setting, see below), and these services have different
C<NonBlocking> configurations, the precise state of C<O_NONBLOCK>
depends on the order in which these services are invoked, and will possibly change after service code
already took possession of the socket file descriptor, simply because the
C<O_NONBLOCK> state of a socket is shared by all file descriptors referencing
it. Hence it is essential that all services sharing the same socket use the same
C<NonBlocking> configuration, and do not change the flag in service code
either.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'NotifyAccess',
      {
        'choice' => [
          'all',
          'exec',
          'main',
          'none'
        ],
        'description' => 'Controls access to the service status notification socket, as accessible via the
L<sd_notify(3)>
call. Takes one of C<none> (the default), C<main>, C<exec>
or C<all>. If C<none>, no daemon status updates are accepted from the
service processes, all status update messages are ignored. If C<main>, only service
updates sent from the main process of the service are accepted. If C<exec>, only
service updates sent from any of the main or control processes originating from one of the
C<Exec*=> commands are accepted. If C<all>, all services updates from
all members of the service\'s control group are accepted. This option should be set to open access to
the notification socket when using
C<Type=notify>/C<Type=notify-reload> or
C<WatchdogSec> (see above). If those options are used but
C<NotifyAccess> is not configured, it will be implicitly set to
C<main>.

Note that sd_notify() notifications may be attributed to units correctly only if
either the sending process is still around at the time PID 1 processes the message, or if the sending process
is explicitly runtime-tracked by the service manager. The latter is the case if the service manager originally
forked off the process, i.e. on all processes that match C<main> or
C<exec>. Conversely, if an auxiliary process of the unit sends an
sd_notify() message and immediately exits, the service manager might not be able to
properly attribute the message to the unit, and thus will ignore it, even if
C<NotifyAccess>=C<all> is set for it.

Hence, to eliminate all race conditions involving lookup of the client\'s unit and attribution of notifications
to units correctly, sd_notify_barrier() may be used. This call acts as a synchronization point
and ensures all notifications sent before this call have been picked up by the service manager when it returns
successfully. Use of sd_notify_barrier() is needed for clients which are not invoked by the
service manager, otherwise this synchronization mechanism is unnecessary for attribution of notifications to the
unit.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'Sockets',
      {
        'description' => 'Specifies the name of the socket units this
service shall inherit socket file descriptors from when the
service is started. Normally, it should not be necessary to use
this setting, as all socket file descriptors whose unit shares
the same name as the service (subject to the different unit
name suffix of course) are passed to the spawned
process.

Note that the same socket file descriptors may be passed
to multiple processes simultaneously. Also note that a
different service may be activated on incoming socket traffic
than the one which is ultimately configured to inherit the
socket file descriptors. Or, in other words: the
C<Service> setting of
C<.socket> units does not have to match the
inverse of the C<Sockets> setting of the
C<.service> it refers to.

This option may appear more than once, in which case the list of socket units is merged. Note
that once set, clearing the list of sockets again (for example, by assigning the empty string to this
option) is not supported.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'FileDescriptorStoreMax',
      {
        'description' => 'Configure how many file descriptors may be stored in the service manager for the
service using
L<sd_pid_notify_with_fds(3)>\'s
C<FDSTORE=1> messages. This is useful for implementing services that can restart
after an explicit request or a crash without losing state. Any open sockets and other file
descriptors which should not be closed during the restart may be stored this way. Application state
can either be serialized to a file in C<RuntimeDirectory>, or stored in a
L<memfd_create(2)>
memory file descriptor. Defaults to 0, i.e. no file descriptors may be stored in the service
manager. All file descriptors passed to the service manager from a specific service are passed back
to the service\'s main process on the next service restart (see
L<sd_listen_fds(3)> for
details about the precise protocol used and the order in which the file descriptors are passed). Any
file descriptors passed to the service manager are automatically closed when
C<POLLHUP> or C<POLLERR> is seen on them, or when the service is
fully stopped and no job is queued or being executed for it (the latter can be tweaked with
C<FileDescriptorStorePreserve>, see below). If this option is used,
C<NotifyAccess> (see above) should be set to open access to the notification socket
provided by systemd. If C<NotifyAccess> is not set, it will be implicitly set to
C<main>.

The fdstore command of
L<systemd-analyze(1)>
may be used to list the current contents of a service\'s file descriptor store.

Note that the service manager will only pass file descriptors contained in the file descriptor
store to the service\'s own processes, never to other clients via IPC or similar. However, it does
allow unprivileged clients to query the list of currently open file descriptors of a
service. Sensitive data may hence be safely placed inside the referenced files, but should not be
attached to the metadata (e.g. included in filenames) of the stored file
descriptors.

If this option is set to a non-zero value the C<$FDSTORE> environment variable
will be set for processes invoked for this service. See
L<systemd.exec(5)> for
details.

For further information on the file descriptor store see the L<File Descriptor
Store|https://systemd.io/FILE_DESCRIPTOR_STORE> overview.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'FileDescriptorStorePreserve',
      {
        'choice' => [
          'no',
          'restart',
          'yes'
        ],
        'description' => "Takes one of C<no>, C<yes>,
C<restart> and controls when to release the service's file descriptor store
(i.e. when to close the contained file descriptors, if any). If set to C<no> the
file descriptor store is automatically released when the service is stopped; if
C<restart> (the default) it is kept around as long as the unit is neither inactive
nor failed, or a job is queued for the service, or the service is expected to be restarted. If
C<yes> the file descriptor store is kept around until the unit is removed from
memory (i.e. is not referenced anymore and inactive). The latter is useful to keep entries in the
file descriptor store pinned until the service manager exits.

Use systemctl clean --what=fdstore \x{2026} to release the file descriptor store
explicitly.",
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'USBFunctionDescriptors',
      {
        'description' => 'Configure the location of a file containing
L<USB
FunctionFS|https://docs.kernel.org/usb/functionfs.html> descriptors, for implementation of USB
gadget functions. This is used only in conjunction with a
socket unit with C<ListenUSBFunction>
configured. The contents of this file are written to the
C<ep0> file after it is
opened.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'USBFunctionStrings',
      {
        'description' => 'Configure the location of a file containing
USB FunctionFS strings.  Behavior is similar to
C<USBFunctionDescriptors>
above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'OOMPolicy',
      {
        'description' => 'Configure the out-of-memory (OOM) killing policy for the kernel and the userspace OOM
killer
L<systemd-oomd.service(8)>.
On Linux, when memory becomes scarce to the point that the kernel has trouble allocating memory for
itself, it might decide to kill a running process in order to free up memory and reduce memory
pressure. Note that C<systemd-oomd.service> is a more flexible solution that aims
to prevent out-of-memory situations for the userspace too, not just the kernel, by attempting to
terminate services earlier, before the kernel would have to act.

This setting takes one of C<continue>, C<stop> or
C<kill>. If set to C<continue> and a process in the unit is
killed by the OOM killer, this is logged but the unit continues running. If set to
C<stop> the event is logged but the unit is terminated cleanly by the service
manager. If set to C<kill> and one of the unit\'s processes is killed by the OOM
killer the kernel is instructed to kill all remaining processes of the unit too, by setting the
C<memory.oom.group> attribute to C<1>; also see kernel
page L<Control Group v2|https://docs.kernel.org/admin-guide/cgroup-v2.html>.

Defaults to the setting C<DefaultOOMPolicy> in
L<systemd-system.conf(5)>
is set to, except for units where C<Delegate> is turned on, where it defaults to
C<continue>.

Use the C<OOMScoreAdjust> setting to configure whether processes of the unit
shall be considered preferred or less preferred candidates for process termination by the Linux OOM
killer logic. See
L<systemd.exec(5)> for
details.

This setting also applies to
L<systemd-oomd.service(8)>.
Similarly to the kernel OOM kills performed by the kernel, this setting determines the state of the
unit after systemd-oomd kills a cgroup associated with it.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'OpenFile',
      {
        'description' => 'Takes an argument of the form C<path:fd-name:options>,
where:
C<path> is a path to a file or an C<AF_UNIX> socket in the file system;C<fd-name> is a name that will be associated
with the file descriptor;
the name may contain any ASCII character, but must exclude control characters and ":", and must be at most 255
characters in length;
it is optional and, if not provided, defaults to the file name;C<options> is a comma-separated list of access options;
possible values are
C<read-only>,
C<append>,
C<truncate>,
C<graceful>;
if not specified, files will be opened in C<rw> mode;
if C<graceful> is specified, errors during file/socket opening are ignored.
Specifying the same option several times is treated as an error.
The file or socket is opened by the service manager and the file descriptor is passed to the service.
If the path is a socket, we call connect() on it.
See L<sd_listen_fds(3)>
for more details on how to retrieve these file descriptors.

This setting is useful to allow services to access files/sockets that they can\'t access themselves
(due to running in a separate mount namespace, not having privileges, ...).

This setting can be specified multiple times, in which case all the specified paths are opened and the file descriptors
passed to the service.
If the empty string is assigned, the entire list of open files defined prior to this is reset.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ReloadSignal',
      {
        'description' => 'Configures the UNIX process signal to send to the service\'s main process when asked
to reload the service\'s configuration. Defaults to C<SIGHUP>. This option has no
effect unless C<Type>=C<notify-reload> is used, see
above.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'FailureAction',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'FailureAction is now part of Unit.'
      },
      'SuccessAction',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'SuccessAction is now part of Unit.'
      },
      'StartLimitBurst',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'StartLimitBurst is now part of Unit.'
      },
      'StartLimitInterval',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'service/StartLimitInterval is now Unit/StartLimitIntervalSec.'
      },
      'RebootArgument',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'RebootArgument is now part of Unit.'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd doc',
    'include' => [
      'Systemd::Common::ResourceControl',
      'Systemd::Common::Exec',
      'Systemd::Common::Kill'
    ],
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Section::Service'
  }
]
;


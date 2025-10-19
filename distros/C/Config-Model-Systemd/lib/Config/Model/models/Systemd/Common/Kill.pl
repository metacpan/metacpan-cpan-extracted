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
    'class_description' => 'Unit configuration files for services, sockets, mount
points, swap devices and scopes share a subset of configuration
options which define the killing procedure of processes belonging
to the unit.

This man page lists the configuration options shared by
these five unit types. See
L<systemd.unit(5)>
for the common options shared by all unit configuration files, and
L<systemd.service(5)>,
L<systemd.socket(5)>,
L<systemd.swap(5)>,
L<systemd.mount(5)>
and
L<systemd.scope(5)>
for more information on the configuration file options specific to
each unit type.

The kill procedure configuration options are configured in
the [Service], [Socket], [Mount] or [Swap] section, depending on
the unit type.
This configuration class was generated from systemd documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>
',
    'copyright' => [
      '2010-2016 Lennart Poettering and others',
      '2016 Dominique Dumont'
    ],
    'element' => [
      'KillMode',
      {
        'description' => 'Specifies how processes of this unit shall be killed. One of
C<control-group>, C<mixed>, C<process>,
C<none>.

If set to C<control-group>, all remaining processes in the control group of this
unit will be killed on unit stop (for services: after the stop command is executed, as configured
with C<ExecStop>). If set to C<mixed>, the
C<SIGTERM> signal (see below) is sent to the main process while the subsequent
C<SIGKILL> signal (see below) is sent to all remaining processes of the unit\'s
control group. If set to C<process>, only the main process itself is killed (not
recommended!). If set to C<none>, no process is killed (strongly recommended
against!). In this case, only the stop command will be executed on unit stop, but no process will be
killed otherwise.  Processes remaining alive after stop are left in their control group and the
control group continues to exist after stop unless empty.

Note that it is not recommended to set C<KillMode> to
C<process> or even C<none>, as this allows processes to escape
the service manager\'s lifecycle and resource management, and to remain running even while their
service is considered stopped and is assumed to not consume any resources.

Processes will first be terminated via C<SIGTERM> (unless the signal to send
is changed via C<KillSignal> or C<RestartKillSignal>). Optionally,
this is immediately followed by a C<SIGHUP> (if enabled with
C<SendSIGHUP>). If processes still remain after:
the main process of a unit has exited (applies to C<KillMode>:
C<mixed>)the delay configured via the C<TimeoutStopSec> has passed
(applies to C<KillMode>: C<control-group>, C<mixed>,
C<process>)
the termination request is repeated with the C<SIGKILL> signal or the signal specified via
C<FinalKillSignal> (unless this is disabled via the C<SendSIGKILL>
option). See L<kill(2)>
for more information.

Defaults to C<control-group>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KillSignal',
      {
        'description' => 'Specifies which signal to use when stopping a service. This controls the signal that
is sent as first step of shutting down a unit (see above), and is usually followed by
C<SIGKILL> (see above and below). For a list of valid signals, see
L<signal(7)>.
Defaults to C<SIGTERM>.

Note that, right after sending the signal specified in this setting, systemd will always send
C<SIGCONT>, to ensure that even suspended tasks can be terminated cleanly.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RestartKillSignal',
      {
        'description' => 'Specifies which signal to use when restarting a service. The same as
C<KillSignal> described above, with the exception that this setting is used in a
restart job. Not set by default, and the value of C<KillSignal> is used.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SendSIGHUP',
      {
        'description' => 'Specifies whether to send
C<SIGHUP> to remaining processes immediately
after sending the signal configured with
C<KillSignal>. This is useful to indicate to
shells and shell-like programs that their connection has been
severed. Takes a boolean value. Defaults to C<no>.
',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'SendSIGKILL',
      {
        'description' => 'Specifies whether to send
C<SIGKILL> (or the signal specified by
C<FinalKillSignal>) to remaining processes
after a timeout, if the normal shutdown procedure left
processes of the service around. When disabled, a
C<KillMode> of C<control-group>
or C<mixed> service will not restart if
processes from prior services exist within the control group.
Takes a boolean value. Defaults to C<yes>.
',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'FinalKillSignal',
      {
        'description' => 'Specifies which signal to send to remaining
processes after a timeout if C<SendSIGKILL>
is enabled. The signal configured here should be one that is
not typically caught and processed by services (C<SIGTERM>
is not suitable). Developers can find it useful to use this to
generate a coredump to troubleshoot why a service did not
terminate upon receiving the initial C<SIGTERM>
signal. This can be achieved by configuring C<LimitCORE>
and setting C<FinalKillSignal> to either
C<SIGQUIT> or C<SIGABRT>.
Defaults to C<SIGKILL>.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'WatchdogSignal',
      {
        'description' => 'Specifies which signal to use to terminate the
service when the watchdog timeout expires (enabled through
C<WatchdogSec>). Defaults to C<SIGABRT>.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd 258 doc',
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Common::Kill'
  }
]
;


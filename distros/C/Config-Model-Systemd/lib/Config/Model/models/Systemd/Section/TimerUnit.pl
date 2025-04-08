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
        'warn' => '$unknown_param_msg'
      }
    ],
    'element' => [
      'FailureAction',
      {
        'choice' => [
          'exit',
          'exit-force',
          'halt',
          'halt-force',
          'halt-immediate',
          'kexec',
          'kexec-force',
          'none',
          'poweroff',
          'poweroff-force',
          'poweroff-immediate',
          'reboot',
          'reboot-force',
          'reboot-immediate',
          'soft-reboot',
          'soft-reboot-force'
        ],
        'description' => 'Configure the action to take when the unit stops and enters a failed state or
inactive state.  Takes one of C<none>, C<reboot>,
C<reboot-force>, C<reboot-immediate>, C<poweroff>,
C<poweroff-force>, C<poweroff-immediate>, C<exit>,
C<exit-force>, C<soft-reboot>, C<soft-reboot-force>,
C<kexec>, C<kexec-force>, C<halt>,
C<halt-force> and C<halt-immediate>. In system mode, all options are
allowed. In user mode, only C<none>, C<exit>, and
C<exit-force> are allowed. Both options default to C<none>.

If C<none> is set, no action will be triggered. C<reboot> causes a
reboot following the normal shutdown procedure (i.e. equivalent to systemctl
reboot).  C<reboot-force> causes a forced reboot which will terminate all
processes forcibly but should cause no dirty file systems on reboot (i.e. equivalent to
systemctl reboot -f) and C<reboot-immediate> causes immediate
execution of the
L<reboot(2)> system
call, which might result in data loss (i.e. equivalent to systemctl reboot -ff).
Similarly, C<poweroff>, C<poweroff-force>,
C<poweroff-immediate>, C<kexec>, C<kexec-force>,
C<halt>, C<halt-force> and C<halt-immediate> have the
effect of powering down the system, executing kexec, and halting the system respectively with similar
semantics. C<exit> causes the manager to exit following the normal shutdown procedure,
and C<exit-force> causes it terminate without shutting down services. When
C<exit> or C<exit-force> is used by default the exit status of the main
process of the unit (if this applies) is returned from the service manager. However, this may be
overridden with
C<FailureActionExitStatus>/C<SuccessActionExitStatus>, see below.
C<soft-reboot> will trigger a userspace reboot operation.
C<soft-reboot-force> does that too, but does not go through the shutdown transaction
beforehand.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'SuccessAction',
      {
        'choice' => [
          'exit',
          'exit-force',
          'halt',
          'halt-force',
          'halt-immediate',
          'kexec',
          'kexec-force',
          'none',
          'poweroff',
          'poweroff-force',
          'poweroff-immediate',
          'reboot',
          'reboot-force',
          'reboot-immediate',
          'soft-reboot',
          'soft-reboot-force'
        ],
        'description' => 'Configure the action to take when the unit stops and enters a failed state or
inactive state.  Takes one of C<none>, C<reboot>,
C<reboot-force>, C<reboot-immediate>, C<poweroff>,
C<poweroff-force>, C<poweroff-immediate>, C<exit>,
C<exit-force>, C<soft-reboot>, C<soft-reboot-force>,
C<kexec>, C<kexec-force>, C<halt>,
C<halt-force> and C<halt-immediate>. In system mode, all options are
allowed. In user mode, only C<none>, C<exit>, and
C<exit-force> are allowed. Both options default to C<none>.

If C<none> is set, no action will be triggered. C<reboot> causes a
reboot following the normal shutdown procedure (i.e. equivalent to systemctl
reboot).  C<reboot-force> causes a forced reboot which will terminate all
processes forcibly but should cause no dirty file systems on reboot (i.e. equivalent to
systemctl reboot -f) and C<reboot-immediate> causes immediate
execution of the
L<reboot(2)> system
call, which might result in data loss (i.e. equivalent to systemctl reboot -ff).
Similarly, C<poweroff>, C<poweroff-force>,
C<poweroff-immediate>, C<kexec>, C<kexec-force>,
C<halt>, C<halt-force> and C<halt-immediate> have the
effect of powering down the system, executing kexec, and halting the system respectively with similar
semantics. C<exit> causes the manager to exit following the normal shutdown procedure,
and C<exit-force> causes it terminate without shutting down services. When
C<exit> or C<exit-force> is used by default the exit status of the main
process of the unit (if this applies) is returned from the service manager. However, this may be
overridden with
C<FailureActionExitStatus>/C<SuccessActionExitStatus>, see below.
C<soft-reboot> will trigger a userspace reboot operation.
C<soft-reboot-force> does that too, but does not go through the shutdown transaction
beforehand.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'StartLimitBurst',
      {
        'description' => 'Configure unit start rate limiting. Units which are started more than
burst times within an interval time span are
not permitted to start any more. Use C<StartLimitIntervalSec> to configure the
checking interval and C<StartLimitBurst> to configure how many starts per interval
are allowed.

interval is a time span with the default unit of seconds, but other
units may be specified, see
L<systemd.time(7)>.
The special value C<infinity> can be used to limit the total number of start
attempts, even if they happen at large time intervals.
Defaults to C<DefaultStartLimitIntervalSec> in manager configuration file, and may
be set to 0 to disable any kind of rate limiting. burst is a number and
defaults to C<DefaultStartLimitBurst> in manager configuration file.

These configuration options are particularly useful in conjunction with the service setting
C<Restart> (see
L<systemd.service(5)>);
however, they apply to all kinds of starts (including manual), not just those triggered by the
C<Restart> logic.

Note that units which are configured for C<Restart>, and which reach the start
limit are not attempted to be restarted anymore; however, they may still be restarted manually or
from a timer or socket at a later point, after the interval has passed.
From that point on, the restart logic is activated again. systemctl reset-failed
will cause the restart rate counter for a service to be flushed, which is useful if the administrator
wants to manually start a unit and the start limit interferes with that. Rate-limiting is enforced
after any unit condition checks are executed, and hence unit activations with failing conditions do
not count towards the rate limit.

When a unit is unloaded due to the garbage collection logic (see above) its rate limit counters
are flushed out too. This means that configuring start rate limiting for a unit that is not
referenced continuously has no effect.

This setting does not apply to slice, target, device, and scope units, since they are unit
types whose activation may either never fail, or may succeed only a single time.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartLimitIntervalSec',
      {
        'description' => 'Configure unit start rate limiting. Units which are started more than
burst times within an interval time span are
not permitted to start any more. Use C<StartLimitIntervalSec> to configure the
checking interval and C<StartLimitBurst> to configure how many starts per interval
are allowed.

interval is a time span with the default unit of seconds, but other
units may be specified, see
L<systemd.time(7)>.
The special value C<infinity> can be used to limit the total number of start
attempts, even if they happen at large time intervals.
Defaults to C<DefaultStartLimitIntervalSec> in manager configuration file, and may
be set to 0 to disable any kind of rate limiting. burst is a number and
defaults to C<DefaultStartLimitBurst> in manager configuration file.

These configuration options are particularly useful in conjunction with the service setting
C<Restart> (see
L<systemd.service(5)>);
however, they apply to all kinds of starts (including manual), not just those triggered by the
C<Restart> logic.

Note that units which are configured for C<Restart>, and which reach the start
limit are not attempted to be restarted anymore; however, they may still be restarted manually or
from a timer or socket at a later point, after the interval has passed.
From that point on, the restart logic is activated again. systemctl reset-failed
will cause the restart rate counter for a service to be flushed, which is useful if the administrator
wants to manually start a unit and the start limit interferes with that. Rate-limiting is enforced
after any unit condition checks are executed, and hence unit activations with failing conditions do
not count towards the rate limit.

When a unit is unloaded due to the garbage collection logic (see above) its rate limit counters
are flushed out too. This means that configuring start rate limiting for a unit that is not
referenced continuously has no effect.

This setting does not apply to slice, target, device, and scope units, since they are unit
types whose activation may either never fail, or may succeed only a single time.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RebootArgument',
      {
        'description' => 'Configure the optional argument for the
L<reboot(2)> system call if
C<StartLimitAction> or C<FailureAction> is a reboot action. This
works just like the optional argument to systemctl reboot command.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'include' => [
      'Systemd::Section::Unit'
    ],
    'name' => 'Systemd::Section::TimerUnit'
  }
]
;


#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2015-2018 by Dominique Dumont.
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
    'element' => [
      'FailureAction',
      {
        'description' => 'Configure the action to take when the unit stops and enters a failed state or inactive
state. Takes the same values as the setting C<StartLimitAction> setting and executes the same
actions. Both options default to C<none>.',
        'migrate_from' => {
          'formula' => '$service',
          'variables' => {
            'service' => '- - Service FailureAction'
          }
        },
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SuccessAction',
      {
        'description' => 'Configure the action to take when the unit stops and enters a failed state or inactive
state. Takes the same values as the setting C<StartLimitAction> setting and executes the same
actions. Both options default to C<none>.',
        'migrate_from' => {
          'formula' => '$service',
          'variables' => {
            'service' => '- - Service SuccessAction'
          }
        },
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartLimitBurst',
      {
        'description' => 'Configure unit start rate limiting. Units which are started more than
burst times within an interval time interval are not
permitted to start any more. Use C<StartLimitIntervalSec> to configure the checking interval
(defaults to C<DefaultStartLimitIntervalSec> in manager configuration file, set it to 0 to
disable any kind of rate limiting). Use C<StartLimitBurst> to configure how many starts per
interval are allowed (defaults to C<DefaultStartLimitBurst> in manager configuration
file). These configuration options are particularly useful in conjunction with the service setting
C<Restart> (see
L<systemd.service(5)>); however,
they apply to all kinds of starts (including manual), not just those triggered by the
C<Restart> logic. Note that units which are configured for C<Restart> and
which reach the start limit are not attempted to be restarted anymore; however, they may still be restarted
manually at a later point, after the interval has passed.  From this point on, the
restart logic is activated again. Note that systemctl reset-failed will cause the restart
rate counter for a service to be flushed, which is useful if the administrator wants to manually start a unit
and the start limit interferes with that. Note that this rate-limiting is enforced after any unit condition
checks are executed, and hence unit activations with failing conditions do not count towards this rate
limit. This setting does not apply to slice, target, device, and scope units, since they are unit types whose
activation may either never fail, or may succeed only a single time.

When a unit is unloaded due to the garbage collection logic (see above) its rate limit counters are
flushed out too. This means that configuring start rate limiting for a unit that is not referenced continuously
has no effect.',
        'migrate_from' => {
          'formula' => '$service',
          'variables' => {
            'service' => '- - Service StartLimitBurst'
          }
        },
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StartLimitIntervalSec',
      {
        'description' => 'Configure unit start rate limiting. Units which are started more than
burst times within an interval time interval are not
permitted to start any more. Use C<StartLimitIntervalSec> to configure the checking interval
(defaults to C<DefaultStartLimitIntervalSec> in manager configuration file, set it to 0 to
disable any kind of rate limiting). Use C<StartLimitBurst> to configure how many starts per
interval are allowed (defaults to C<DefaultStartLimitBurst> in manager configuration
file). These configuration options are particularly useful in conjunction with the service setting
C<Restart> (see
L<systemd.service(5)>); however,
they apply to all kinds of starts (including manual), not just those triggered by the
C<Restart> logic. Note that units which are configured for C<Restart> and
which reach the start limit are not attempted to be restarted anymore; however, they may still be restarted
manually at a later point, after the interval has passed.  From this point on, the
restart logic is activated again. Note that systemctl reset-failed will cause the restart
rate counter for a service to be flushed, which is useful if the administrator wants to manually start a unit
and the start limit interferes with that. Note that this rate-limiting is enforced after any unit condition
checks are executed, and hence unit activations with failing conditions do not count towards this rate
limit. This setting does not apply to slice, target, device, and scope units, since they are unit types whose
activation may either never fail, or may succeed only a single time.

When a unit is unloaded due to the garbage collection logic (see above) its rate limit counters are
flushed out too. This means that configuring start rate limiting for a unit that is not referenced continuously
has no effect.',
        'migrate_from' => {
          'formula' => '$unit || $service',
          'use_eval' => '1',
          'variables' => {
            'service' => '- - Service StartLimitInterval',
            'unit' => '- StartLimitInterval'
          }
        },
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RebootArgument',
      {
        'description' => 'Configure the optional argument for the
L<reboot(2)> system call if
C<StartLimitAction> or C<FailureAction> is a reboot action. This
works just like the optional argument to systemctl reboot command.',
        'migrate_from' => {
          'formula' => '$service',
          'variables' => {
            'service' => '- - Service RebootArgument'
          }
        },
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'include' => [
      'Systemd::Section::Unit'
    ],
    'name' => 'Systemd::Section::ServiceUnit'
  }
]
;


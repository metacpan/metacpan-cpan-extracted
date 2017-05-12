NAME
    AnsibleModule - Port of AnsibleModule helper from Ansible distribution

SYNOPSIS
    my $pkg_mod=AnsibleModule->new(argument_spec=> { name => { aliases =>
    'pkg' }, state => { default => 'present', choices => [ 'present',
    'absent'], list => {} }, required_one_of => [ qw/ name list / ],
    mutually_exclusive => [ qw/ name list / ], supports_check_mode => 1, );
    ... $pkg_mod->exit_json(changed => 1, foo => 'bar');

DESCRIPTION
    This is a helper class for building ansible modules in Perl. It's a
    straight port of the AnsibleModule class that ships with the ansible
    distribution.

ATTRIBUTES
  argument_spec
    The argument specification for your module.

  bypass_checks
  no_log
  check_invalid_arguments
  mutually_exclusive
  required_together
  required_one_fo
  add_file_common_args
  supports_check_mode
  required_if
METHODS
  exit_json $args
    Exit with a json msg. changed will default to false.

  fail_json $args
    Exit with a failure. msg is required.


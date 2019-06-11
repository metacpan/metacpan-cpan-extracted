#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2019 by Dominique Dumont.
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
        'summary' => 'boilerplate parameter that may hide a typo',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Unknown parameter. Please make sure there\'s no typo and contact the author'
      }
    ],
    'class_description' => 'This configuration class was generated from ssh_system documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-openssh/contrib/parse-man.pl>
',
    'element' => [
      'Host',
      {
        'cargo' => {
          'config_class_name' => 'Ssh::HostElement',
          'type' => 'node'
        },
        'description' => "Restricts the
following declarations (up to the next B<Host> or
B<Match> keyword) to be only for those hosts that match
one of the patterns given after the keyword. If more than
one pattern is provided, they should be separated by
whitespace. A single \x{2019}*\x{2019} as a pattern can be
used to provide global defaults for all hosts. The host is
usually the I<hostname> argument given on the command
line (see the B<CanonicalizeHostname> keyword for
exceptions).See
I<PATTERNS> for more information on patterns.",
        'index_type' => 'string',
        'type' => 'hash'
      },
      'Match',
      {
        'cargo' => {
          'config_class_name' => 'Ssh::HostElement',
          'type' => 'node'
        },
        'description' => "Restricts the
following declarations (up to the next B<Host> or
B<Match> keyword) to be used only when the conditions
following the B<Match> keyword are satisfied. Match
conditions are specified using one or more criteria or the
single token B<all> which always matches. The available
criteria keywords are: B<canonical>, B<exec>,
B<host>, B<originalhost>, B<user>, and
B<localuser>. The B<all> criteria must appear alone
or immediately after B<canonical>. Other criteria may be
combined arbitrarily. All criteria but B<all> and
B<canonical> require an argument. Criteria may be
negated by prepending an exclamation mark
(\x{2019}!\x{2019}).The other
keywords\x{2019} criteria must be single entries or
comma-separated lists and may use the wildcard and negation
operators described in the I<PATTERNS> section. The
criteria for the B<host> keyword are matched against the
target hostname, after any substitution by the
B<Hostname> or B<CanonicalizeHostname> options. The
B<originalhost> keyword matches against the hostname as
it was specified on the command-line. The B<user>
keyword matches against the target username on the remote
host. The B<localuser> keyword matches against the name
of the local user running L<ssh(1)> (this keyword may be useful
in system-wide B<ssh_config> files).",
        'index_type' => 'string',
        'type' => 'hash'
      }
    ],
    'generated_by' => 'parse-man.pl from ssh_system  7.9p1 doc',
    'include' => [
      'Ssh::HostElement'
    ],
    'include_after' => 'Host',
    'license' => 'LGPL2',
    'name' => 'Ssh',
    'rw_config' => {
      'auto_create' => '1',
      'backend' => 'OpenSsh::Ssh',
      'config_dir' => '~/.ssh',
      'default_layer' => {
        'config_dir' => '/etc/ssh',
        'file' => 'ssh_config',
        'os_config_dir' => {
          'darwin' => '/etc'
        }
      },
      'file' => 'config'
    }
  }
]
;


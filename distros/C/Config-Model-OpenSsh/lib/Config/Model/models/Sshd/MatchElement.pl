#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'Configuration class that represents all parameters available 
inside a Match block of a sshd configuration.',
    'copyright' => [
      '2009-2011 Dominique Dumont'
    ],
    'element' => [
      'AcceptEnv',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies what environment variables sent by the client will be copied into the session\'s environ(7).',
        'type' => 'list'
      },
      'AllowAgentForwarding',
      {
        'description' => 'Specifies whether L<ssh-agent(1)> forwarding is permitted.  Note that disabling agent forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'AllowGroups',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Login is allowed only for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.',
        'type' => 'list'
      },
      'AllowUsers',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'List of user name patterns, separated by spaces. If specified, login is allowed only for user names that match one of the patterns. Only user names are valid; a numerical user ID is not recognized. By default, login is allowed for all users. If the pattern takes the form USER@HOST then USER and HOST are separately checked, restricting logins to particular users from particular hosts. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.',
        'level' => 'important',
        'type' => 'list'
      },
      'AuthenticationMethods',
      {
        'description' => 'Specifies the authentication methods that must be successfully
completed for a user to be granted access. This option must be
followed by one or more comma-separated lists of authentication method
names. Successful authentication requires completion of every method
in at least one of these lists.

For example, an argument of "publickey,password
publickey,keyboard-interactive" would require the user to complete
public key authentication, followed by either password or keyboard
interactive authentication. Only methods that are next in one or more
lists are offered at each stage, so for this example, it would not be
possible to attempt password or keyboard-interactive authentication
before public key.

For keyboard interactive authentication it is also possible to
restrict authentication to a specific device by appending a colon
followed by the device identifier "bsdauth", "pam", or "skey",
depending on the server configuration. For example,
"keyboard-interactive:bsdauth" would restrict keyboard interactive
authentication to the "bsdauth" device.

This option is only available for SSH protocol 2 and will yield a
fatal error if enabled if protocol 1 is also enabled. Note that each
authentication method listed should also be explicitly enabled in the
configuration. The default is not to require multiple authentication;
successful completion of a single authentication method is sufficient.',
        'summary' => 'authentication methods that must be successfully completed for a user to be granted access',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AuthorizedKeysCommand',
      {
        'description' => 'Specifies a program to be used to look up the user\'s public keys. The program must be owned by root and not writable by group or others. It will be invoked with a single argument of the username being authenticated, and should produce on standard output zero or more lines of authorized_keys output (see AUTHORIZED_KEYS in L<sshd(8)>). If a key supplied by AuthorizedKeysCommand does not successfully authenticate and authorize the user then public key authentication continues using the usual AuthorizedKeysFile files. By default, no AuthorizedKeysCommand is run.',
        'summary' => 'program to be used to look up the user\'s public keys',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AuthorizedKeysCommandUser',
      {
        'description' => 'Specifies the user under whose account the AuthorizedKeysCommand is run. It is recommended to use a dedicated user that has no other role on the host than running authorized keys commands.',
        'summary' => ' user under whose account the AuthorizedKeysCommand is run',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AllowTcpForwarding',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether TCP forwarding is permitted. The default is "yes".Note that disabling TCP forwarding does not improve security unless users are also denied shell access, as they can always install their own forwarders.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'AuthorizedKeysFile2',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies the file that contains the public keys that can be used for user authentication. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup.',
        'status' => 'deprecated',
        'type' => 'list'
      },
      'AuthorizedKeysFile',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies the file that contains the public keys that can be used for user authentication. The format is described in the AUTHORIZED_KEYS FILE FORMAT section of L<sshd(8)>. AuthorizedKeysFile may contain tokens of the form %T which are substituted during connection setup. The following tokens are defined: %% is replaced by a literal \'%\', %h is replaced by the home directory of the user being authenticated, and %u is replaced by the username of that user. After expansion, AuthorizedKeysFile is taken to be an absolute path or one relative to the user\'s home directory. Multiple files may be listed, separated by whitespace. The default is ".ssh/authorized_keys .ssh/authorized_keys2".',
        'migrate_values_from' => '- AuthorizedKeysFile2',
        'type' => 'list'
      },
      'AuthorizedPrincipalsFile',
      {
        'description' => 'Specifies a file that lists principal names that are accepted for
certificate authentication.  When using certificates signed by a key
listed in TrustedUserCAKeys, this file lists names, one of which must
appear in the certificate for it to be accepted for authentication.
Names are listed one per line preceded by key options (as described in
AUTHORIZED_KEYS FILE FORMAT in L<sshd(8)>).  Empty lines and comments
starting with \'#\' are ignored.

AuthorizedPrincipalsFile may contain tokens of the form %T which are
substituted during connection setup. The following tokens are
defined: %% is replaced by a literal \'%\', %h is replaced by the home
directory of the user being authenticated, and %u is replaced by the
username of that user.  After expansion, AuthorizedPrincipalsFile is
taken to be an absolute path or one relative to the user\'s home
directory.

The default is "none", i.e. not to use a principals file - in this
case, the username of the user must appear in a certificate\'s
principals list for it to be accepted.  Note that
AuthorizedPrincipalsFile is only used when authentication proceeds
using a CA listed in TrustedUserCAKeys and is not consulted for
certification authorities trusted via ~/.ssh/authorized_keys, though
the principals= key option offers a similar facility (see L<sshd(8)>
for details).',
        'summary' => 'file that lists principal names that are accepted for certificate authentication',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Banner',
      {
        'description' => 'In some jurisdictions, sending a warning message before authentication may be relevant for getting legal protection. The contents of the specified file are sent to the remote user before authentication is allowed. This option is only available for protocol version 2. By default, no banner is displayed.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ChrootDirectory',
      {
        'description' => 'Specifies the pathname of a directory to L<chroot(2)> to after
authentication.  All components of the pathname must be root owned
directories that are not writable by any other user or group.  After
the chroot, L<sshd(8)> changes the working directory to the user\'s home
directory.

The pathname may contain the following tokens that are expanded at
runtime once the connecting user has been authenticated: %% is
replaced by a literal \'%\', %h is replaced by the home directory of the
user being authenticated, and %u is replaced by the username of that
user.

The ChrootDirectory must contain the necessary files and directories
to support the user\'s session.  For an interactive session this
requires at least a shell, typically L<sh(1)>, and basic /dev nodes
such as L<null(4)>, L<zero(4)>, L<stdin(4)>, L<stdout(4)>,
L<stderr(4)>, L<arandom(4)> and L<tty(4)> devices.  For file transfer
sessions using "sftp", no additional configuration of the environment
is necessary if the in-process sftp server is used, though sessions
which use logging do require /dev/log inside the chroot directory (see
L<sftp-server(8)> for details).

The default is not to chroot(2).',
        'summary' => 'pathname of a directory to chroot to after authentication',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DenyGroups',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This keyword can be followed by a list of group name patterns, separated by spaces.  Login is disallowed for users whose primary group or supplementary group list matches one of the patterns. Only group names are valid; a numerical group ID is not recognized. By default, login is allowed for all groups.  The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.',
        'type' => 'list'
      },
      'DenyUSers',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This keyword can be followed by a list of user name patterns, separated by spaces.  Login is disallowed for user names that match one of the patterns. Only user names are valid; a numerical user ID is not recognized. By default, login is allowed for all users. If the pattern takes the form USER@HOST then USER and HOST are separately checked, restricting logins to particular users from particular hosts. The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.',
        'type' => 'list'
      },
      'ForceCommand',
      {
        'description' => 'Forces the execution of the command specified by ForceCommand, ignoring any command supplied by the client. The command is invoked by using the user\'s login shell with the -c option. This applies to shell, command, or subsystem execution. It is most useful inside a Match block. The command originally supplied by the client is available in the SSH_ORIGINAL_COMMAND environment variable.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'GatewayPorts',
      {
        'choice' => [
          'yes',
          'clientspecified',
          'no'
        ],
        'description' => 'Specifies whether remote hosts are allowed to connect to ports forwarded for the client. By default, sshd(8) binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.',
        'help' => {
          'clientspecified' => 'allow the client to select the address to which the forwarding is bound',
          'no' => 'No port forwarding
',
          'yes' => 'force remote port forwardings to bind to the wildcard address'
        },
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'GSSAPIAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether user authentication based on GSSAPI is allowed. Note that this option applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'HostbasedAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether rhosts or /etc/hosts.equiv authentication together with successful public key client host authentication is allowed (host-based authentication). This option is similar to RhostsRSAAuthentication and applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'HostbasedUsesNameFromPacketOnly',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether or not the server will attempt to perform a reverse name lookup when matching the name in the ~/.shosts, ~/.rhosts, and /etc/hosts.equiv files during HostbasedAuthentication.',
        'help' => {
          'no' => 'sshd(8) attempts to resolve the name from the TCP connection itself.',
          'yes' => 'sshd(8) uses the name supplied by the client'
        },
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'KbdInteractiveAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'No doc found in sshd documentation',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'KerberosAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether the password provided by the user for PasswordAuthentication will be validated through the Kerberos KDC. To use this option, the server needs a Kerberos servtab which allows the verification of the KDC\'s identity. The default is "no".',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'MaxAuthTries',
      {
        'description' => 'Specifies the maximum number of authentication attempts permitted per connection. Once the number of failures reaches half this value, additional failures are logged.',
        'type' => 'leaf',
        'upstream_default' => '6',
        'value_type' => 'integer'
      },
      'MaxSessions',
      {
        'summary' => 'Specifies the maximum number of open sessions permitted per network connection',
        'type' => 'leaf',
        'upstream_default' => '10',
        'value_type' => 'integer'
      },
      'PasswordAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether password authentication is allowed.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'PermitEmptyPasswords',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'When password authentication is allowed, it specifies whether the server allows login to accounts with empty password strings.  The default is "no".',
        'help' => {
          'yes' => 'So, you want your machine to be part of a botnet ? ;-)'
        },
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'PermitOpen',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies the destinations to which TCP port forwarding is permitted. The forwarding specification must be one of the following forms: "host:port" or "IPv4_addr:port" or "[IPv6_addr]:port". An argument of "any" can be used to remove all restrictions and permit any forwarding requests. By default all port forwarding requests are permitted.',
        'type' => 'list'
      },
      'PermitRootLogin',
      {
        'choice' => [
          'yes',
          'without-password',
          'forced-commands-only',
          'no'
        ],
        'description' => 'Specifies whether root can log in using ssh(1).',
        'help' => {
          'forced-commands-only' => 'root login with public key authentication will be allowed, but only if the command option has been specified (which may be useful for taking remote backups even if root login is normally not allowed).  All other authentication methods are disabled for root.',
          'no' => 'root is not allowed to log in
',
          'without-password' => 'password authentication is disabled for root'
        },
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'PermitTunnel',
      {
        'choice' => [
          'yes',
          'point-to-point',
          'ethernet',
          'no'
        ],
        'description' => 'Specifies whether tun(4) device forwarding is allowed. The argument must be "yes", "point-to-point" (layer 3), "ethernet" (layer 2), or "no".  Specifying "yes" permits both "point-to-point" and "ethernet".',
        'help' => {
          'yes' => 'permits both "point-to-point" and "ethernet"'
        },
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'PubkeyAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether public key authentication is allowed.  The default is "yes". Note that this option applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'RekeyLimit',
      {
        'description' => 'Specifies the maximum amount of data that may be transmitted before
the session key is renegotiated, optionally followed a maximum amount
of time that may pass before the session key is renegotiated.  The
first argument is specified in bytes and may have a suffix of \'K\',
\'M\', or \'G\' to indicate Kilobytes, Megabytes, or Gigabytes,
respectively.  The default is between \'1G\' and \'4G\', depending on the
cipher.  The optional second value is specified in seconds and may use
any of the units documented in the TIME FORMATS section.  The default
value for RekeyLimit is "default none", which means that rekeying is
performed after the cipher\'s default amount of data has been sent or
received and no time based rekeying is done.  This option applies to
protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => 'default none',
        'value_type' => 'uniline'
      },
      'RhostsRSAAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether rhosts or /etc/hosts.equiv authentication together with successful RSA host authentication is allowed.  The default is "no". This option applies to protocol version 1 only.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'RSAAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether pure RSA authentication is allowed. This option applies to protocol version 1 only.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'X11DisplayOffset',
      {
        'description' => 'Specifies the first display number available for sshd(8)\'s X11 forwarding. This prevents sshd from interfering with real X11 servers.',
        'type' => 'leaf',
        'upstream_default' => '10',
        'value_type' => 'integer'
      },
      'X11Forwarding',
      {
        'choice' => [
          'yes',
          'no'
        ],
        'description' => 'Specifies whether X11 forwarding is permitted. Note that disabling X11 forwarding does not prevent users from forwarding X11 traffic, as users can always install their own forwarders. X11 forwarding is automatically disabled if UseLogin is enabled.',
        'level' => 'important',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'X11UseLocalhost',
      {
        'choice' => [
          'yes',
          'no'
        ],
        'description' => 'Specifies whether sshd(8) should bind the X11 forwarding server to the loopback address or to the wildcard address. By default, sshd binds the forwarding server to the loopback address and sets the hostname part of the DISPLAY environment variable to "localhost". This prevents remote hosts from connecting to the proxy display. However, some older X11 clients may not function with this configuration. X11UseLocalhost may be set to "no" to specify that the forwarding server should be bound to the wildcard address.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Sshd::MatchElement'
  }
]
;


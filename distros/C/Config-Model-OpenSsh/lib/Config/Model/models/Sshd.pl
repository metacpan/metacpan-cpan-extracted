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
    'accept' => [
      '.*',
      {
        'summary' => 'boilerplate parameter that may hide a typo',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warn' => 'Unknow parameter please make sure there\'s no typo and contact the author'
      }
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'Configuration class used by L<Config::Model> to edit or 
validate /etc/ssh/sshd_config
',
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
      'AddressFamily',
      {
        'choice' => [
          'any',
          'inet',
          'inet6'
        ],
        'description' => 'Specifies which address family should be used by sshd(8).',
        'type' => 'leaf',
        'upstream_default' => 'any',
        'value_type' => 'enum'
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
      'ChallengeResponseAuthentication',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether challenge-response authentication is allowed. All authentication styles from login.conf(5) are supported.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
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
      'Ciphers',
      {
        'choice' => [
          '3des-cbc',
          'aes128-cbc',
          'aes192-cbc',
          'aes256-cbc',
          'aes128-ctr',
          'aes192-ctr',
          'aes256-ctr',
          'arcfour128',
          'arcfour256',
          'arcfour',
          'blowfish-cbc',
          'cast128-cbc'
        ],
        'description' => 'Specifies the ciphers allowed for protocol version 2. By default, all ciphers are allowed.',
        'type' => 'check_list',
        'upstream_default_list' => [
          '3des-cbc',
          'aes128-cbc',
          'aes128-ctr',
          'aes192-cbc',
          'aes192-ctr',
          'aes256-cbc',
          'aes256-ctr',
          'arcfour',
          'arcfour128',
          'arcfour256',
          'blowfish-cbc',
          'cast128-cbc'
        ]
      },
      'ClientAliveCountMax',
      {
        'description' => 'Sets the number of client alive messages which may be sent without sshd(8) receiving any messages back from the client. If this threshold is reached while client alive messages are being sent, sshd will disconnect the client, terminating the session.  It is important to note that the use of client alive messages is very different from TCPKeepAlive. The client alive messages are sent through the encrypted channel and therefore will not be spoofable. The TCP keepalive option enabled by TCPKeepAlive is spoofable. The client alive mechanism is valuable when the client or server depend on knowing when a connection has become inactive.

The default value is 3. If ClientAliveInterval is set to 15, and ClientAliveCountMax is left at the default, unresponsive SSH clients will be disconnected after approximately 45 seconds. This option applies to protocol version 2 only.',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '3',
        'value_type' => 'integer'
      },
      'ClientAliveInterval',
      {
        'min' => '1',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'Compression',
      {
        'choice' => [
          'yes',
          'delayed',
          'no'
        ],
        'description' => 'Specifies whether compression is allowed, or delayed until the user has authenticated successfully.',
        'type' => 'leaf',
        'upstream_default' => 'delayed',
        'value_type' => 'enum'
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
      'GSSAPIKeyExchange',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether key exchange based on GSSAPI is allowed. GSSAPI key exchange doesn\'t rely on ssh keys to verify host identity. Note that this option applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'GSSAPICleanupCredentials',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether to automatically destroy the user\'s credentials cache on logout. Note that this option applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'GSSAPIStrictAcceptorCheck',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Determines whether to be strict about the identity of the GSSAPI acceptor a client authenticates against.This facility is provided to assist with operation on multi homed machines. Note that this option applies only to protocol version 2 GSSAPI connections, and setting it to "no" may only work with recent Kerberos GSSAPI libraries.',
        'help' => {
          'no' => 'the client may authenticate against any service key stored in the machine\'s default store',
          'yes' => 'the client must authenticate against the host service on the current hostname.'
        },
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'GSSAPIStoreCredentialsOnRekey',
      {
        'description' => 'Controls whether the user\'s GSSAPI credentials should be updated following a successful connection rekeying. This option can be used to accepted renewed or updated credentials from a compatible client.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
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
      'HostCertificate',
      {
        'description' => 'Specifies a file containing a public host certificate. The certificate\'s public key must match a private host key already specified by HostKey. The default behaviour of sshd(8) is not to load any certificates.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'HostKey',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies a file containing a private host key used by SSH. The default is /etc/ssh/ssh_host_key for protocol version 1, and /etc/ssh/ssh_host_rsa_key and /etc/ssh/ssh_host_dsa_key for protocol version 2. Note that sshd(8) will refuse to use a file if it is group/world-accessible.  It is possible to have multiple host key files. "rsa1" keys are used for version 1 and "dsa" or "rsa" are used for version 2 of the SSH protocol.',
        'type' => 'list'
      },
      'HostKeyAgent',
      {
        'description' => 'Identifies the UNIX-domain socket used to communicate with an agent that has access to the private host keys. If "SSH_AUTH_SOCK" is specified, the location of the socket will be read from the SSH_AUTH_SOCK environment variable.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IgnoreRhosts',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies that .rhosts and .shosts files will not be used in RhostsRSAAuthentication or HostbasedAuthentication. /etc/hosts.equiv and /etc/ssh/shosts.equiv are still used. ',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'IgnoreUserKnownHosts',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether sshd(8) should ignore the user\'s ~/.ssh/known_hosts during RhostsRSAAuthentication or HostbasedAuthentication.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'IPQoS',
      {
        'assert' => {
          '1_or_2' => {
            'code' => 'return 1 unless defined $_;
my @v = (/(\\w+)/g);
return  (@v < 3) ? 1 : 0;
',
            'msg' => 'value must not have more than 2 fields.'
          },
          'accepted_values' => {
            'code' => 'return 1 unless defined $_;
my @v = (/(\\S+)/g);
my @good = grep {/^(af[1-4][1-3]|cs[0-7]|ef|lowdelay|throughput|reliability|\\d+)/} @v ;
return @good == @v ? 1 : 0;
',
            'msg' => 'value must be 1 or 2 occurences of: "af11", "af12", "af13", "af21", "af22",
"af23", "af31", "af32", "af33", "af41", "af42", "af43", "cs0", "cs1",
"cs2", "cs3", "cs4", "cs5", "cs6", "cs7", "ef", "lowdelay",
"throughput", "reliability", or a numeric value.'
          }
        },
        'description' => 'Specifies the IPv4 type-of-service or DSCP class for the connection. Accepted values are "af11", "af12", "af13", "af21", "af22", "af23", "af31", "af32", "af33", "af41", "af42", "af43", "cs0", "cs1", "cs2", "cs3", "cs4", "cs5", "cs6", "cs7", "ef", "lowdelay", "throughput", "reliability", or a numeric value. This option may take one or two arguments, separated by whitespace. If one argument is specified, it is used as the packet class unconditionally. If two values are specified, the first is automatically selected for interactive sessions and the second for non-interactive sessions. The default is "lowdelay" for interactive sessions and "throughput" for non-interactive sessions.',
        'summary' => 'IPv4 type-of-service or DSCP class for the connection.',
        'type' => 'leaf',
        'upstream_default' => 'lowdelay throughput',
        'value_type' => 'uniline'
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
      'KerberosGetAFSToken',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'If AFS is active and the user has a Kerberos 5 TGT, attempt to acquire an AFS token before accessing the user\'s home directory.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'KerberosOrLocalPasswd',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'If password authentication through Kerberos fails then the password will be validated via any additional local mechanism such as /etc/passwd.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'KerberosTicketCleanup',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether to automatically destroy the user\'s ticket cache file on logout.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'KexAlgorithms',
      {
        'choice' => [
          'ecdh-sha2-nistp256',
          'ecdh-sha2-nistp384',
          'ecdh-sha2-nistp521',
          'diffie-hellman-group-exchange-sha256',
          'diffie-hellman-group-exchange-sha1',
          'diffie-hellman-group14-sha1',
          'diffie-hellman-group1-sha1'
        ],
        'description' => 'Specifies the available KEX (Key Exchange) algorithms.',
        'type' => 'check_list',
        'upstream_default_list' => [
          'diffie-hellman-group-exchange-sha1',
          'diffie-hellman-group-exchange-sha256',
          'diffie-hellman-group1-sha1',
          'diffie-hellman-group14-sha1',
          'ecdh-sha2-nistp256',
          'ecdh-sha2-nistp384',
          'ecdh-sha2-nistp521'
        ]
      },
      'KeyRegenerationInterval',
      {
        'description' => 'In protocol version 1, the ephemeral server key is automatically regenerated after this many seconds (if it has been used). The purpose of regeneration is to prevent decrypting captured sessions by later breaking into the machine and stealing the keys. The key is never stored anywhere. If the value is 0, the key is never regenerated. The default is 3600 (seconds).',
        'type' => 'leaf',
        'upstream_default' => '3600',
        'value_type' => 'integer'
      },
      'Port',
      {
        'description' => 'Specifies the port number that sshd(8) listens on. The default is 22. Multiple options of this type are permitted. See also ListenAddress.',
        'type' => 'leaf',
        'upstream_default' => '22',
        'value_type' => 'integer'
      },
      'ListenAddress',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies the local addresses sshd(8) should listen on. The following forms may be used:

  host|IPv4_addr|IPv6_addr
  host|IPv4_addr:port
  [host|IPv6_addr]:port

If port is not specified, sshd will listen on the address and all prior Port options specified. The default is to listen on all local addresses.  Multiple ListenAddress options are permitted. Additionally, any Port options must precede this option for non-port qualified addresses.',
        'type' => 'list'
      },
      'LoginGraceTime',
      {
        'description' => 'The server disconnects after this time if the user has not successfully logged in. If the value is 0, there is no time limit. The default is 120 seconds.',
        'type' => 'leaf',
        'upstream_default' => '120',
        'value_type' => 'integer'
      },
      'LogLevel',
      {
        'choice' => [
          'SILENT',
          'QUIET',
          'FATAL',
          'ERROR',
          'INFO',
          'VERBOSE',
          'DEBUG',
          'DEBUG1',
          'DEBUG2',
          'DEBUG3'
        ],
        'help' => {
          'DEBUG' => 'Logging with this level violates the privacy of users and is not recommended',
          'DEBUG1' => 'Logging with this level violates the privacy of users and is not recommended',
          'DEBUG2' => 'Logging with this level violates the privacy of users and is not recommended',
          'DEBUG3' => 'Logging with this level violates the privacy of users and is not recommended'
        },
        'type' => 'leaf',
        'upstream_default' => 'INFO',
        'value_type' => 'enum'
      },
      'MACs',
      {
        'choice' => [
          'hmac-md5',
          'hmac-md5-96',
          'hmac-ripemd160',
          'hmac-sha1',
          'hmac-sha1-96',
          'umac-64@openssh.com'
        ],
        'description' => 'Specifies the available MAC (message authentication code) algorithms. The MAC algorithm is used in protocol version 2 for data integrity protection.',
        'type' => 'check_list'
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
      'MaxStartups',
      {
        'description' => 'Specifies the maximum number of concurrent unauthenticated connections to the SSH daemon. Additional connections will be dropped until authentication succeeds or the LoginGraceTime expires for a connection. The default is 10.

Alternatively, random early drop can be enabled by specifying the three colon separated values "start:rate:full" (e.g. "10:30:60"). sshd(8) will refuse connection attempts with a probability of "rate/100" (30%) if there are currently "start" (10) unauthenticated connections. The probability increases linearly and all connection attempts are refused if the number of unauthenticated connections reaches "full" (60).',
        'type' => 'leaf',
        'upstream_default' => '10',
        'value_type' => 'uniline'
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
      'PermitBlacklistedKeys',
      {
        'description' => 'Specifies whether sshd(8) should allow keys recorded in its blacklist of known-compromised keys (see L<ssh-vulnkey(1)>). If "yes", then attempts to authenticate with compromised keys will be logged but accepted. If "no", then attempts to authenticate with compromised keys will be rejected.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
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
      'PermitUserEnvironment',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether ~/.ssh/environment and environment= options in ~/.ssh/authorized_keys are processed by sshd(8). The default is "no". Enabling environment processing may enable users to bypass access restrictions in some configurations using mechanisms such as LD_PRELOAD.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'PidFile',
      {
        'description' => 'Specifies the file that contains the process ID of the SSH daemon.',
        'type' => 'leaf',
        'upstream_default' => '/var/run/sshd.pid',
        'value_type' => 'uniline'
      },
      'PrintLastLog',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether sshd(8) should print the date and time of the last user login when a user logs in interactively.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'PrintMotd',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether sshd(8) should print /etc/motd when a user logs in interactively. (On some systems it is also printed by the shell, /etc/profile, or equivalent.)',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'Protocol',
      {
        'choice' => [
          '1',
          '2'
        ],
        'description' => 'Specifies the protocol versions sshd(8) supports.  Note that the order of the protocol list does not indicate preference, because the client selects among multiple protocol versions offered by the server.',
        'type' => 'check_list',
        'upstream_default_list' => [
          '1',
          '2'
        ]
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
      'RevokedKeys',
      {
        'description' => 'Specifies revoked public keys.  Keys listed in this file will be
refused for public key authentication.  Note that if this file is not
readable, then public key authentication will be refused for all
users.  Keys may be specified as a text file, listing one public key
per line, or as an OpenSSH Key Revocation List (KRL) as generated by
L<ssh-keygen(1)>.  For more information on KRLs, see the KEY REVOCATION
LISTS section in ssh-keygen(1).',
        'summary' => 'Revoked keys file',
        'type' => 'leaf',
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
      'ServerKeyBits',
      {
        'description' => 'Defines the number of bits in the ephemeral protocol version 1 server key. The minimum value is 512, and the default is 768.',
        'min' => '512',
        'type' => 'leaf',
        'upstream_default' => '768',
        'value_type' => 'integer'
      },
      'StrictModes',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether sshd(8) should check file modes and ownership of the user\'s files and home directory before accepting login.  This is normally desirable because novices sometimes accidentally leave their directory or files world-writable.  The default is "yes".
',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'Subsystem',
      {
        'cargo' => {
          'mandatory' => 1,
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Configures an external subsystem (e.g. file transfer daemon). Keys of the hash should be a subsystem name and hash value a command (with optional arguments) to execute upon subsystem request. The command sftp-server(8) implements the "sftp" file transfer subsystem.  By default no subsystems are defined. Note that this option applies to protocol version 2 only.',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'SyslogFacility',
      {
        'choice' => [
          'DAEMON',
          'USER',
          'AUTH',
          'LOCAL0',
          'LOCAL1',
          'LOCAL2',
          'LOCAL3',
          'LOCAL4',
          'LOCAL5',
          'LOCAL6',
          'LOCAL7'
        ],
        'description' => 'Gives the facility code that is used when logging messages from sshd(8). The default is AUTH.',
        'type' => 'leaf',
        'upstream_default' => 'AUTH',
        'value_type' => 'enum'
      },
      'KeepAlive',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'TCPKeepAlive',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether the system should send TCP keepalive messages to the other side. If they are sent, death of the connection or crash of one of the machines will be properly noticed. However, this means that connections will die if the route is down temporarily, and some people find it annoying.  On the other hand, if TCP keepalives are not sent, sessions may hang indefinitely on the server, leaving "ghost" users and consuming server resources. This option was formerly called KeepAlive.',
        'help' => {
          'no' => 'disable TCP keepalive messages',
          'yes' => 'Send TCP keepalive messages. The server will notice if the network goes down or the client host crashes. This avoids infinitely hanging sessions.'
        },
        'migrate_from' => {
          'formula' => '$keep_alive',
          'variables' => {
            'keep_alive' => '- KeepAlive'
          }
        },
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'TrustedUserCAKeys',
      {
        'description' => 'Specifies a file containing public keys of certificate authorities
that are trusted to sign user certificates for authentication.  Keys
are listed one per line; empty lines and comments starting with \'#\'
are allowed.  If a certificate is presented for authentication and has
its signing CA key listed in this file, then it may be used for
authentication for any user listed in the certificate\'s principals
list.  Note that certificates that lack a list of principals will not
be permitted for authentication using TrustedUserCAKeys.  For more
details on certificates, see the CERTIFICATES section in
ssh-keygen(1).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UseDNS',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether sshd(8) should look up the remote host name and check that the resolved host name for the remote IP address maps back to the very same IP address. The default is "yes"',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'UseLogin',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether login(1) is used for interactive login sessions.  The default is "no". Note that login(1) is never used for remote command execution.  Note also, that if this is enabled, X11Forwarding will be disabled because login(1) does not know how to handle xauth(1) cookies. If UsePrivilegeSeparation is specified, it will be disabled after authentication',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'UsePAM',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Enables the Pluggable Authentication Module interface. If set to "yes" this will enable PAM authentication using ChallengeResponseAuthentication and PasswordAuthentication in addition to PAM account and session module processing for all authentication types.

Because PAM challenge-response authentication usually serves an equivalent role to password authentication, you should disable either PasswordAuthentication or ChallengeResponseAuthentication.

If UsePAM is enabled, you will not be able to run sshd(8) as a non-root user.  The default is "no".',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'UsePrivilegeSeparation',
      {
        'choice' => [
          'no',
          'yes'
        ],
        'description' => 'Specifies whether sshd(8) separates privileges by creating an unprivileged child process to deal with incoming network traffic.  After successful authentication, another process will be created that has the privilege of the authenticated user. The goal of privilege separation is to prevent privilege escalation by containing any corruption within the unprivileged processes. The default is "yes".',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'VersionAddendum',
      {
        'description' => 'Optionally specifies additional text to append to the SSH protocol banner sent by the server upon connection',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'XAuthLocation',
      {
        'description' => 'Specifies the full pathname of the xauth(1) program.',
        'type' => 'leaf',
        'upstream_default' => '/usr/bin/X11/xauth',
        'value_type' => 'uniline'
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
      },
      'Match',
      {
        'cargo' => {
          'config_class_name' => 'Sshd::MatchBlock',
          'type' => 'node'
        },
        'description' => 'Specifies a match block. The criteria User, Group Host and Address can contain patterns. When all these criteria are satisfied (i.e. all patterns match the incoming connection), the parameters set in the block element will override the general settings.',
        'type' => 'list'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Sshd',
    'read_config' => [
      {
        'backend' => 'OpenSsh::Sshd',
        'config_dir' => '/etc/ssh',
        'file' => 'sshd_config',
        'os_config_dir' => {
          'darwin' => '/etc'
        }
      }
    ]
  }
]
;


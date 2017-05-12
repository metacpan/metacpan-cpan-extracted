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
inside a Host directive of a ssh configuration.',
    'copyright' => [
      '2009-2011 Dominique Dumont'
    ],
    'element' => [
      'AddressFamily',
      {
        'choice' => [
          'any',
          'inet',
          'inet6'
        ],
        'description' => 'Specifies which address family to use when connecting.',
        'type' => 'leaf',
        'upstream_default' => 'any',
        'value_type' => 'enum'
      },
      'BatchMode',
      {
        'description' => 'If set to \'yes\', passphrase/password querying will be disabled. In addition, the ServerAliveInterval option will be set to 300 seconds by default. This option is useful in scripts and other batch jobs where no user is present to supply the password, and where it is desirable to detect a broken network swiftly. ',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'BindAddress',
      {
        'description' => 'Use the specified address on the local machine as the source address of the connection. Only useful on systems with more than one address. Note that this option does not work if UsePrivilegedPort is set to \'yes\'.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ChallengeResponseAuthentication',
      {
        'description' => 'Specifies whether to use challenge-response authentication.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'CheckHostIP',
      {
        'description' => 'If enabled, ssh(1) will additionally check the host IP address in the known_hosts file. This allows ssh to detect if a host key changed due to DNS spoofing. If disbled, the check will not be executed.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'Cipher',
      {
        'choice' => [
          'blowfish',
          '3des',
          'des'
        ],
        'description' => 'Specifies the cipher to use for encrypting the session in protocol version 1. "des" is only supported in the ssh(1) client for interoperability with legacy protocol 1 implementations that do not support the 3des cipher. Its use is strongly discouraged due to cryptographic weaknesses.',
        'type' => 'leaf',
        'upstream_default' => '3des',
        'value_type' => 'enum'
      },
      'Ciphers',
      {
        'choice' => [
          'aes128-cbc',
          '3des-cbc',
          'blowfish-cbc',
          'cast128-cbc',
          'arcfour128',
          'arcfour256',
          'arcfour',
          'aes192-cbc',
          'aes256-cbc',
          'aes128-ctr',
          'aes192-ctr',
          'aes256-ctr'
        ],
        'description' => 'Specifies the ciphers allowed for protocol version 2 in order of preference. By default, all ciphers are allowed. User cipher list will override system list',
        'ordered' => '1',
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
      'ClearAllForwardings',
      {
        'description' => 'Specifies that all local, remote, and dynamic port forwardings specified in the configuration files or on the command line be cleared. This option is primarily useful when used from the ssh(1) command line to clear port forwardings set in configuration files, and is automatically set by scp(1) and sftp(1).',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'Compression',
      {
        'description' => 'Specifies whether to use compression.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'CompressionLevel',
      {
        'level' => 'hidden',
        'max' => '9',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '6',
        'value_type' => 'integer',
        'warp' => {
          'follow' => {
            'compression' => '- Compression'
          },
          'rules' => [
            '$compression == 1',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'ConnectionAttempts',
      {
        'description' => 'Specifies the number of tries (one per second) to make before exiting. The argument must be an integer. This may be useful in scripts if the connection sometimes fails.',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'integer'
      },
      'ConnectTimeout',
      {
        'description' => 'Specifies the timeout (in seconds) used when connecting to the SSH server, instead of using the default system TCP timeout. This value is used only when the target is down or really unreachable, not when it refuses the connection.
',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'ControlMaster',
      {
        'choice' => [
          'no',
          'yes',
          'ask',
          'auto',
          'autoask'
        ],
        'description' => 'Enables the sharing of multiple sessions over a single network connection. When set to \'yes\', ssh(1) will listen for connections on a control socket specified using the ControlPath argument. Additional sessions can connect to this socket using the same ControlPath with ControlMaster set to \'no\' (the default). These sessions will try to reuse the master instance\'s network connection rather than initiating new ones, but will fall back to connecting normally if the control socket does not exist, or is not listening.

Setting this to \'ask\' will cause ssh to listen for control connections, but require confirmation using the SSH_ASKPASS program before they are accepted (see ssh-add(1) for details). If the ControlPath cannot be opened, ssh will continue without connecting to a master instance.

X11 and ssh-agent(1) forwarding is supported over these multiplexed connections, however the display and agent forwarded will be the one belonging to the master connection i.e. it is not pos sible to forward multiple displays or agents.

Two additional options allow for opportunistic multiplexing: try to use a master connection but fall back to creating a new one if
 one does not already exist. These options are: \'auto\' and \'autoask\'. The latter requires confirmation like the \'ask\' option.
',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'ControlPath',
      {
        'description' => 'Specify the path to the control socket used for connection sharing as described in the ControlMaster section above or the string \'none\' to disable connection sharing.  In the path, \'%l\' will be substituted by the local host name, \'%h\' will be substituted by the target host name, \'%p\' the port, and \'%r\' by the remotelogin username. It is recommended that any ControlPath used for opportunistic connection sharing include at least %h, %p, and %r. This ensures that shared connections are uniquely identified.
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ControlPersist',
      {
        'description' => 'When used in conjunction with ControlMaster, specifies that the master connection should remain open in the background (waiting for future client connections) after the initial client connection has been closed. If set to ``no\'\', then the master connection will not be placed into the background, and will close as soon as the initial client connection is closed. If set to ``yes\'\', then the master connection will remain in the background indef- initely (until killed or closed via a mechanism such as the ssh(1) ``-O exit\'\' option). If set to a time in seconds, or a time in any of the formats documented in sshd_config(5), then the backgrounded master connection will automatically terminate after it has remained idle (with no client connections) for the specified time.',
        'match' => '^(?i)yes|no|\\d+$',
        'summary' => 'persists the master connection in the background',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DynamicForward',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies that a TCP port on the local machine be forwarded over the secure channel, and the application protocol is then used to determine where to connect to from the remote machine.

The argument must be [bind_address:]port. IPv6 addresses can be specified by enclosing addresses in square brackets or by using an alternative syntax: [bind_address/]port. By default, the local port is bound in accordance with the GatewayPorts setting. However, an explicit bind_address may be used to bind the connection to a specific address. The bind_address of \'localhost\' indicates that the listening port be bound for local use only, while an empty address or \'*\' indicates that the port should be available from all interfaces.

Currently the SOCKS4 and SOCKS5 protocols are supported, and ssh(1) will act as a SOCKS server. Multiple forwardings may be specified, and additional forwardings can be given on the command line. Only the superuser can forward privileged ports.
',
        'type' => 'list'
      },
      'EscapeChar',
      {
        'description' => 'Sets the escape character (default: \'~\'). The escape character can also be set on the command line.  The argument should be a single character, \'^\' followed by a letter, or \'none\' to disable the escape character entirely (making the connection transparent for binary data).
',
        'type' => 'leaf',
        'upstream_default' => '~',
        'value_type' => 'uniline'
      },
      'ExitOnForwardFailure',
      {
        'description' => 'Specifies whether ssh(1) should terminate the connection if it cannot set up all requested dynamic, tunnel, local, and remote port forwardings.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'ForwardAgent',
      {
        'description' => 'Specifies whether the connection to the authentication agent (if any) will be forwarded to the remote machine. 

Agent forwarding should be enabled with caution.  Users with the ability to bypass file permissions on the remote host (for the agent\'s Unix-domain socket) can access the local agent through the forwarded connection.  An attacker cannot obtain key material from the agent, however they can perform operations on the keys that enable them to authenticate using the identities loaded into the agent.
',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'ForwardX11',
      {
        'description' => 'Specifies whether X11 connections will be automatically redirected over the secure channel and DISPLAY set.

X11 forwarding should be enabled with caution.  Users with the ability to bypass file permissions on the remote host (for the user\'s X11 authorization database) can access the local X11 dis play through the forwarded connection.  An attacker may then be able to perform activities such as keystroke monitoring if the ForwardX11Trusted option is also enabled.
',
        'level' => 'important',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'ForwardX11Timeout',
      {
        'description' => 'Specify a timeout for untrusted X11 forwarding using the format described in the TIME FORMATS section of L<sshd_config(5)>. X11 connections received by L<ssh(1)> after this time will be refused. The default is to disable untrusted X11 forwarding after twenty minutes has elapsed.',
        'summary' => 'timeout for untrusted X11 forwarding',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ForwardX11Trusted',
      {
        'description' => 'If this option is set, remote X11 clients will have full access to the original X11 display.

If this option is not set, remote X11 clients will be considered untrusted and prevented from stealing or tampering with data belonging to trusted X11 clients. Furthermore, the xauth(1) token used for the session will be set to expire after 20 minutes. Remote clients will be refused access after this time.

See the X11 SECURITY extension specification for full details on the restrictions imposed on untrusted clients.
',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'GatewayPorts',
      {
        'description' => 'Specifies whether remote hosts are allowed to connect to local forwarded ports. By default, ssh(1) binds local port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that ssh should bind local port forwardings to the wildcard address, thus allowing remote hosts to connect to forwarded ports. ',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'GlobalKnownHostsFile',
      {
        'description' => 'Specifies a file to use for the global host key database',
        'type' => 'leaf',
        'upstream_default' => '/etc/ssh/ssh_known_hosts',
        'value_type' => 'uniline'
      },
      'GSSAPIAuthentication',
      {
        'description' => 'Specifies whether user authentication based on GSSAPI is allowed. Note that this option applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'GSSAPIKeyExchange',
      {
        'description' => 'Specifies whether key exchange based on GSSAPI may be used. When using GSSAPI key exchange the server need not have a host key. Note that this option applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'GSSAPIClientIdentity',
      {
        'description' => 'If set, specifies the GSSAPI client identity that ssh should use when connecting to the server. The default is unset, which means that the default identity will be used.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'GSSAPIServerIdentity',
      {
        'description' => 'If set, specifies the GSSAPI server identity that ssh should expect when connecting to the server. The default is unset, which means that the expected GSSAPI server identity will be determined from the target hostname.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'GSSAPIDelegateCredentials',
      {
        'description' => 'Forward (delegate) credentials to the server. Note that this option applies to protocol version 2 connections using GSSAPI.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'GSSAPIRenewalForcesRekey',
      {
        'description' => 'If set to "yes" then renewal of the client\'s GSSAPI credentials will force the rekeying of the ssh connection. With a compatible server, this can delegate the renewed credentials to a session on the server.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'GSSAPITrustDns',
      {
        'description' => 'Set to "yes" to indicate that the DNS is trusted to securely canonicalize the name of the host being connected to. If "no", the hostname entered on the command line will be passed untouched to the GSSAPI library. This option only applies to protocol version 2 connections using GSSAPI.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'HashKnownHosts',
      {
        'description' => 'Indicates that ssh(1) should hash host names and addresses when they are added to ~/.ssh/known_hosts. These hashed names may be used normally by ssh(1) and sshd(8), but they do not reveal identifying information should the file\'s contents be disclosed. Note that existing names and addresses in known hosts files will not be converted automatically, but may be manually hashed using ssh-keygen(1).
',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'HostbasedAuthentication',
      {
        'description' => 'Specifies whether to try rhosts based authentication with public key authentication. This option applies to protocol version 2 only and is similar to RhostsRSAAuthentication.
',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'HostKeyAlgorithms',
      {
        'choice' => [
          'ssh-rsa',
          'ssh-dss'
        ],
        'description' => 'Specifies the protocol version 2 host key algorithms that the client wants to use in order of preference.',
        'ordered' => '1',
        'type' => 'check_list',
        'upstream_default_list' => [
          'ssh-rsa',
          'ssh-dss'
        ]
      },
      'HostKeyAlias',
      {
        'description' => 'Specifies an alias that should be used instead of the real host name when looking up or saving the host key in the host key database files. This option is useful for tunneling SSH connections or for multiple servers running on a single host.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'HostName',
      {
        'description' => 'Specifies the real host name to log into. This can be used to specify nicknames or abbreviations for hosts. The default is the name given on the command line. Numeric IP addresses are also permitted (both on the command line and in HostName specifications).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IdentitiesOnly',
      {
        'description' => 'Specifies that ssh(1) should only use the authentication identity files configured in the ssh_config files, even if ssh-agent(1) offers more identities. This option is intended for situations where ssh-agent offers many different identities.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'IdentityFile',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline',
          'warn_if_match' => {
            '\\.pub$' => {
              'fix' => 's/\\.pub$//;',
              'msg' => 'identity file should be the private key '
            }
          }
        },
        'description' => 'Specifies a file from which the user\'s RSA or DSA authentication identity is read. The default is ~/.ssh/identity for protocol version 1, and ~/.ssh/id_rsa and ~/.ssh/id_dsa for protocol version 2. Additionally, any identities represented by the authentication agent will be used for authentication.

The file name may use the tilde syntax to refer to a user\'s home directory or one of the following escape characters: \'%d\' (local user\'s home directory), \'%u\' (local user name), \'%l\' (local host  name), \'%h\' (remote host name) or \'%r\' (remote user name).

It is possible to have multiple identity files specified in con figuration files; all these identities will be tried in sequence.
',
        'type' => 'list'
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
        'description' => 'Specifies whether to use keyboard-interactive authentication.
',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'KbdInteractiveDevices',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies the list of methods to use in keyboard-interactive authentication.  Multiple method names must be comma-separated. The default is to use the server specified list. The methods available vary depending on what the server supports. For an OpenSSH server, it may be zero or more of: \'bsdauth\', \'pam\', and \'skey\'.',
        'type' => 'list'
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
      'LocalForward',
      {
        'cargo' => {
          'config_class_name' => 'Ssh::PortForward',
          'type' => 'node'
        },
        'description' => 'Specifies that a TCP port on the local machine be forwarded over the secure channel to the specified host and port from the remote machine. The first argument must be [bind_address:]port and the second argument must be host:hostport. 

IPv6 addresses can be specified by enclosing addresses in square brackets or by using an alternative syntax: [bind_address/]port and host/hostport. 

Multiple forwardings may be specified, and additional forwardings can be given on the command line. Only the superuser can forward privileged ports. 

By default, the local port is bound in accordance with the GatewayPorts setting. However, an explicit bind_address may be used to bind the connection to a specific address. The bind_address of "localhost" indicates that the listening port be bound for local use only, while an empty address or \'*\' indicates that the port should be available from all interfaces.

Example:
   LocalForward 20000 192.168.0.66:80
',
        'summary' => 'Local port forwarding',
        'type' => 'list'
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
        'description' => 'Gives the verbosity level that is used when logging messages from ssh(1).  The possible values are: SILENT, QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG, DEBUG1, DEBUG2, and DEBUG3.  The default is INFO.  DEBUG and DEBUG1 are equivalent.  DEBUG2 and DEBUG3 each specify higher levels of verbose output.',
        'type' => 'leaf',
        'upstream_default' => 'INFO',
        'value_type' => 'enum'
      },
      'MACs',
      {
        'choice' => [
          'hmac-md5',
          'hmac-sha1',
          'umac-64@openssh.com',
          'hmac-ripemd160',
          'hmac-sha1-96',
          'hmac-md5-96'
        ],
        'description' => 'Specifies the MAC (message authentication code) algorithms in order of preference. The MAC algorithm is used in protocol version 2 for data integrity protection.',
        'ordered' => '1',
        'type' => 'check_list',
        'upstream_default_list' => [
          'hmac-md5',
          'hmac-sha1',
          'umac-64@openssh.com',
          'hmac-ripemd160',
          'hmac-sha1-96',
          'hmac-md5-96'
        ]
      },
      'NoHostAuthenticationForLocalhost',
      {
        'description' => 'This option can be used if the home directory is shared across machines. In this case localhost will refer to a different machine on each of the machines and the user will get many warn ings about changed host keys. However, this option disables host authentication for localhost. The default is to check the host key for localhost.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'NumberOfPasswordPrompts',
      {
        'description' => 'Specifies the number of password prompts before giving up.',
        'type' => 'leaf',
        'upstream_default' => '3',
        'value_type' => 'integer'
      },
      'PasswordAuthentication',
      {
        'description' => 'Specifies whether to use password authentication.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'PermitLocalCommand',
      {
        'description' => 'Allow local command execution via the LocalCommand option or using the !command escape sequence in ssh(1).',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'LocalCommand',
      {
        'description' => 'Specifies a command to execute on the local machine after successfully connecting to the server. The command string extends to the end of the line, and is executed with the user\'s shell. The following escape character substitutions will be performed: \'%d\' (local user\'s home directory), \'%h\' (remote host name), \'%l\' (local host name), \'%n\' (host name as provided on the command line), \'%p\' (remote port), \'%r\' (remote user name) or \'%u\' (local user name). This directive is ignored unless PermitLocalCommand has been enabled.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PKCS11Provider',
      {
        'description' => 'Specifies which PKCS#11 provider to use. The argument to this keyword is the PKCS#11 shared library ssh(1) should use to communicate with a PKCS#11 token providing the user\'s private RSA key.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Port',
      {
        'description' => 'Specifies the port number to connect on the remote host.',
        'type' => 'leaf',
        'upstream_default' => '22',
        'value_type' => 'integer'
      },
      'PreferredAuthentications',
      {
        'choice' => [
          'gssapi-with-mic',
          'hostbased',
          'publickey',
          'keyboard-interactive',
          'password'
        ],
        'description' => 'Specifies the order in which the client should try protocol 2 authentication methods.  This allows a client to prefer one method (e.g. keyboard-interactive) over another method (e.g. password).',
        'ordered' => '1',
        'type' => 'check_list',
        'upstream_default_list' => [
          'gssapi-with-mic',
          'hostbased',
          'publickey',
          'keyboard-interactive',
          'password'
        ]
      },
      'Protocol',
      {
        'choice' => [
          '2',
          '1'
        ],
        'description' => 'Specifies the protocol versions ssh(1) should support in order of preference.  The default is "2,1".  This means that ssh tries version 2 and falls back to version 1 if version 2 is not available.',
        'ordered' => '1',
        'type' => 'check_list',
        'upstream_default_list' => [
          '2',
          '1'
        ]
      },
      'ProxyCommand',
      {
        'description' => 'Specifies the command to use to connect to the server. The command string extends to the end of the line, and is executed with the user\'s shell. In the command string, \'%h\' will be substi tuted by the host name to connect and \'%p\' by the port.  The com mand can be basically anything, and should read from its standard input and write to its standard output. It should eventually connect an sshd(8) server running on some machine, or execute sshd -i somewhere. Host key management will be done using the HostName of the host being connected (defaulting to the name typed by the user).  Setting the command to "none" disables this option entirely. Note that CheckHostIP is not available for connects with a proxy command.

This directive is useful in conjunction with nc(1) and its proxy support. For example, the following directive would connect via an HTTP proxy at 192.0.2.0:

    ProxyCommand /usr/bin/nc -X connect -x 192.0.2.0:8080 %h %p',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PubkeyAuthentication',
      {
        'description' => 'Specifies whether to try public key authentication. This option applies to protocol version 2 only.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'RekeyLimit',
      {
        'description' => 'Specifies the maximum amount of data that may be transmitted before the session key is renegotiated.  The argument is the number of bytes, with an optional suffix of \'K\', \'M\', or \'G\' to indicate Kilobytes, Megabytes, or Gigabytes, respectively.  The default is between \'1G\' and \'4G\', depending on the cipher.  This option applies to protocol version 2 only.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RemoteForward',
      {
        'cargo' => {
          'config_class_name' => 'Ssh::PortForward',
          'type' => 'node'
        },
        'description' => 'Specifies that a TCP port on the remote machine be forwarded over the secure channel to the specified host and port from the local machine. Multiple forwardings may be specified, and additional forwardings can be given on the command line. Only the superuser can forward privileged ports.

If the bind_address is not specified, the default is to only bind to loopback addresses. If the bind_address is \'*\' or an empty string, then the forwarding is requested to listen on all inter faces. Specifying a remote bind_address will only succeed if the server\'s GatewayPorts option is enabled (see sshd_config(5)).',
        'level' => 'important',
        'summary' => 'remote port forward to local',
        'type' => 'list'
      },
      'RequestTTY',
      {
        'choice' => [
          'yes',
          'no',
          'force',
          'auto'
        ],
        'description' => 'Specifies whether to request a pseudo-tty for the session. This option mirrors the -t and -T flags for C<ssh>.',
        'help' => {
          'auto' => 'request a TTY when opening a login session',
          'force' => 'always request a TTY',
          'no' => 'never request a TTY',
          'yes' => 'always request a TTY when standard input is a TTY'
        },
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'RhostsRSAAuthentication',
      {
        'description' => 'Specifies whether to try rhosts based authentication with RSA host authentication. This option applies to protocol version 1 only and requires ssh(1) to be setuid root.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'RSAAuthentication',
      {
        'description' => 'Specifies whether to try RSA authentication. RSA authentication will only be attempted if the identity file exists, or an authentication agent is running. Note that this option applies to protocol version 1 only.',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'SendEnv',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies what variables from the local environ(7) should be sent to the server. Note that environment passing is only supported for protocol 2. The server must also support it, and the server must be configured to accept these environment variables. Refer to AcceptEnv in sshd_config(5) for how to configure the server. Variables are specified by name, which may contain wildcard char acters. Multiple environment variables may be separated by whitespace or spread across multiple SendEnv directives. The default is not to send any environment variables.

See PATTERNS in ssh_config(5) for more information on patterns.',
        'type' => 'list'
      },
      'ServerAliveCountMax',
      {
        'description' => 'Sets the number of server alive messages (see below) which may be sent without ssh(1) receiving any messages back from the server. If this threshold is reached while server alive messages are being sent, ssh will disconnect from the server, terminating the session.  It is important to note that the use of server alive messages is very different from TCPKeepAlive.  The server alive messages are sent through the encrypted channel and there fore will not be spoofable. The TCP keepalive option enabled by TCPKeepAlive is spoofable. The server alive mechanism is valuable when the client or server depend on knowing when a connec tion has become inactive.

The default value is 3. If, for example, ServerAliveInterval is set to 15 and ServerAliveCountMax is left at the default, if the server becomes unresponsive, ssh will disconnect after approximately 45 seconds.  This option applies to protocol version 2 only; in protocol version 1 there is no mechanism to request a response from the server to the server alive messages, so disconnection is the responsibility of the TCP stack.',
        'type' => 'leaf',
        'upstream_default' => '3',
        'value_type' => 'integer'
      },
      'ServerAliveInterval',
      {
        'description' => 'Sets a timeout interval in seconds after which if no data has been received from the server, ssh(1) will send a message through the encrypted channel to request a response from the server.  The default is 0, indicating that these messages will not be sent to the server, or 300 if the BatchMode option is set.  This option applies to protocol version 2 only.  ProtocolKeepAlives and SetupTimeOut are Debian-specific compatibility aliases for this option.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer',
        'warp' => {
          'follow' => {
            'batch_mode' => '?BatchMode'
          },
          'rules' => [
            '$batch_mode eq \'1\'',
            {
              'upstream_default' => '300'
            }
          ]
        }
      },
      'SmartcardDevice',
      {
        'description' => 'Specifies which smartcard device to use.  The argument to this keyword is the device ssh(1) should use to communicate with a smartcard used for storing the user\'s private RSA key.  By default, no device is specified and smartcard support is not activated.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StrictHostKeyChecking',
      {
        'choice' => [
          'yes',
          'no',
          'ask'
        ],
        'description' => 'If this flag is set to "yes", ssh(1) will never automatically add host keys to the ~/.ssh/known_hosts file, and refuses to connect to hosts whose host key has changed.  This provides maximum protection against trojan horse attacks, though it can be annoying when the /etc/ssh/ssh_known_hosts file is poorly maintained or when connections to new hosts are frequently made.  This option forces the user to manually add all new hosts.  If this flag is set to "no", ssh will automatically add new host keys to the user known hosts files.  If this flag is set to "ask", new host keys will be added to the user known host files only after the user has confirmed that is what they really want to do, and ssh will refuse to connect to hosts whose host key has changed.  The host keys of known hosts will be verified automatically in all cases. The argument must be "yes", "no", or "ask".  The default is "ask".',
        'type' => 'leaf',
        'upstream_default' => 'ask',
        'value_type' => 'enum'
      },
      'TCPKeepAlive',
      {
        'description' => 'Specifies whether the system should send TCP keepalive messages to the other side.  If they are sent, death of the connection or crash of one of the machines will be properly noticed.  This option only uses TCP keepalives (as opposed to using ssh level keepalives), so takes a long time to notice when the connection dies.  As such, you probably want the ServerAliveInterval option as well.  However, this means that connections will die if the route is down temporarily, and some people find it annoying. The default is "yes" (to send TCP keepalive messages), and the client will notice if the network goes down or the remote host dies.  This is important in scripts, and many users want it too.

To disable TCP keepalive messages, the value should be set to "no".',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'Tunnel',
      {
        'choice' => [
          'yes',
          'point-to-point',
          'ethernet',
          'no'
        ],
        'description' => 'Request tun(4) device forwarding between the client and the server.  The argument must be "yes", "point-to-point" (layer 3), "ethernet" (layer 2), or "no".  Specifying "yes" requests the default tunnel mode, which is "point-to-point".  The default is "no".',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'TunnelDevice',
      {
        'description' => 'Specifies the tun(4) devices to open on the client (local_tun) and the server (remote_tun).

             The argument must be local_tun[:remote_tun].  The devices may be specified by numerical ID or the keyword "any", which uses the next available tunnel device.  If remote_tun is not specified, it defaults to "any".  The default is "any:any".',
        'type' => 'leaf',
        'upstream_default' => 'any:any',
        'value_type' => 'uniline'
      },
      'UseBlacklistedKeys',
      {
        'description' => 'Specifies whether ssh(1) should use keys recorded in its blacklist of known-compromised keys (see ssh-vulnkey(1)) for authentication.  If "yes", then attempts to use compromised keys for authentication will be logged but accepted.  It is strongly recommended that this be used only to install new authorized keys on the remote system, and even then only with the utmost care.  If "no", then attempts to use compromised keys for authentication will be prevented.  The default is "no".',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'UsePrivilegedPort',
      {
        'description' => 'Specifies whether to use a privileged port for outgoing connections.  The argument must be "yes" or "no".  The default is "no". If set to "yes", ssh(1) must be setuid root.  Note that this option must be set to "yes" for RhostsRSAAuthentication with older servers.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'User',
      {
        'description' => 'Specifies the user to log in as.  This can be useful when a dif ferent user name is used on different machines.  This saves the trouble of having to remember to give the user name on the command line.',
        'level' => 'important',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UserKnownHostsFile',
      {
        'description' => 'Specifies a file to use for the user host key database instead of ~/.ssh/known_hosts.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'VerifyHostKeyDNS',
      {
        'choice' => [
          'yes',
          'no',
          'ask'
        ],
        'description' => 'Specifies whether to verify the remote key using DNS and SSHFP resource records.  If this option is set to "yes", the client will implicitly trust keys that match a secure fingerprint from DNS.  Insecure fingerprints will be handled as if this option was set to "ask".  If this option is set to "ask", information on fingerprint match will be displayed, but the user will still need to confirm new host keys according to the StrictHostKeyChecking option.  The argument must be "yes", "no", or "ask".  The default is "no".  Note that this option applies to protocol version 2 only. 
See also VERIFYING HOST KEYS in ssh(1).',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'VisualHostKey',
      {
        'description' => 'If this flag is set to "yes", an ASCII art representation of the remote host key fingerprint is printed additionally to the hex fingerprint string.  If this flag is set to "no", only the hex fingerprint string will be printed.  The default is "no".',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'XAuthLocation',
      {
        'description' => 'Specifies the full pathname of the xauth(1) program.  The default is /usr/bin/X11/xauth.',
        'type' => 'leaf',
        'upstream_default' => '/usr/X11R6/bin/xauth',
        'value_type' => 'uniline'
      },
      'UseRsh',
      {
        'description' => 'This parameter is now ignored by Ssh',
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'FallBackToRsh',
      {
        'description' => 'This parameter is now ignored by Ssh',
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Ssh::HostElement'
  }
]
;


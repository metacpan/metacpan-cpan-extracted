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
    'class_description' => 'This configuration class was generated from sshd_system documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-openssh/contrib/parse-man.pl>
',
    'element' => [
      'AddressFamily',
      {
        'choice' => [
          'any',
          'inet',
          'inet6'
        ],
        'description' => 'B<AddressFamily>Specifies which address family
should be used by L<sshd(8)>. Valid arguments are B<any>
(the default), B<inet> (use IPv4 only), or B<inet6>
(use IPv6 only).',
        'type' => 'leaf',
        'upstream_default' => 'any',
        'value_type' => 'enum'
      },
      'CASignatureAlgorithms',
      {
        'description' => 'B<CASignatureAlgorithms>Specifies which algorithms are
allowed for signing of certificates by certificate
authorities (CAs). The default is:ecdsa-sha2-nistp256.ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,

ssh-ed25519,rsa-sha2-512,rsa-sha2-256,ssh-rsaCertificates
signed using other algorithms will not be accepted for
public key or host-based authentication.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ChallengeResponseAuthentication',
      {
        'description' => 'B<ChallengeResponseAuthentication>Specifies whether
challenge-response authentication is allowed (e.g. via PAM).
The default is B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Ciphers',
      {
        'description' => "B<Ciphers>Specifies the ciphers allowed.
Multiple ciphers must be comma-separated. If the specified
value begins with a \x{2019}+\x{2019} character, then the
specified ciphers will be appended to the default set
instead of replacing them. If the specified value begins
with a \x{2019}-\x{2019} character, then the specified ciphers
(including wildcards) will be removed from the default set
instead of replacing them.The supported
ciphers are:3des-cbc 
aes128-cbc 
aes192-cbc 
aes256-cbc 
aes128-ctr 
aes192-ctr 
aes256-ctr 
aes128-gcm\@openssh.com 
aes256-gcm\@openssh.com 
chacha20-poly1305\@openssh.comThe default
is:chacha20-poly1305\@openssh.com,

aes128-ctr,aes192-ctr,aes256-ctr, 
aes128-gcm\@openssh.com,aes256-gcm\@openssh.comThe list of
available ciphers may also be obtained using \"ssh -Q
cipher\".",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Compression',
      {
        'choice' => [
          'yes',
          'delayed',
          'no'
        ],
        'description' => 'B<Compression>Specifies whether compression
is enabled after the user has authenticated successfully.
The argument must be B<yes>, B<delayed> (a legacy
synonym for B<yes>) or B<no>. The default is
B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'DebianBanner',
      {
        'description' => 'B<DebianBanner>Specifies whether the
distribution-specified extra version suffix is included
during initial protocol handshake. The default is
B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'DisableForwarding',
      {
        'description' => 'B<DisableForwarding>Disables all forwarding
features, including X11, L<ssh-agent(1)>, TCP and StreamLocal.
This option overrides all other forwarding-related options
and may simplify restricted configurations.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ExposeAuthInfo',
      {
        'description' => 'B<ExposeAuthInfo>Writes a temporary file
containing a list of authentication methods and public
credentials (e.g. keys) used to authenticate the user. The
location of the file is exposed to the user session through
the SSH_USER_AUTH environment variable. The default is
B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'FingerprintHash',
      {
        'choice' => [
          'md5',
          'sha256'
        ],
        'description' => 'B<FingerprintHash>Specifies the hash algorithm
used when logging key fingerprints. Valid options are:
B<md5> and B<sha256>. The default is
B<sha256>.',
        'type' => 'leaf',
        'upstream_default' => 'sha256',
        'value_type' => 'enum'
      },
      'GSSAPIKeyExchange',
      {
        'description' => "B<GSSAPIKeyExchange>Specifies whether key exchange
based on GSSAPI is allowed. GSSAPI key exchange
doesn\x{2019}t rely on ssh keys to verify host identity. The
default is B<no>.",
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'GSSAPICleanupCredentials',
      {
        'description' => "B<GSSAPICleanupCredentials>Specifies whether to
automatically destroy the user\x{2019}s credentials cache on
logout. The default is B<yes>.",
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'GSSAPIStrictAcceptorCheck',
      {
        'description' => "B<GSSAPIStrictAcceptorCheck>Determines whether to be strict
about the identity of the GSSAPI acceptor a client
authenticates against. If set to B<yes> then the client
must authenticate against the host service on the current
hostname. If set to B<no> then the client may
authenticate against any service key stored in the
machine\x{2019}s default store. This facility is provided to
assist with operation on multi homed machines. The default
is B<yes>.",
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'GSSAPIStoreCredentialsOnRekey',
      {
        'description' => "B<GSSAPIStoreCredentialsOnRekey>Controls whether the
user\x{2019}s GSSAPI credentials should be updated following
a successful connection rekeying. This option can be used to
accepted renewed or updated credentials from a compatible
client. The default is B<no>.",
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'HostCertificate',
      {
        'description' => "B<HostCertificate>Specifies a file containing a
public host certificate. The certificate\x{2019}s public key
must match a private host key already specified by
B<HostKey>. The default behaviour of L<sshd(8)> is not to
load any certificates.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'HostKey',
      {
        'description' => 'B<HostKey>Specifies a file containing a
private host key used by SSH. The defaults are
I</etc/ssh/ssh_host_ecdsa_key>,
I</etc/ssh/ssh_host_ed25519_key> and
I</etc/ssh/ssh_host_rsa_key>.Note that
L<sshd(8)> will refuse to use a file if it is
group/world-accessible and that the B<HostKeyAlgorithms>
option restricts which of the keys are actually used by
L<sshd(8)>.It is possible
to have multiple host key files. It is also possible to
specify public host key files instead. In this case
operations on the private key will be delegated to an
L<ssh-agent(1)>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'HostKeyAgent',
      {
        'description' => 'B<HostKeyAgent>Identifies the UNIX-domain
socket used to communicate with an agent that has access to
the private host keys. If the string
"SSH_AUTH_SOCK" is specified, the location of the
socket will be read from the SSH_AUTH_SOCK environment
variable.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'HostKeyAlgorithms',
      {
        'description' => 'B<HostKeyAlgorithms>Specifies the host key
algorithms that the server offers. The default for this
option is:ecdsa-sha2-nistp256-cert-v01@openssh.com,

ecdsa-sha2-nistp384-cert-v01@openssh.com, 
ecdsa-sha2-nistp521-cert-v01@openssh.com, 
ssh-ed25519-cert-v01@openssh.com, 

rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,

ssh-rsa-cert-v01@openssh.com, 

ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,

ssh-ed25519,rsa-sha2-512,rsa-sha2-256,ssh-rsaThe list of
available key types may also be obtained using "ssh -Q
key".',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IgnoreRhosts',
      {
        'description' => 'B<IgnoreRhosts>Specifies that I<.rhosts>
and I<.shosts> files will not be used in
B<HostbasedAuthentication>.I</etc/hosts.equiv>
and I</etc/ssh/shosts.equiv> are still used. The default
is B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'IgnoreUserKnownHosts',
      {
        'description' => "B<IgnoreUserKnownHosts>Specifies whether L<sshd(8)>
should ignore the user\x{2019}s I<~/.ssh/known_hosts>
during B<HostbasedAuthentication> and use only the
system-wide known hosts file I</etc/ssh/known_hosts>.
The default is B<no>.",
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'KerberosGetAFSToken',
      {
        'description' => "B<KerberosGetAFSToken>If AFS is active and the user
has a Kerberos 5 TGT, attempt to acquire an AFS token before
accessing the user\x{2019}s home directory. The default is
B<no>.",
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'KerberosOrLocalPasswd',
      {
        'description' => 'B<KerberosOrLocalPasswd>If password authentication
through Kerberos fails then the password will be validated
via any additional local mechanism such as
I</etc/passwd>. The default is B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'KerberosTicketCleanup',
      {
        'description' => "B<KerberosTicketCleanup>Specifies whether to
automatically destroy the user\x{2019}s ticket cache file on
logout. The default is B<yes>.",
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'KexAlgorithms',
      {
        'description' => "B<KexAlgorithms>Specifies the available KEX
(Key Exchange) algorithms. Multiple algorithms must be
comma-separated. Alternately if the specified value begins
with a \x{2019}+\x{2019} character, then the specified methods
will be appended to the default set instead of replacing
them. If the specified value begins with a \x{2019}-\x{2019}
character, then the specified methods (including wildcards)
will be removed from the default set instead of replacing
them. The supported algorithms are:curve25519-sha256

curve25519-sha256\@libssh.org 
diffie-hellman-group1-sha1 
diffie-hellman-group14-sha1 
diffie-hellman-group14-sha256 
diffie-hellman-group16-sha512 
diffie-hellman-group18-sha512 
diffie-hellman-group-exchange-sha1 
diffie-hellman-group-exchange-sha256 
ecdh-sha2-nistp256 
ecdh-sha2-nistp384 
ecdh-sha2-nistp521The default
is:curve25519-sha256,curve25519-sha256\@libssh.org,

ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,

diffie-hellman-group-exchange-sha256, 

diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,


diffie-hellman-group14-sha256,diffie-hellman-group14-sha1The list of
available key exchange algorithms may also be obtained using
\"ssh -Q kex\".",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ListenAddress',
      {
        'description' => 'B<ListenAddress>Specifies the local addresses
L<sshd(8)> should listen on. The following forms may be
used:B<ListenAddress>I<hostname>|I<address> [B<rdomain>I<domain>] B<
ListenAddress> I<hostname>:I<port>
[B<rdomain> I<domain>] B<
ListenAddress> I<IPv4_address>:I<port>
[B<rdomain> I<domain>] B<
ListenAddress> [I<hostname>|I<address> ]:I<port>
[B<rdomain> I<domain>]The optional
B<rdomain> qualifier requests L<sshd(8)> listen in an
explicit routing domain. If I<port> is not specified,
sshd will listen on the address and all B<Port> options
specified. The default is to listen on all local addresses
on the current default routing domain. Multiple
B<ListenAddress> options are permitted. For more
information on routing domains, see L<rdomain(4)>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LoginGraceTime',
      {
        'description' => 'B<LoginGraceTime>The server disconnects after
this time if the user has not successfully logged in. If the
value is 0, there is no time limit. The default is 120
seconds.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MACs',
      {
        'description' => "B<MACs>Specifies the
available MAC (message authentication code) algorithms. The
MAC algorithm is used for data integrity protection.
Multiple algorithms must be comma-separated. If the
specified value begins with a \x{2019}+\x{2019} character,
then the specified algorithms will be appended to the
default set instead of replacing them. If the specified
value begins with a \x{2019}-\x{2019} character, then the
specified algorithms (including wildcards) will be removed
from the default set instead of replacing them.The algorithms
that contain \"-etm\" calculate the MAC after
encryption (encrypt-then-mac). These are considered safer
and their use recommended. The supported MACs are:hmac-md5 
hmac-md5-96 
hmac-sha1 
hmac-sha1-96 
hmac-sha2-256 
hmac-sha2-512 
umac-64\@openssh.com 
umac-128\@openssh.com 
hmac-md5-etm\@openssh.com 
hmac-md5-96-etm\@openssh.com 
hmac-sha1-etm\@openssh.com 
hmac-sha1-96-etm\@openssh.com 
hmac-sha2-256-etm\@openssh.com 
hmac-sha2-512-etm\@openssh.com 
umac-64-etm\@openssh.com 
umac-128-etm\@openssh.comThe default
is:umac-64-etm\@openssh.com,umac-128-etm\@openssh.com,


hmac-sha2-256-etm\@openssh.com,hmac-sha2-512-etm\@openssh.com,

hmac-sha1-etm\@openssh.com, 
umac-64\@openssh.com,umac-128\@openssh.com, 
hmac-sha2-256,hmac-sha2-512,hmac-sha1The list of
available MAC algorithms may also be obtained using
\"ssh -Q mac\".",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Match',
      {
        'cargo' => {
          'config_class_name' => 'Sshd::MatchBlock',
          'type' => 'node'
        },
        'description' => 'B<Match>Introduces a
conditional block. If all of the criteria on the
B<Match> line are satisfied, the keywords on the
following lines override those set in the global section of
the config file, until either another B<Match> line or
the end of the file. If a keyword appears in multiple
B<Match> blocks that are satisfied, only the first
instance of the keyword is applied.The arguments
to B<Match> are one or more criteria-pattern pairs or
the single token B<All> which matches all criteria. The
available criteria are B<User>, B<Group>,
B<Host>, B<LocalAddress>, B<LocalPort>,
B<RDomain>, and B<Address> (with B<RDomain>
representing the L<rdomain(4)> on which the connection was
received.)The match
patterns may consist of single entries or comma-separated
lists and may use the wildcard and negation operators
described in the I<PATTERNS> section of
L<ssh_config(5)>.The patterns in
an B<Address> criteria may additionally contain
addresses to match in CIDR address/masklen format, such as
192.0.2.0/24 or 2001:db8::/32. Note that the mask length
provided must be consistent with the address - it is an
error to specify a mask length that is too long for the
address or one with bits set in this host portion of the
address. For example, 192.0.2.0/33 and 192.0.2.0/8,
respectively.Only a subset
of keywords may be used on the lines following a
B<Match> keyword. Available keywords are
B<AcceptEnv>, B<AllowAgentForwarding>,
B<AllowGroups>, B<AllowStreamLocalForwarding>,
B<AllowTcpForwarding>, B<AllowUsers>,
B<AuthenticationMethods>, B<AuthorizedKeysCommand>,
B<AuthorizedKeysCommandUser>, B<AuthorizedKeysFile>,
B<AuthorizedPrincipalsCommand>,
B<AuthorizedPrincipalsCommandUser>,
B<AuthorizedPrincipalsFile>, B<Banner>,
B<ChrootDirectory>, B<ClientAliveCountMax>,
B<ClientAliveInterval>, B<DenyGroups>,
B<DenyUsers>, B<ForceCommand>, B<GatewayPorts>,
B<GSSAPIAuthentication>,
B<HostbasedAcceptedKeyTypes>,
B<HostbasedAuthentication>,
B<HostbasedUsesNameFromPacketOnly>, B<IPQoS>,
B<KbdInteractiveAuthentication>,
B<KerberosAuthentication>, B<LogLevel>,
B<MaxAuthTries>, B<MaxSessions>,
B<PasswordAuthentication>, B<PermitEmptyPasswords>,
B<PermitListen>, B<PermitOpen>,
B<PermitRootLogin>, B<PermitTTY>,
B<PermitTunnel>, B<PermitUserRC>,
B<PubkeyAcceptedKeyTypes>, B<PubkeyAuthentication>,
B<RekeyLimit>, B<RevokedKeys>, B<RDomain>,
B<SetEnv>, B<StreamLocalBindMask>,
B<StreamLocalBindUnlink>, B<TrustedUserCAKeys>,
B<X11DisplayOffset>, B<X11Forwarding> and
B<X11UseLocalHost>.',
        'type' => 'list'
      },
      'MaxStartups',
      {
        'description' => 'B<MaxStartups>Specifies the maximum number of
concurrent unauthenticated connections to the SSH daemon.
Additional connections will be dropped until authentication
succeeds or the B<LoginGraceTime> expires for a
connection. The default is 10:30:100.Alternatively,
random early drop can be enabled by specifying the three
colon separated values start:rate:full (e.g.
"10:30:60"). L<sshd(8)> will refuse connection
attempts with a probability of rate/100 (30%) if there are
currently start (10) unauthenticated connections. The
probability increases linearly and all connection attempts
are refused if the number of unauthenticated connections
reaches full (60).',
        'type' => 'leaf',
        'upstream_default' => '10',
        'value_type' => 'uniline'
      },
      'PermitUserEnvironment',
      {
        'description' => 'B<PermitUserEnvironment>Specifies whether
I<~/.ssh/environment> and B<environment=> options in
I<~/.ssh/authorized_keys> are processed by L<sshd(8)>.
Valid options are B<yes>, B<no> or a pattern-list
specifying which environment variable names to accept (for
example "LANG,LC_*"). The default is B<no>.
Enabling environment processing may enable users to bypass
access restrictions in some configurations using mechanisms
such as LD_PRELOAD.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PidFile',
      {
        'description' => 'B<PidFile>Specifies the file that
contains the process ID of the SSH daemon, or B<none> to
not write one. The default is I</run/sshd.pid>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Port',
      {
        'description' => 'B<Port>Specifies the
port number that L<sshd(8)> listens on. The default is 22.
Multiple options of this type are permitted. See also
B<ListenAddress>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PrintLastLog',
      {
        'description' => 'B<PrintLastLog>Specifies whether L<sshd(8)>
should print the date and time of the last user login when a
user logs in interactively. The default is B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PrintMotd',
      {
        'description' => 'B<PrintMotd>Specifies whether L<sshd(8)>
should print I</etc/motd> when a user logs in
interactively. (On some systems it is also printed by the
shell, I</etc/profile>, or equivalent.) The default is
B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'StrictModes',
      {
        'description' => "B<StrictModes>Specifies whether L<sshd(8)>
should check file modes and ownership of the user\x{2019}s
files and home directory before accepting login. This is
normally desirable because novices sometimes accidentally
leave their directory or files world-writable. The default
is B<yes>. Note that this does not apply to
B<ChrootDirectory>, whose permissions and ownership are
checked unconditionally.",
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Subsystem',
      {
        'cargo' => {
          'mandatory' => '1',
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'B<Subsystem>Configures an external
subsystem (e.g. file transfer daemon). Arguments should be a
subsystem name and a command (with optional arguments) to
execute upon subsystem request.The command
B<sftp-server> implements the SFTP file transfer
subsystem.Alternately the
name B<internal-sftp> implements an in-process SFTP
server. This may simplify configurations using
B<ChrootDirectory> to force a different filesystem root
on clients.By default no
subsystems are defined.',
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
        'description' => 'B<SyslogFacility>Gives the facility code that is
used when logging messages from L<sshd(8)>. The possible values
are: DAEMON, USER, AUTH, LOCAL0, LOCAL1, LOCAL2, LOCAL3,
LOCAL4, LOCAL5, LOCAL6, LOCAL7. The default is AUTH.',
        'type' => 'leaf',
        'upstream_default' => 'AUTH',
        'value_type' => 'enum'
      },
      'TCPKeepAlive',
      {
        'description' => 'B<TCPKeepAlive>Specifies whether the system
should send TCP keepalive messages to the other side. If
they are sent, death of the connection or crash of one of
the machines will be properly noticed. However, this means
that connections will die if the route is down temporarily,
and some people find it annoying. On the other hand, if TCP
keepalives are not sent, sessions may hang indefinitely on
the server, leaving "ghost" users and consuming
server resources.The default is
B<yes> (to send TCP keepalive messages), and the server
will notice if the network goes down or the client host
crashes. This avoids infinitely hanging sessions.To disable TCP
keepalive messages, the value should be set to
B<no>.This option was
formerly called B<KeepAlive>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'UseDNS',
      {
        'description' => 'B<UseDNS>Specifies
whether L<sshd(8)> should look up the remote host name, and to
check that the resolved host name for the remote IP address
maps back to the very same IP address.If this option
is set to B<no> (the default) then only addresses and
not host names may be used in I<~/.ssh/authorized_keys>B<from> and B<sshd_config Match Host>
directives.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'UsePAM',
      {
        'description' => 'B<UsePAM>Enables the
Pluggable Authentication Module interface. If set to
B<yes> this will enable PAM authentication using
B<ChallengeResponseAuthentication> and
B<PasswordAuthentication> in addition to PAM account and
session module processing for all authentication types.Because PAM
challenge-response authentication usually serves an
equivalent role to password authentication, you should
disable either B<PasswordAuthentication> or
B<ChallengeResponseAuthentication.>If
B<UsePAM> is enabled, you will not be able to run
L<sshd(8)> as a non-root user. The default is B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'VersionAddendum',
      {
        'description' => 'B<VersionAddendum>Optionally specifies additional
text to append to the SSH protocol banner sent by the server
upon connection. The default is B<none>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'X11UseLocalhost',
      {
        'description' => 'B<X11UseLocalhost>Specifies whether L<sshd(8)>
should bind the X11 forwarding server to the loopback
address or to the wildcard address. By default, sshd binds
the forwarding server to the loopback address and sets the
hostname part of the DISPLAY environment variable to
B<localhost>. This prevents remote hosts from connecting
to the proxy display. However, some older X11 clients may
not function with this configuration. B<X11UseLocalhost>
may be set to B<no> to specify that the forwarding
server should be bound to the wildcard address. The argument
must be B<yes> or B<no>. The default is
B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'XAuthLocation',
      {
        'description' => 'B<XAuthLocation>Specifies the full pathname of
the L<xauth(1)> program, or B<none> to not use one. The
default is I</usr/bin/xauth>.',
        'type' => 'leaf',
        'upstream_default' => '/usr/bin/xauth',
        'value_type' => 'uniline'
      }
    ],
    'generated_by' => 'parse-man.pl from sshd_system  7.9p1 doc',
    'include' => [
      'Sshd::MatchElement'
    ],
    'license' => 'LGPL2',
    'name' => 'Sshd',
    'rw_config' => {
      'backend' => 'OpenSsh::Sshd',
      'config_dir' => '/etc/ssh',
      'file' => 'sshd_config',
      'os_config_dir' => {
        'darwin' => '/etc'
      }
    }
  }
]
;


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
      'AcceptEnv',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "B<AcceptEnv>Specifies what environment
variables sent by the client will be copied into the
session\x{2019}s L<environ(7)>. See B<SendEnv> and
B<SetEnv> in L<ssh_config(5)> for how to configure the
client. The TERM environment variable is always accepted
whenever the client requests a pseudo-terminal as it is
required by the protocol. Variables are specified by name,
which may contain the wildcard characters \x{2019}*\x{2019}
and \x{2019}?\x{2019}. Multiple environment variables may be
separated by whitespace or spread across multiple
B<AcceptEnv> directives. Be warned that some environment
variables could be used to bypass restricted user
environments. For this reason, care should be taken in the
use of this directive. The default is not to accept any
environment variables.",
        'type' => 'list'
      },
      'AllowAgentForwarding',
      {
        'description' => 'B<AllowAgentForwarding>Specifies whether L<ssh-agent(1)>
forwarding is permitted. The default is B<yes>. Note
that disabling agent forwarding does not improve security
unless users are also denied shell access, as they can
always install their own forwarders.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
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
        'description' => 'B<AllowGroups>This keyword can be followed by
a list of group name patterns, separated by spaces. If
specified, login is allowed only for users whose primary
group or supplementary group list matches one of the
patterns. Only group names are valid; a numerical group ID
is not recognized. By default, login is allowed for all
groups. The allow/deny directives are processed in the
following order: B<DenyUsers>, B<AllowUsers>,
B<DenyGroups>, and finally B<AllowGroups>.See PATTERNS in
L<ssh_config(5)> for more information on patterns.',
        'type' => 'list'
      },
      'AllowStreamLocalForwarding',
      {
        'choice' => [
          'yes',
          'all',
          'no',
          'local',
          'remote'
        ],
        'description' => 'B<AllowStreamLocalForwarding>Specifies whether StreamLocal
(Unix-domain socket) forwarding is permitted. The available
options are B<yes> (the default) or B<all> to allow
StreamLocal forwarding, B<no> to prevent all StreamLocal
forwarding, B<local> to allow local (from the
perspective of L<ssh(1)>) forwarding only or B<remote> to
allow remote forwarding only. Note that disabling
StreamLocal forwarding does not improve security unless
users are also denied shell access, as they can always
install their own forwarders.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'AllowTcpForwarding',
      {
        'choice' => [
          'yes',
          'all',
          'no',
          'local',
          'remote'
        ],
        'description' => 'B<AllowTcpForwarding>Specifies whether TCP
forwarding is permitted. The available options are
B<yes> (the default) or B<all> to allow TCP
forwarding, B<no> to prevent all TCP forwarding,
B<local> to allow local (from the perspective of L<ssh(1)>)
forwarding only or B<remote> to allow remote forwarding
only. Note that disabling TCP forwarding does not improve
security unless users are also denied shell access, as they
can always install their own forwarders.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'enum'
      },
      'AllowUsers',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'B<AllowUsers>This keyword can be followed by
a list of user name patterns, separated by spaces. If
specified, login is allowed only for user names that match
one of the patterns. Only user names are valid; a numerical
user ID is not recognized. By default, login is allowed for
all users. If the pattern takes the form USER@HOST then USER
and HOST are separately checked, restricting logins to
particular users from particular hosts. HOST criteria may
additionally contain addresses to match in CIDR
address/masklen format. The allow/deny directives are
processed in the following order: B<DenyUsers>,
B<AllowUsers>, B<DenyGroups>, and finally
B<AllowGroups>.See PATTERNS in
L<ssh_config(5)> for more information on patterns.',
        'type' => 'list'
      },
      'AuthenticationMethods',
      {
        'description' => 'B<AuthenticationMethods>Specifies the authentication
methods that must be successfully completed for a user to be
granted access. This option must be followed by one or more
lists of comma-separated authentication method names, or by
the single string B<any> to indicate the default
behaviour of accepting any single authentication method. If
the default is overridden, then successful authentication
requires completion of every method in at least one of these
lists.For example,
"publickey,password
publickey,keyboard-interactive" would require the user
to complete public key authentication, followed by either
password or keyboard interactive authentication. Only
methods that are next in one or more lists are offered at
each stage, so for this example it would not be possible to
attempt password or keyboard-interactive authentication
before public key.For keyboard
interactive authentication it is also possible to restrict
authentication to a specific device by appending a colon
followed by the device identifier B<bsdauth> or
B<pam>. depending on the server configuration. For
example, "keyboard-interactive:bsdauth" would
restrict keyboard interactive authentication to the
B<bsdauth> device.If the
publickey method is listed more than once, L<sshd(8)> verifies
that keys that have been used successfully are not reused
for subsequent authentications. For example,
"publickey,publickey" requires successful
authentication using two different public keys.Note that each
authentication method listed should also be explicitly
enabled in the configuration.The available
authentication methods are: "gssapi-with-mic",
"hostbased", "keyboard-interactive",
"none" (used for access to password-less accounts
when B<PermitEmptyPasswords> is enabled),
"password" and "publickey".',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AuthorizedKeysCommand',
      {
        'description' => "B<AuthorizedKeysCommand>Specifies a program to be used
to look up the user\x{2019}s public keys. The program must be
owned by root, not writable by group or others and specified
by an absolute path. Arguments to
B<AuthorizedKeysCommand> accept the tokens described in
the I<TOKENS> section. If no arguments are specified
then the username of the target user is used.The program
should produce on standard output zero or more lines of
authorized_keys output (see I<AUTHORIZED_KEYS> in
L<sshd(8)>). If a key supplied by B<AuthorizedKeysCommand>
does not successfully authenticate and authorize the user
then public key authentication continues using the usual
B<AuthorizedKeysFile> files. By default, no
B<AuthorizedKeysCommand> is run.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AuthorizedKeysCommandUser',
      {
        'description' => 'B<AuthorizedKeysCommandUser>Specifies the user under whose
account the B<AuthorizedKeysCommand> is run. It is
recommended to use a dedicated user that has no other role
on the host than running authorized keys commands. If
B<AuthorizedKeysCommand> is specified but
B<AuthorizedKeysCommandUser> is not, then L<sshd(8)> will
refuse to start.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AuthorizedKeysFile',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "B<AuthorizedKeysFile>Specifies the file that
contains the public keys used for user authentication. The
format is described in the I<AUTHORIZED_KEYS FILE
FORMAT> section of L<sshd(8)>. Arguments to
B<AuthorizedKeysFile> accept the tokens described in the
I<TOKENS> section. After expansion,
B<AuthorizedKeysFile> is taken to be an absolute path or
one relative to the user\x{2019}s home directory. Multiple
files may be listed, separated by whitespace. Alternately
this option may be set to B<none> to skip checking for
user keys in files. The default is
\".ssh/authorized_keys .ssh/authorized_keys2\".",
        'migrate_values_from' => '- AuthorizedKeysFile2',
        'type' => 'list'
      },
      'AuthorizedPrincipalsCommand',
      {
        'description' => 'B<AuthorizedPrincipalsCommand>Specifies a program to be used
to generate the list of allowed certificate principals as
per B<AuthorizedPrincipalsFile>. The program must be
owned by root, not writable by group or others and specified
by an absolute path. Arguments to
B<AuthorizedPrincipalsCommand> accept the tokens
described in the I<TOKENS> section. If no arguments are
specified then the username of the target user is used.The program
should produce on standard output zero or more lines of
B<AuthorizedPrincipalsFile> output. If either
B<AuthorizedPrincipalsCommand> or
B<AuthorizedPrincipalsFile> is specified, then
certificates offered by the client for authentication must
contain a principal that is listed. By default, no
B<AuthorizedPrincipalsCommand> is run.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AuthorizedPrincipalsCommandUser',
      {
        'description' => 'B<AuthorizedPrincipalsCommandUser>Specifies the user under whose
account the B<AuthorizedPrincipalsCommand> is run. It is
recommended to use a dedicated user that has no other role
on the host than running authorized principals commands. If
B<AuthorizedPrincipalsCommand> is specified but
B<AuthorizedPrincipalsCommandUser> is not, then L<sshd(8)>
will refuse to start.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'AuthorizedPrincipalsFile',
      {
        'description' => "B<AuthorizedPrincipalsFile>Specifies a file that lists
principal names that are accepted for certificate
authentication. When using certificates signed by a key
listed in B<TrustedUserCAKeys>, this file lists names,
one of which must appear in the certificate for it to be
accepted for authentication. Names are listed one per line
preceded by key options (as described in I<AUTHORIZED_KEYS
FILE FORMAT> in L<sshd(8)>). Empty lines and comments
starting with \x{2019}#\x{2019} are ignored.Arguments to
B<AuthorizedPrincipalsFile> accept the tokens described
in the I<TOKENS> section. After expansion,
B<AuthorizedPrincipalsFile> is taken to be an absolute
path or one relative to the user\x{2019}s home directory. The
default is B<none>, i.e. not to use a principals file
\x{2013} in this case, the username of the user must appear
in a certificate\x{2019}s principals list for it to be
accepted.Note that
B<AuthorizedPrincipalsFile> is only used when
authentication proceeds using a CA listed in
B<TrustedUserCAKeys> and is not consulted for
certification authorities trusted via
I<~/.ssh/authorized_keys>, though the B<principals=>
key option offers a similar facility (see L<sshd(8)> for
details).",
        'type' => 'leaf',
        'upstream_default' => 'none',
        'value_type' => 'uniline'
      },
      'Banner',
      {
        'description' => 'B<Banner>The contents of
the specified file are sent to the remote user before
authentication is allowed. If the argument is B<none>
then no banner is displayed. By default, no banner is
displayed.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ChrootDirectory',
      {
        'description' => "B<ChrootDirectory>Specifies the pathname of a
directory to L<chroot(2)> to after authentication. At session
startup L<sshd(8)> checks that all components of the pathname
are root-owned directories which are not writable by any
other user or group. After the chroot, L<sshd(8)> changes the
working directory to the user\x{2019}s home directory.
Arguments to B<ChrootDirectory> accept the tokens
described in the I<TOKENS> section.The
B<ChrootDirectory> must contain the necessary files and
directories to support the user\x{2019}s session. For an
interactive session this requires at least a shell,
typically L<sh(1)>, and basic I</dev> nodes such as
L<null(4)>, L<zero(4)>, L<stdin(4)>, L<stdout(4)>, L<stderr(4)>, and L<tty(4)>
devices. For file transfer sessions using SFTP no additional
configuration of the environment is necessary if the
in-process sftp-server is used, though sessions which use
logging may require I</dev/log> inside the chroot
directory on some operating systems (see L<sftp-server(8)> for
details).For safety, it
is very important that the directory hierarchy be prevented
from modification by other processes on the system
(especially those outside the jail). Misconfiguration can
lead to unsafe environments which L<sshd(8)> cannot detect.The default is
B<none>, indicating not to L<chroot(2)>.",
        'type' => 'leaf',
        'upstream_default' => 'none',
        'value_type' => 'uniline'
      },
      'ClientAliveCountMax',
      {
        'description' => 'B<ClientAliveCountMax>Sets the number of client alive
messages which may be sent without L<sshd(8)> receiving any
messages back from the client. If this threshold is reached
while client alive messages are being sent, sshd will
disconnect the client, terminating the session. It is
important to note that the use of client alive messages is
very different from B<TCPKeepAlive>. The client alive
messages are sent through the encrypted channel and
therefore will not be spoofable. The TCP keepalive option
enabled by B<TCPKeepAlive> is spoofable. The client
alive mechanism is valuable when the client or server depend
on knowing when a connection has become inactive.The default
value is 3. If B<ClientAliveInterval> is set to 15, and
B<ClientAliveCountMax> is left at the default,
unresponsive SSH clients will be disconnected after
approximately 45 seconds.',
        'type' => 'leaf',
        'upstream_default' => '3',
        'value_type' => 'integer'
      },
      'ClientAliveInterval',
      {
        'description' => 'B<ClientAliveInterval>Sets a timeout interval in
seconds after which if no data has been received from the
client, L<sshd(8)> will send a message through the encrypted
channel to request a response from the client. The default
is 0, indicating that these messages will not be sent to the
client.',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      },
      'DenyGroups',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'B<DenyGroups>This keyword can be followed by
a list of group name patterns, separated by spaces. Login is
disallowed for users whose primary group or supplementary
group list matches one of the patterns. Only group names are
valid; a numerical group ID is not recognized. By default,
login is allowed for all groups. The allow/deny directives
are processed in the following order: B<DenyUsers>,
B<AllowUsers>, B<DenyGroups>, and finally
B<AllowGroups>.See PATTERNS in
L<ssh_config(5)> for more information on patterns.',
        'type' => 'list'
      },
      'DenyUsers',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'B<DenyUsers>This keyword can be followed by
a list of user name patterns, separated by spaces. Login is
disallowed for user names that match one of the patterns.
Only user names are valid; a numerical user ID is not
recognized. By default, login is allowed for all users. If
the pattern takes the form USER@HOST then USER and HOST are
separately checked, restricting logins to particular users
from particular hosts. HOST criteria may additionally
contain addresses to match in CIDR address/masklen format.
The allow/deny directives are processed in the following
order: B<DenyUsers>, B<AllowUsers>,
B<DenyGroups>, and finally B<AllowGroups>.See PATTERNS in
L<ssh_config(5)> for more information on patterns.',
        'type' => 'list'
      },
      'ForceCommand',
      {
        'description' => "B<ForceCommand>Forces the execution of the
command specified by B<ForceCommand>, ignoring any
command supplied by the client and I<~/.ssh/rc> if
present. The command is invoked by using the user\x{2019}s
login shell with the -c option. This applies to shell,
command, or subsystem execution. It is most useful inside a
B<Match> block. The command originally supplied by the
client is available in the SSH_ORIGINAL_COMMAND environment
variable. Specifying a command of B<internal-sftp> will
force the use of an in-process SFTP server that requires no
support files when used with B<ChrootDirectory>. The
default is B<none>.",
        'type' => 'leaf',
        'upstream_default' => 'none',
        'value_type' => 'uniline'
      },
      'GatewayPorts',
      {
        'choice' => [
          'no',
          'yes',
          'clientspecified'
        ],
        'description' => 'B<GatewayPorts>Specifies whether remote hosts
are allowed to connect to ports forwarded for the client. By
default, L<sshd(8)> binds remote port forwardings to the
loopback address. This prevents other remote hosts from
connecting to forwarded ports. B<GatewayPorts> can be
used to specify that sshd should allow remote port
forwardings to bind to non-loopback addresses, thus allowing
other hosts to connect. The argument may be B<no> to
force remote port forwardings to be available to the local
host only, B<yes> to force remote port forwardings to
bind to the wildcard address, or B<clientspecified> to
allow the client to select the address to which the
forwarding is bound. The default is B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'GSSAPIAuthentication',
      {
        'description' => 'B<GSSAPIAuthentication>Specifies whether user
authentication based on GSSAPI is allowed. The default is
B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'HostbasedAcceptedKeyTypes',
      {
        'description' => "B<HostbasedAcceptedKeyTypes>Specifies the key types that
will be accepted for hostbased authentication as a list of
comma-separated patterns. Alternately if the specified value
begins with a \x{2019}+\x{2019} character, then the specified
key types will be appended to the default set instead of
replacing them. If the specified value begins with a
\x{2019}-\x{2019} character, then the specified key types
(including wildcards) will be removed from the default set
instead of replacing them. The default for this option
is:ecdsa-sha2-nistp256-cert-v01\@openssh.com,

ecdsa-sha2-nistp384-cert-v01\@openssh.com, 
ecdsa-sha2-nistp521-cert-v01\@openssh.com, 
ssh-ed25519-cert-v01\@openssh.com, 

rsa-sha2-512-cert-v01\@openssh.com,rsa-sha2-256-cert-v01\@openssh.com,

ssh-rsa-cert-v01\@openssh.com, 

ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,

ssh-ed25519,rsa-sha2-512,rsa-sha2-256,ssh-rsaThe list of
available key types may also be obtained using \"ssh -Q
key\".",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'HostbasedAuthentication',
      {
        'description' => 'B<HostbasedAuthentication>Specifies whether rhosts or
/etc/hosts.equiv authentication together with successful
public key client host authentication is allowed (host-based
authentication). The default is B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'HostbasedUsesNameFromPacketOnly',
      {
        'description' => 'B<HostbasedUsesNameFromPacketOnly>Specifies whether or not the
server will attempt to perform a reverse name lookup when
matching the name in the I<~/.shosts>, I<~/.rhosts>,
and I</etc/hosts.equiv> files during
B<HostbasedAuthentication>. A setting of B<yes>
means that L<sshd(8)> uses the name supplied by the client
rather than attempting to resolve the name from the TCP
connection itself. The default is B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
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
            'msg' => 'Unexpected value "$_". Expected 1 or 2 occurences of: "af11", "af12", "af13", "af21", "af22",
"af23", "af31", "af32", "af33", "af41", "af42", "af43", "cs0", "cs1",
"cs2", "cs3", "cs4", "cs5", "cs6", "cs7", "ef", "lowdelay",
"throughput", "reliability", or numeric value.
'
          }
        },
        'description' => 'B<IPQoS>Specifies the
IPv4 type-of-service or DSCP class for the connection.
Accepted values are B<af11>, B<af12>, B<af13>,
B<af21>, B<af22>, B<af23>, B<af31>,
B<af32>, B<af33>, B<af41>, B<af42>,
B<af43>, B<cs0>, B<cs1>, B<cs2>, B<cs3>,
B<cs4>, B<cs5>, B<cs6>, B<cs7>, B<ef>,
B<lowdelay>, B<throughput>, B<reliability>, a
numeric value, or B<none> to use the operating system
default. This option may take one or two arguments,
separated by whitespace. If one argument is specified, it is
used as the packet class unconditionally. If two values are
specified, the first is automatically selected for
interactive sessions and the second for non-interactive
sessions. The default is B<lowdelay> for interactive
sessions and B<throughput> for non-interactive
sessions.',
        'type' => 'leaf',
        'upstream_default' => 'af21 cs1',
        'value_type' => 'uniline'
      },
      'KbdInteractiveAuthentication',
      {
        'description' => 'B<KbdInteractiveAuthentication>Specifies whether to allow
keyboard-interactive authentication. The argument to this
keyword must be B<yes> or B<no>. The default is to
use whatever value B<ChallengeResponseAuthentication> is
set to (by default B<yes>).',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'KerberosAuthentication',
      {
        'description' => "B<KerberosAuthentication>Specifies whether the password
provided by the user for B<PasswordAuthentication> will
be validated through the Kerberos KDC. To use this option,
the server needs a Kerberos servtab which allows the
verification of the KDC\x{2019}s identity. The default is
B<no>.",
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'LogLevel',
      {
        'choice' => [
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
        'description' => 'B<LogLevel>Gives the verbosity level that
is used when logging messages from L<sshd(8)>. The possible
values are: QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG,
DEBUG1, DEBUG2, and DEBUG3. The default is INFO. DEBUG and
DEBUG1 are equivalent. DEBUG2 and DEBUG3 each specify higher
levels of debugging output. Logging with a DEBUG level
violates the privacy of users and is not recommended.',
        'type' => 'leaf',
        'upstream_default' => 'INFO',
        'value_type' => 'enum'
      },
      'MaxAuthTries',
      {
        'description' => 'B<MaxAuthTries>Specifies the maximum number of
authentication attempts permitted per connection. Once the
number of failures reaches half this value, additional
failures are logged. The default is 6.',
        'type' => 'leaf',
        'upstream_default' => '6',
        'value_type' => 'integer'
      },
      'MaxSessions',
      {
        'description' => 'B<MaxSessions>Specifies the maximum number of
open shell, login or subsystem (e.g. sftp) sessions
permitted per network connection. Multiple sessions may be
established by clients that support connection multiplexing.
Setting B<MaxSessions> to 1 will effectively disable
session multiplexing, whereas setting it to 0 will prevent
all shell, login and subsystem sessions while still
permitting forwarding. The default is 10.',
        'type' => 'leaf',
        'upstream_default' => '10',
        'value_type' => 'integer'
      },
      'PasswordAuthentication',
      {
        'description' => 'B<PasswordAuthentication>Specifies whether password
authentication is allowed. The default is B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PermitEmptyPasswords',
      {
        'description' => 'B<PermitEmptyPasswords>When password authentication is
allowed, it specifies whether the server allows login to
accounts with empty password strings. The default is
B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PermitListen',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "B<PermitListen>Specifies the addresses/ports
on which a remote TCP port forwarding may listen. The listen
specification must be one of the following forms:B<PermitListen>I<port> B<
PermitListen> I<host>:I<port>Multiple
permissions may be specified by separating them with
whitespace. An argument of B<any> can be used to remove
all restrictions and permit any listen requests. An argument
of B<none> can be used to prohibit all listen requests.
The host name may contain wildcards as described in the
PATTERNS section in L<ssh_config(5)>. The wildcard
\x{2019}*\x{2019} can also be used in place of a port number
to allow all ports. By default all port forwarding listen
requests are permitted. Note that the B<GatewayPorts>
option may further restrict which addresses may be listened
on. Note also that L<ssh(1)> will request a listen host of
\x{201c}localhost\x{201d} if no listen host was specifically
requested, and this this name is treated differently to
explicit localhost addresses of \x{201c}127.0.0.1\x{201d} and
\x{201c}::1\x{201d}.",
        'type' => 'list'
      },
      'PermitOpen',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => "B<PermitOpen>Specifies the destinations to
which TCP port forwarding is permitted. The forwarding
specification must be one of the following forms:B<PermitOpen>I<host>:I<port> B<
PermitOpen> I<IPv4_addr>:I<port> B<
PermitOpen> I<[IPv6_addr]>:I<port>Multiple
forwards may be specified by separating them with
whitespace. An argument of B<any> can be used to remove
all restrictions and permit any forwarding requests. An
argument of B<none> can be used to prohibit all
forwarding requests. The wildcard \x{2019}*\x{2019} can be
used for host or port to allow all hosts or ports,
respectively. By default all port forwarding requests are
permitted.",
        'type' => 'list'
      },
      'PermitRootLogin',
      {
        'choice' => [
          'yes',
          'prohibit-password',
          'forced-commands-only',
          'no'
        ],
        'description' => 'B<PermitRootLogin>Specifies whether root can log
in using L<ssh(1)>. The argument must be B<yes>,
B<prohibit-password>, B<forced-commands-only>, or
B<no>. The default is B<prohibit-password>.If this option
is set to B<prohibit-password> (or its deprecated alias,
B<without-password>), password and keyboard-interactive
authentication are disabled for root.If this option
is set to B<forced-commands-only>, root login with
public key authentication will be allowed, but only if the
I<command> option has been specified (which may be
useful for taking remote backups even if root login is
normally not allowed). All other authentication methods are
disabled for root.If this option
is set to B<no>, root is not allowed to log in.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'PermitTTY',
      {
        'description' => 'B<PermitTTY>Specifies whether L<pty(4)>
allocation is permitted. The default is B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PermitTunnel',
      {
        'choice' => [
          'yes',
          'point-to-point',
          'ethernet',
          'no'
        ],
        'description' => 'B<PermitTunnel>Specifies whether L<tun(4)> device
forwarding is allowed. The argument must be B<yes>,
B<point-to-point> (layer 3), B<ethernet> (layer 2),
or B<no>. Specifying B<yes> permits both
B<point-to-point> and B<ethernet>. The default is
B<no>.Independent of
this setting, the permissions of the selected L<tun(4)> device
must allow access to the user.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'PermitUserRC',
      {
        'description' => 'B<PermitUserRC>Specifies whether any
I<~/.ssh/rc> file is executed. The default is
B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PubkeyAcceptedKeyTypes',
      {
        'description' => "B<PubkeyAcceptedKeyTypes>Specifies the key types that
will be accepted for public key authentication as a list of
comma-separated patterns. Alternately if the specified value
begins with a \x{2019}+\x{2019} character, then the specified
key types will be appended to the default set instead of
replacing them. If the specified value begins with a
\x{2019}-\x{2019} character, then the specified key types
(including wildcards) will be removed from the default set
instead of replacing them. The default for this option
is:ecdsa-sha2-nistp256-cert-v01\@openssh.com,

ecdsa-sha2-nistp384-cert-v01\@openssh.com, 
ecdsa-sha2-nistp521-cert-v01\@openssh.com, 
ssh-ed25519-cert-v01\@openssh.com, 

rsa-sha2-512-cert-v01\@openssh.com,rsa-sha2-256-cert-v01\@openssh.com,

ssh-rsa-cert-v01\@openssh.com, 

ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,

ssh-ed25519,rsa-sha2-512,rsa-sha2-256,ssh-rsaThe list of
available key types may also be obtained using \"ssh -Q
key\".",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PubkeyAuthentication',
      {
        'description' => 'B<PubkeyAuthentication>Specifies whether public key
authentication is allowed. The default is B<yes>.',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'RekeyLimit',
      {
        'description' => "B<RekeyLimit>Specifies the maximum amount of
data that may be transmitted before the session key is
renegotiated, optionally followed a maximum amount of time
that may pass before the session key is renegotiated. The
first argument is specified in bytes and may have a suffix
of \x{2019}K\x{2019}, \x{2019}M\x{2019}, or \x{2019}G\x{2019} to
indicate Kilobytes, Megabytes, or Gigabytes, respectively.
The default is between \x{2019}1G\x{2019} and
\x{2019}4G\x{2019}, depending on the cipher. The optional
second value is specified in seconds and may use any of the
units documented in the I<TIME FORMATS> section. The
default value for B<RekeyLimit> is B<default none>,
which means that rekeying is performed after the
cipher\x{2019}s default amount of data has been sent or
received and no time based rekeying is done.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RevokedKeys',
      {
        'description' => 'B<RevokedKeys>Specifies revoked public keys
file, or B<none> to not use one. Keys listed in this
file will be refused for public key authentication. Note
that if this file is not readable, then public key
authentication will be refused for all users. Keys may be
specified as a text file, listing one public key per line,
or as an OpenSSH Key Revocation List (KRL) as generated by
L<ssh-keygen(1)>. For more information on KRLs, see the KEY
REVOCATION LISTS section in L<ssh-keygen(1)>.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RDomain',
      {
        'description' => 'B<RDomain>Specifies an explicit routing
domain that is applied after authentication has completed.
The user session, as well and any forwarded or listening IP
sockets, will be bound to this L<rdomain(4)>. If the routing
domain is set to B<%D>, then the domain in which the
incoming connection was received will be applied.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SetEnv',
      {
        'description' => "B<SetEnv>Specifies one
or more environment variables to set in child sessions
started by L<sshd(8)> as \x{201c}NAME=VALUE\x{201d}. The
environment value may be quoted (e.g. if it contains
whitespace characters). Environment variables set by
B<SetEnv> override the default environment and any
variables specified by the user via B<AcceptEnv> or
B<PermitUserEnvironment>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StreamLocalBindMask',
      {
        'description' => 'B<StreamLocalBindMask>Sets the octal file creation
mode mask (umask) used when creating a Unix-domain socket
file for local or remote port forwarding. This option is
only used for port forwarding to a Unix-domain socket
file.The default
value is 0177, which creates a Unix-domain socket file that
is readable and writable only by the owner. Note that not
all operating systems honor the file mode on Unix-domain
socket files.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'StreamLocalBindUnlink',
      {
        'description' => 'B<StreamLocalBindUnlink>Specifies whether to remove an
existing Unix-domain socket file for local or remote port
forwarding before creating a new one. If the socket file
already exists and B<StreamLocalBindUnlink> is not
enabled, B<sshd> will be unable to forward the port to
the Unix-domain socket file. This option is only used for
port forwarding to a Unix-domain socket file.The argument
must be B<yes> or B<no>. The default is
B<no>.',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'TrustedUserCAKeys',
      {
        'description' => "B<TrustedUserCAKeys>Specifies a file containing
public keys of certificate authorities that are trusted to
sign user certificates for authentication, or B<none> to
not use one. Keys are listed one per line; empty lines and
comments starting with \x{2019}#\x{2019} are allowed. If a
certificate is presented for authentication and has its
signing CA key listed in this file, then it may be used for
authentication for any user listed in the
certificate\x{2019}s principals list. Note that certificates
that lack a list of principals will not be permitted for
authentication using B<TrustedUserCAKeys>. For more
details on certificates, see the CERTIFICATES section in
L<ssh-keygen(1)>.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'X11DisplayOffset',
      {
        'description' => "B<X11DisplayOffset>Specifies the first display
number available for L<sshd(8)>\x{2019}s X11 forwarding. This
prevents sshd from interfering with real X11 servers. The
default is 10.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'X11Forwarding',
      {
        'description' => "B<X11Forwarding>Specifies whether X11
forwarding is permitted. The argument must be B<yes> or
B<no>. The default is B<no>.When X11
forwarding is enabled, there may be additional exposure to
the server and to client displays if the L<sshd(8)> proxy
display is configured to listen on the wildcard address (see
B<X11UseLocalhost>), though this is not the default.
Additionally, the authentication spoofing and authentication
data verification and substitution occur on the client side.
The security risk of using X11 forwarding is that the
client\x{2019}s X11 display server may be exposed to attack
when the SSH client requests forwarding (see the warnings
for B<ForwardX11> in L<ssh_config(5)>). A system
administrator may have a stance in which they want to
protect clients that may expose themselves to attack by
unwittingly requesting X11 forwarding, which can warrant a
B<no> setting.Note that
disabling X11 forwarding does not prevent users from
forwarding X11 traffic, as users can always install their
own forwarders.",
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'AuthorizedKeysFile2',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'This parameter is now ignored by Ssh',
        'status' => 'deprecated',
        'type' => 'list'
      },
      'Protocol',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RSAAuthentication',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RhostsRSAAuthentication',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UsePrivilegeSeparation',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeyRegenerationInterval',
      {
        'status' => 'deprecated',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'generated_by' => 'parse-man.pl from sshd_system  7.9p1 doc',
    'license' => 'LGPL2',
    'name' => 'Sshd::MatchElement'
  }
]
;


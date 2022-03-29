#
# This file is part of Config-Model-Systemd
#
# This software is Copyright (c) 2008-2022 by Dominique Dumont.
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
    'class_description' => 'A unit configuration file whose name ends in
C<.socket> encodes information about an IPC or
network socket or a file system FIFO controlled and supervised by
systemd, for socket-based activation.

This man page lists the configuration options specific to
this unit type. See
L<systemd.unit(5)>
for the common options of all unit configuration files. The common
configuration items are configured in the generic [Unit] and
[Install] sections. The socket specific configuration options are
configured in the [Socket] section.

Additional options are listed in
L<systemd.exec(5)>,
which define the execution environment the
C<ExecStartPre>, C<ExecStartPost>,
C<ExecStopPre> and C<ExecStopPost>
commands are executed in, and in
L<systemd.kill(5)>,
which define the way the processes are terminated, and in
L<systemd.resource-control(5)>,
which configure resource control settings for the processes of the
socket.

For each socket unit, a matching service unit must exist,
describing the service to start on incoming traffic on the socket
(see
L<systemd.service(5)>
for more information about .service units). The name of the
.service unit is by default the same as the name of the .socket
unit, but can be altered with the C<Service> option
described below. Depending on the setting of the
C<Accept> option described below, this .service
unit must either be named like the .socket unit, but with the
suffix replaced, unless overridden with C<Service>;
or it must be a template unit named the same way. Example: a
socket file C<foo.socket> needs a matching
service C<foo.service> if
C<Accept=no> is set. If
C<Accept=yes> is set, a service template
C<foo@.service> must exist from which services
are instantiated for each incoming connection.

No implicit C<WantedBy> or
C<RequiredBy> dependency from the socket to the
service is added. This means that the service may be started
without the socket, in which case it must be able to open sockets
by itself. To prevent this, an explicit
C<Requires> dependency may be added.

Socket units may be used to implement on-demand starting of
services, as well as parallelized starting of services. See the
blog stories linked at the end for an introduction.

Note that the daemon software configured for socket activation with socket units needs to be able
to accept sockets from systemd, either via systemd\'s native socket passing interface (see
L<sd_listen_fds(3)> for
details about the precise protocol used and the order in which the file descriptors are passed) or via
traditional L<inetd(8)>-style
socket passing (i.e. sockets passed in via standard input and output, using
C<StandardInput=socket> in the service file).

All network sockets allocated through C<.socket> units are allocated in the host\'s network
namespace (see L<network_namespaces(7)>). This
does not mean however that the service activated by a configured socket unit has to be part of the host\'s network
namespace as well.  It is supported and even good practice to run services in their own network namespace (for
example through C<PrivateNetwork>, see
L<systemd.exec(5)>), receiving only
the sockets configured through socket-activation from the host\'s namespace. In such a set-up communication within
the host\'s network namespace is only permitted through the activation sockets passed in while all sockets allocated
from the service code itself will be associated with the service\'s own namespace, and thus possibly subject to a
restrictive configuration.
This configuration class was generated from systemd documentation.
by L<parse-man.pl|https://github.com/dod38fr/config-model-systemd/contrib/parse-man.pl>
',
    'copyright' => [
      '2010-2016 Lennart Poettering and others',
      '2016 Dominique Dumont'
    ],
    'element' => [
      'ListenStream',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies an address to listen on for a stream
(C<SOCK_STREAM>), datagram
(C<SOCK_DGRAM>), or sequential packet
(C<SOCK_SEQPACKET>) socket, respectively.
The address can be written in various formats:

If the address starts with a slash
(C</>), it is read as file system socket in
the C<AF_UNIX> socket family.

If the address starts with an at symbol
(C<@>), it is read as abstract namespace
socket in the C<AF_UNIX> family. The
C<@> is replaced with a
C<NUL> character before binding. For
details, see
L<unix(7)>.

If the address string is a single number, it is read as
port number to listen on via IPv6. Depending on the value of
C<BindIPv6Only> (see below) this might result
in the service being available via both IPv6 and IPv4
(default) or just via IPv6.

If the address string is a string in the format
C<v.w.x.y:z>, it is interpreted
as IPv4 address v.w.x.y and port z.

If the address string is a string in the format
C<[x]:y>, it is interpreted as
IPv6 address x and port y. An optional
interface scope (interface name or number) may be specified after a C<%> symbol:
C<[x]:y%dev>.
Interface scopes are only useful with link-local addresses, because the kernel ignores them in other
cases. Note that if an address is specified as IPv6, it might still make the service available via
IPv4 too, depending on the C<BindIPv6Only> setting (see below).

If the address string is a string in the format
C<vsock:x:y>, it is read as CID
x on a port y address in the
C<AF_VSOCK> family.  The CID is a unique 32-bit integer identifier in
C<AF_VSOCK> analogous to an IP address.  Specifying the CID is optional, and may be
set to the empty string.

Note that C<SOCK_SEQPACKET> (i.e.
C<ListenSequentialPacket>) is only available
for C<AF_UNIX> sockets.
C<SOCK_STREAM> (i.e.
C<ListenStream>) when used for IP sockets
refers to TCP sockets, C<SOCK_DGRAM> (i.e.
C<ListenDatagram>) to UDP.

These options may be specified more than once, in which
case incoming traffic on any of the sockets will trigger
service activation, and all listed sockets will be passed to
the service, regardless of whether there is incoming traffic
on them or not. If the empty string is assigned to any of
these options, the list of addresses to listen on is reset,
all prior uses of any of these options will have no
effect.

It is also possible to have more than one socket unit
for the same service when using C<Service>,
and the service will receive all the sockets configured in all
the socket units. Sockets configured in one unit are passed in
the order of configuration, but no ordering between socket
units is specified.

If an IP address is used here, it is often desirable to
listen on it before the interface it is configured on is up
and running, and even regardless of whether it will be up and
running at any point. To deal with this, it is recommended to
set the C<FreeBind> option described
below.',
        'type' => 'list'
      },
      'ListenDatagram',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies an address to listen on for a stream
(C<SOCK_STREAM>), datagram
(C<SOCK_DGRAM>), or sequential packet
(C<SOCK_SEQPACKET>) socket, respectively.
The address can be written in various formats:

If the address starts with a slash
(C</>), it is read as file system socket in
the C<AF_UNIX> socket family.

If the address starts with an at symbol
(C<@>), it is read as abstract namespace
socket in the C<AF_UNIX> family. The
C<@> is replaced with a
C<NUL> character before binding. For
details, see
L<unix(7)>.

If the address string is a single number, it is read as
port number to listen on via IPv6. Depending on the value of
C<BindIPv6Only> (see below) this might result
in the service being available via both IPv6 and IPv4
(default) or just via IPv6.

If the address string is a string in the format
C<v.w.x.y:z>, it is interpreted
as IPv4 address v.w.x.y and port z.

If the address string is a string in the format
C<[x]:y>, it is interpreted as
IPv6 address x and port y. An optional
interface scope (interface name or number) may be specified after a C<%> symbol:
C<[x]:y%dev>.
Interface scopes are only useful with link-local addresses, because the kernel ignores them in other
cases. Note that if an address is specified as IPv6, it might still make the service available via
IPv4 too, depending on the C<BindIPv6Only> setting (see below).

If the address string is a string in the format
C<vsock:x:y>, it is read as CID
x on a port y address in the
C<AF_VSOCK> family.  The CID is a unique 32-bit integer identifier in
C<AF_VSOCK> analogous to an IP address.  Specifying the CID is optional, and may be
set to the empty string.

Note that C<SOCK_SEQPACKET> (i.e.
C<ListenSequentialPacket>) is only available
for C<AF_UNIX> sockets.
C<SOCK_STREAM> (i.e.
C<ListenStream>) when used for IP sockets
refers to TCP sockets, C<SOCK_DGRAM> (i.e.
C<ListenDatagram>) to UDP.

These options may be specified more than once, in which
case incoming traffic on any of the sockets will trigger
service activation, and all listed sockets will be passed to
the service, regardless of whether there is incoming traffic
on them or not. If the empty string is assigned to any of
these options, the list of addresses to listen on is reset,
all prior uses of any of these options will have no
effect.

It is also possible to have more than one socket unit
for the same service when using C<Service>,
and the service will receive all the sockets configured in all
the socket units. Sockets configured in one unit are passed in
the order of configuration, but no ordering between socket
units is specified.

If an IP address is used here, it is often desirable to
listen on it before the interface it is configured on is up
and running, and even regardless of whether it will be up and
running at any point. To deal with this, it is recommended to
set the C<FreeBind> option described
below.',
        'type' => 'list'
      },
      'ListenSequentialPacket',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies an address to listen on for a stream
(C<SOCK_STREAM>), datagram
(C<SOCK_DGRAM>), or sequential packet
(C<SOCK_SEQPACKET>) socket, respectively.
The address can be written in various formats:

If the address starts with a slash
(C</>), it is read as file system socket in
the C<AF_UNIX> socket family.

If the address starts with an at symbol
(C<@>), it is read as abstract namespace
socket in the C<AF_UNIX> family. The
C<@> is replaced with a
C<NUL> character before binding. For
details, see
L<unix(7)>.

If the address string is a single number, it is read as
port number to listen on via IPv6. Depending on the value of
C<BindIPv6Only> (see below) this might result
in the service being available via both IPv6 and IPv4
(default) or just via IPv6.

If the address string is a string in the format
C<v.w.x.y:z>, it is interpreted
as IPv4 address v.w.x.y and port z.

If the address string is a string in the format
C<[x]:y>, it is interpreted as
IPv6 address x and port y. An optional
interface scope (interface name or number) may be specified after a C<%> symbol:
C<[x]:y%dev>.
Interface scopes are only useful with link-local addresses, because the kernel ignores them in other
cases. Note that if an address is specified as IPv6, it might still make the service available via
IPv4 too, depending on the C<BindIPv6Only> setting (see below).

If the address string is a string in the format
C<vsock:x:y>, it is read as CID
x on a port y address in the
C<AF_VSOCK> family.  The CID is a unique 32-bit integer identifier in
C<AF_VSOCK> analogous to an IP address.  Specifying the CID is optional, and may be
set to the empty string.

Note that C<SOCK_SEQPACKET> (i.e.
C<ListenSequentialPacket>) is only available
for C<AF_UNIX> sockets.
C<SOCK_STREAM> (i.e.
C<ListenStream>) when used for IP sockets
refers to TCP sockets, C<SOCK_DGRAM> (i.e.
C<ListenDatagram>) to UDP.

These options may be specified more than once, in which
case incoming traffic on any of the sockets will trigger
service activation, and all listed sockets will be passed to
the service, regardless of whether there is incoming traffic
on them or not. If the empty string is assigned to any of
these options, the list of addresses to listen on is reset,
all prior uses of any of these options will have no
effect.

It is also possible to have more than one socket unit
for the same service when using C<Service>,
and the service will receive all the sockets configured in all
the socket units. Sockets configured in one unit are passed in
the order of configuration, but no ordering between socket
units is specified.

If an IP address is used here, it is often desirable to
listen on it before the interface it is configured on is up
and running, and even regardless of whether it will be up and
running at any point. To deal with this, it is recommended to
set the C<FreeBind> option described
below.',
        'type' => 'list'
      },
      'ListenFIFO',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies a file system FIFO (see L<fifo(7)> for
details) to listen on.  This expects an absolute file system path as argument.  Behavior otherwise is
very similar to the C<ListenDatagram> directive above.',
        'type' => 'list'
      },
      'ListenSpecial',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies a special file in the file system to
listen on. This expects an absolute file system path as
argument. Behavior otherwise is very similar to the
C<ListenFIFO> directive above. Use this to
open character device nodes as well as special files in
C</proc/> and
C</sys/>.',
        'type' => 'list'
      },
      'ListenNetlink',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies a Netlink family to create a socket
for to listen on. This expects a short string referring to the
C<AF_NETLINK> family name (such as
C<audit> or C<kobject-uevent>)
as argument, optionally suffixed by a whitespace followed by a
multicast group integer. Behavior otherwise is very similar to
the C<ListenDatagram> directive
above.',
        'type' => 'list'
      },
      'ListenMessageQueue',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies a POSIX message queue name to listen on (see L<mq_overview(7)>
for details). This expects a valid message queue name (i.e. beginning with
C</>). Behavior otherwise is very similar to the C<ListenFIFO>
directive above. On Linux message queue descriptors are actually file descriptors and can be
inherited between processes.',
        'type' => 'list'
      },
      'ListenUSBFunction',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specifies a L<USB
FunctionFS|https://www.kernel.org/doc/Documentation/usb/functionfs.txt> endpoints location to listen on, for
implementation of USB gadget functions. This expects an
absolute file system path of a FunctionFS mount point as the argument.
Behavior otherwise is very similar to the C<ListenFIFO>
directive above. Use this to open the FunctionFS endpoint
C<ep0>. When using this option, the
activated service has to have the
C<USBFunctionDescriptors> and
C<USBFunctionStrings> options set.
',
        'type' => 'list'
      },
      'SocketProtocol',
      {
        'choice' => [
          'udplite',
          'sctp'
        ],
        'description' => 'Takes one of C<udplite>
or C<sctp>. The socket will use the UDP-Lite
(C<IPPROTO_UDPLITE>) or SCTP
(C<IPPROTO_SCTP>) protocol, respectively.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'BindIPv6Only',
      {
        'choice' => [
          'default',
          'both',
          'ipv6-only'
        ],
        'description' => 'Takes one of C<default>,
C<both> or C<ipv6-only>. Controls
the IPV6_V6ONLY socket option (see
L<ipv6(7)>
for details). If C<both>, IPv6 sockets bound
will be accessible via both IPv4 and IPv6. If
C<ipv6-only>, they will be accessible via IPv6
only. If C<default> (which is the default,
surprise!), the system wide default setting is used, as
controlled by
C</proc/sys/net/ipv6/bindv6only>, which in
turn defaults to the equivalent of
C<both>.',
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'Backlog',
      {
        'description' => 'Takes an unsigned integer argument. Specifies
the number of connections to queue that have not been accepted
yet. This setting matters only for stream and sequential
packet sockets. See
L<listen(2)>
for details. Defaults to SOMAXCONN (128).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'BindToDevice',
      {
        'description' => 'Specifies a network interface name to bind this socket to. If set, traffic will only
be accepted from the specified network interfaces. This controls the
C<SO_BINDTODEVICE> socket option (see L<socket(7)> for
details). If this option is used, an implicit dependency from this socket unit on the network
interface device unit is created
(see L<systemd.device(5)>).
Note that setting this parameter might result in additional dependencies to be added to the unit (see
above).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SocketUser',
      {
        'description' => 'Takes a UNIX user/group name. When specified, all C<AF_UNIX>
sockets and FIFO nodes in the file system are owned by the specified user and group. If unset (the
default), the nodes are owned by the root user/group (if run in system context) or the invoking
user/group (if run in user context).  If only a user is specified but no group, then the group is
derived from the user\'s default group.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SocketGroup',
      {
        'description' => 'Takes a UNIX user/group name. When specified, all C<AF_UNIX>
sockets and FIFO nodes in the file system are owned by the specified user and group. If unset (the
default), the nodes are owned by the root user/group (if run in system context) or the invoking
user/group (if run in user context).  If only a user is specified but no group, then the group is
derived from the user\'s default group.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SocketMode',
      {
        'description' => 'If listening on a file system socket or FIFO,
this option specifies the file system access mode used when
creating the file node. Takes an access mode in octal
notation. Defaults to 0666.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'DirectoryMode',
      {
        'description' => 'If listening on a file system socket or FIFO,
the parent directories are automatically created if needed.
This option specifies the file system access mode used when
creating these directories. Takes an access mode in octal
notation. Defaults to 0755.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Accept',
      {
        'description' => 'Takes a boolean argument. If yes, a service instance is spawned for each incoming
connection and only the connection socket is passed to it. If no, all listening sockets themselves
are passed to the started service unit, and only one service unit is spawned for all connections
(also see above). This value is ignored for datagram sockets and FIFOs where a single service unit
unconditionally handles all incoming traffic. Defaults to C<no>. For performance
reasons, it is recommended to write new daemons only in a way that is suitable for
C<Accept=no>. A daemon listening on an C<AF_UNIX> socket may, but
does not need to, call
L<close(2)> on the
received socket before exiting. However, it must not unlink the socket from a file system. It should
not invoke
L<shutdown(2)> on
sockets it got with C<Accept=no>, but it may do so for sockets it got with
C<Accept=yes> set. Setting C<Accept=yes> is mostly useful to allow
daemons designed for usage with L<inetd(8)> to work
unmodified with systemd socket activation.

For IPv4 and IPv6 connections, the C<REMOTE_ADDR> environment variable will
contain the remote IP address, and C<REMOTE_PORT> will contain the remote port. This
is the same as the format used by CGI. For C<SOCK_RAW>, the port is the IP
protocol.

It is recommended to set C<CollectMode=inactive-or-failed> for service
instances activated via C<Accept=yes>, to ensure that failed connection services are
cleaned up and released from memory, and do not accumulate.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Writable',
      {
        'description' => 'Takes a boolean argument. May only be used in
conjunction with C<ListenSpecial>. If true,
the specified special file is opened in read-write mode, if
false, in read-only mode. Defaults to false.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'FlushPending',
      {
        'description' => 'Takes a boolean argument. May only be used when
C<Accept=no>. If yes, the socket\'s buffers are cleared after the
triggered service exited. This causes any pending data to be
flushed and any pending incoming connections to be rejected. If no, the
socket\'s buffers won\'t be cleared, permitting the service to handle any
pending connections after restart, which is the usually expected behaviour.
Defaults to C<no>.
',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'MaxConnections',
      {
        'description' => 'The maximum number of connections to
simultaneously run services instances for, when
C<Accept=yes> is set. If more concurrent
connections are coming in, they will be refused until at least
one existing connection is terminated. This setting has no
effect on sockets configured with
C<Accept=no> or datagram sockets. Defaults to
64.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MaxConnectionsPerSource',
      {
        'description' => 'The maximum number of connections for a service per source IP address.
This is very similar to the C<MaxConnections> directive
above. Disabled by default.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'KeepAlive',
      {
        'description' => 'Takes a boolean argument. If true, the TCP/IP stack will send a keep alive message
after 2h (depending on the configuration of
C</proc/sys/net/ipv4/tcp_keepalive_time>) for all TCP streams accepted on this
socket. This controls the C<SO_KEEPALIVE> socket option (see L<socket(7)> and
the L<TCP Keepalive
HOWTO|http://www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/> for details.) Defaults to C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'KeepAliveTimeSec',
      {
        'description' => 'Takes time (in seconds) as argument. The connection needs to remain
idle before TCP starts sending keepalive probes. This controls the TCP_KEEPIDLE
socket option (see
L<socket(7)>
and the L<TCP
Keepalive HOWTO|http://www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/> for details.)
Defaults value is 7200 seconds (2 hours).',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'KeepAliveIntervalSec',
      {
        'description' => 'Takes time (in seconds) as argument between individual keepalive probes, if the
socket option C<SO_KEEPALIVE> has been set on this socket. This controls the
C<TCP_KEEPINTVL> socket option (see L<socket(7)> and
the L<TCP Keepalive
HOWTO|http://www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/> for details.) Defaults value is 75 seconds.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'KeepAliveProbes',
      {
        'description' => 'Takes an integer as argument. It is the number of
unacknowledged probes to send before considering the
connection dead and notifying the application layer. This
controls the TCP_KEEPCNT socket option (see
L<socket(7)>
and the L<TCP
Keepalive HOWTO|http://www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/> for details.) Defaults value is
9.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'NoDelay',
      {
        'description' => 'Takes a boolean argument. TCP Nagle\'s
algorithm works by combining a number of small outgoing
messages, and sending them all at once. This controls the
TCP_NODELAY socket option (see
L<tcp(7)>).
Defaults to C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Priority',
      {
        'description' => 'Takes an integer argument controlling the priority for all traffic sent from this
socket. This controls the C<SO_PRIORITY> socket option (see L<socket(7)> for
details.).',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'DeferAcceptSec',
      {
        'description' => 'Takes time (in seconds) as argument. If set,
the listening process will be awakened only when data arrives
on the socket, and not immediately when connection is
established. When this option is set, the
C<TCP_DEFER_ACCEPT> socket option will be
used (see
L<tcp(7)>),
and the kernel will ignore initial ACK packets without any
data. The argument specifies the approximate amount of time
the kernel should wait for incoming data before falling back
to the normal behavior of honoring empty ACK packets. This
option is beneficial for protocols where the client sends the
data first (e.g. HTTP, in contrast to SMTP), because the
server process will not be woken up unnecessarily before it
can take any action.

If the client also uses the
C<TCP_DEFER_ACCEPT> option, the latency of
the initial connection may be reduced, because the kernel will
send data in the final packet establishing the connection (the
third packet in the "three-way handshake").

Disabled by default.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'ReceiveBuffer',
      {
        'description' => 'Takes an integer argument controlling the receive or send buffer sizes of this
socket, respectively.  This controls the C<SO_RCVBUF> and
C<SO_SNDBUF> socket options (see L<socket(7)> for
details.). The usual suffixes K, M, G are supported and are understood to the base of
1024.',
        'match' => '^\\d+(?i)[KMG]$',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SendBuffer',
      {
        'description' => 'Takes an integer argument controlling the receive or send buffer sizes of this
socket, respectively.  This controls the C<SO_RCVBUF> and
C<SO_SNDBUF> socket options (see L<socket(7)> for
details.). The usual suffixes K, M, G are supported and are understood to the base of
1024.',
        'match' => '^\\d+(?i)[KMG]$',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'IPTOS',
      {
        'description' => 'Takes an integer argument controlling the IP Type-Of-Service field for packets
generated from this socket.  This controls the C<IP_TOS> socket option (see
L<ip(7)> for
details.). Either a numeric string or one of C<low-delay>, C<throughput>,
C<reliability> or C<low-cost> may be specified.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'IPTTL',
      {
        'description' => 'Takes an integer argument controlling the IPv4 Time-To-Live/IPv6 Hop-Count field for
packets generated from this socket. This sets the
C<IP_TTL>/C<IPV6_UNICAST_HOPS> socket options (see L<ip(7)> and
L<ipv6(7)> for
details.)',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'Mark',
      {
        'description' => 'Takes an integer value. Controls the firewall mark of packets generated by this
socket. This can be used in the firewall logic to filter packets from this socket. This sets the
C<SO_MARK> socket option. See L<iptables(8)> for
details.',
        'type' => 'leaf',
        'value_type' => 'integer'
      },
      'ReusePort',
      {
        'description' => 'Takes a boolean value. If true, allows multiple
L<bind(2)>s to this TCP
or UDP port. This controls the C<SO_REUSEPORT> socket option. See L<socket(7)> for
details.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'SmackLabel',
      {
        'description' => 'Takes a string value. Controls the extended
attributes C<security.SMACK64>,
C<security.SMACK64IPIN> and
C<security.SMACK64IPOUT>, respectively, i.e.
the security label of the FIFO, or the security label for the
incoming or outgoing connections of the socket, respectively.
See L<Smack.txt|https://www.kernel.org/doc/Documentation/security/Smack.txt>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SmackLabelIPIn',
      {
        'description' => 'Takes a string value. Controls the extended
attributes C<security.SMACK64>,
C<security.SMACK64IPIN> and
C<security.SMACK64IPOUT>, respectively, i.e.
the security label of the FIFO, or the security label for the
incoming or outgoing connections of the socket, respectively.
See L<Smack.txt|https://www.kernel.org/doc/Documentation/security/Smack.txt>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SmackLabelIPOut',
      {
        'description' => 'Takes a string value. Controls the extended
attributes C<security.SMACK64>,
C<security.SMACK64IPIN> and
C<security.SMACK64IPOUT>, respectively, i.e.
the security label of the FIFO, or the security label for the
incoming or outgoing connections of the socket, respectively.
See L<Smack.txt|https://www.kernel.org/doc/Documentation/security/Smack.txt>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'SELinuxContextFromNet',
      {
        'description' => 'Takes a boolean argument. When true, systemd
will attempt to figure out the SELinux label used for the
instantiated service from the information handed by the peer
over the network. Note that only the security level is used
from the information provided by the peer. Other parts of the
resulting SELinux context originate from either the target
binary that is effectively triggered by socket unit or from
the value of the C<SELinuxContext> option.
This configuration option applies only when activated service
is passed in single socket file descriptor, i.e. service
instances that have standard input connected to a socket or
services triggered by exactly one socket unit. Also note
that this option is useful only when MLS/MCS SELinux policy
is deployed. Defaults to
C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PipeSize',
      {
        'description' => 'Takes a size in bytes. Controls the pipe
buffer size of FIFOs configured in this socket unit. See
L<fcntl(2)>
for details. The usual suffixes K, M, G are supported and are
understood to the base of 1024.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'MessageQueueMaxMessages',
      {
        'description' => 'These two settings take integer values and
control the mq_maxmsg field or the mq_msgsize field,
respectively, when creating the message queue. Note that
either none or both of these variables need to be set. See
L<mq_setattr(3)>
for details.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'FreeBind',
      {
        'description' => 'Takes a boolean value. Controls whether the socket can be bound to non-local IP
addresses. This is useful to configure sockets listening on specific IP addresses before those IP
addresses are successfully configured on a network interface. This sets the
C<IP_FREEBIND>/C<IPV6_FREEBIND> socket option. For robustness
reasons it is recommended to use this option whenever you bind a socket to a specific IP
address. Defaults to C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Transparent',
      {
        'description' => 'Takes a boolean value. Controls the
C<IP_TRANSPARENT>/C<IPV6_TRANSPARENT> socket option. Defaults to
C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Broadcast',
      {
        'description' => 'Takes a boolean value. This controls the C<SO_BROADCAST> socket
option, which allows broadcast datagrams to be sent from this socket. Defaults to
C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PassCredentials',
      {
        'description' => 'Takes a boolean value. This controls the C<SO_PASSCRED> socket
option, which allows C<AF_UNIX> sockets to receive the credentials of the sending
process in an ancillary message. Defaults to C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PassSecurity',
      {
        'description' => 'Takes a boolean value. This controls the C<SO_PASSSEC> socket
option, which allows C<AF_UNIX> sockets to receive the security context of the
sending process in an ancillary message.  Defaults to C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'PassPacketInfo',
      {
        'description' => 'Takes a boolean value. This controls the C<IP_PKTINFO>,
C<IPV6_RECVPKTINFO>, C<NETLINK_PKTINFO> or
C<PACKET_AUXDATA> socket options, which enable reception of additional per-packet
metadata as ancillary message, on C<AF_INET>, C<AF_INET6>,
C<AF_UNIX> and C<AF_PACKET> sockets.  Defaults to
C<false>.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Timestamping',
      {
        'choice' => [
          'off',
          'us',
          'usec',
          "\x{b5}s",
          'ns',
          'nsec'
        ],
        'description' => "Takes one of C<off>, C<us> (alias:
C<usec>, C<\x{b5}s>) or C<ns> (alias:
C<nsec>). This controls the C<SO_TIMESTAMP> or
C<SO_TIMESTAMPNS> socket options, and enables whether ingress network traffic shall
carry timestamping metadata. Defaults to C<off>.",
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'TCPCongestion',
      {
        'description' => 'Takes a string value. Controls the TCP congestion algorithm used by this
socket. Should be one of C<westwood>, C<veno>,
C<cubic>, C<lp> or any other available algorithm supported by the IP
stack. This setting applies only to stream sockets.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ExecStartPre',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Takes one or more command lines, which are
executed before or after the listening sockets/FIFOs are
created and bound, respectively. The first token of the
command line must be an absolute filename, then followed by
arguments for the process. Multiple command lines may be
specified following the same scheme as used for
C<ExecStartPre> of service unit
files.',
        'type' => 'list'
      },
      'ExecStartPost',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Takes one or more command lines, which are
executed before or after the listening sockets/FIFOs are
created and bound, respectively. The first token of the
command line must be an absolute filename, then followed by
arguments for the process. Multiple command lines may be
specified following the same scheme as used for
C<ExecStartPre> of service unit
files.',
        'type' => 'list'
      },
      'ExecStopPre',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Additional commands that are executed before
or after the listening sockets/FIFOs are closed and removed,
respectively. Multiple command lines may be specified
following the same scheme as used for
C<ExecStartPre> of service unit
files.',
        'type' => 'list'
      },
      'ExecStopPost',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Additional commands that are executed before
or after the listening sockets/FIFOs are closed and removed,
respectively. Multiple command lines may be specified
following the same scheme as used for
C<ExecStartPre> of service unit
files.',
        'type' => 'list'
      },
      'TimeoutSec',
      {
        'description' => 'Configures the time to wait for the commands
specified in C<ExecStartPre>,
C<ExecStartPost>,
C<ExecStopPre> and
C<ExecStopPost> to finish. If a command does
not exit within the configured time, the socket will be
considered failed and be shut down again. All commands still
running will be terminated forcibly via
C<SIGTERM>, and after another delay of this
time with C<SIGKILL>. (See
C<KillMode> in
L<systemd.kill(5)>.)
Takes a unit-less value in seconds, or a time span value such
as "5min 20s". Pass C<0> to disable the
timeout logic. Defaults to
C<DefaultTimeoutStartSec> from the manager
configuration file (see
L<systemd-system.conf(5)>).
',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Service',
      {
        'description' => 'Specifies the service unit name to activate on
incoming traffic. This setting is only allowed for sockets
with C<Accept=no>. It defaults to the service
that bears the same name as the socket (with the suffix
replaced). In most cases, it should not be necessary to use
this option. Note that setting this parameter might result in
additional dependencies to be added to the unit (see
above).',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RemoveOnStop',
      {
        'description' => 'Takes a boolean argument. If enabled, any file nodes created by this socket unit are
removed when it is stopped. This applies to C<AF_UNIX> sockets in the file system,
POSIX message queues, FIFOs, as well as any symlinks to them configured with
C<Symlinks>. Normally, it should not be necessary to use this option, and is not
recommended as services might continue to run after the socket unit has been terminated and it should
still be possible to communicate with them via their file system node. Defaults to
off.',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Symlinks',
      {
        'description' => 'Takes a list of file system paths. The specified paths will be created as symlinks to the
C<AF_UNIX> socket path or FIFO path of this socket unit. If this setting is used, only one
C<AF_UNIX> socket in the file system or one FIFO may be configured for the socket unit. Use
this option to manage one or more symlinked alias names for a socket, binding their lifecycle together. Note
that if creation of a symlink fails this is not considered fatal for the socket unit, and the socket unit may
still start. If an empty string is assigned, the list of paths is reset. Defaults to an empty
list.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'FileDescriptorName',
      {
        'description' => 'Assigns a name to all file descriptors this
socket unit encapsulates. This is useful to help activated
services identify specific file descriptors, if multiple fds
are passed. Services may use the
L<sd_listen_fds_with_names(3)>
call to acquire the names configured for the received file
descriptors. Names may contain any ASCII character, but must
exclude control characters and C<:>, and must
be at most 255 characters in length. If this setting is not
used, the file descriptor name defaults to the name of the
socket unit, including its C<.socket>
suffix.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TriggerLimitIntervalSec',
      {
        'description' => "Configures a limit on how often this socket unit may be activated within a specific time
interval. The C<TriggerLimitIntervalSec> may be used to configure the length of the time
interval in the usual time units C<us>, C<ms>, C<s>,
C<min>, C<h>, \x{2026} and defaults to 2s (See
L<systemd.time(7)> for details on
the various time units understood). The C<TriggerLimitBurst> setting takes a positive integer
value and specifies the number of permitted activations per time interval, and defaults to 200 for
C<Accept=yes> sockets (thus by default permitting 200 activations per 2s), and 20 otherwise (20
activations per 2s). Set either to 0 to disable any form of trigger rate limiting. If the limit is hit, the
socket unit is placed into a failure mode, and will not be connectible anymore until restarted. Note that this
limit is enforced before the service activation is enqueued.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'TriggerLimitBurst',
      {
        'description' => "Configures a limit on how often this socket unit may be activated within a specific time
interval. The C<TriggerLimitIntervalSec> may be used to configure the length of the time
interval in the usual time units C<us>, C<ms>, C<s>,
C<min>, C<h>, \x{2026} and defaults to 2s (See
L<systemd.time(7)> for details on
the various time units understood). The C<TriggerLimitBurst> setting takes a positive integer
value and specifies the number of permitted activations per time interval, and defaults to 200 for
C<Accept=yes> sockets (thus by default permitting 200 activations per 2s), and 20 otherwise (20
activations per 2s). Set either to 0 to disable any form of trigger rate limiting. If the limit is hit, the
socket unit is placed into a failure mode, and will not be connectible anymore until restarted. Note that this
limit is enforced before the service activation is enqueued.",
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'generated_by' => 'parse-man.pl from systemd 250 doc',
    'license' => 'LGPLv2.1+',
    'name' => 'Systemd::Section::Socket'
  }
]
;


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
    'class_description' => 'Configuration class that represents the parameters required
to specify port forwarding in a ssh configuration.',
    'copyright' => [
      '2009-2011 Dominique Dumont'
    ],
    'element' => [
      'ipv6',
      {
        'description' => 'Specify if the forward is specified iwth IPv6 or IPv4',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'bind_address',
      {
        'description' => 'Specify the address that the port will listen to. By default, only connections coming from localhost (127.0.0.1) will be forwarded.

By default, the local port is bound in accordance with the GatewayPorts setting. However, an explicit bind_address may be used to bind the connection to a specific address.

The bind_address of \'localhost\' indicates that the listening port be bound for local use only, while an empty address or \'*\' indicates that the port should be available from all interfaces.',
        'summary' => 'bind address to listen to',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'port',
      {
        'description' => 'Listening port. Connection made to this port will be forwarded to the other side of the tunnel.',
        'mandatory' => '1',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'host',
      {
        'mandatory' => '1',
        'summary' => 'host name or address',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'hostport',
      {
        'description' => 'Port number to connect the tunnel to.',
        'mandatory' => '1',
        'summary' => 'destination port',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'license' => 'LGPL2',
    'name' => 'Ssh::PortForward'
  }
]
;


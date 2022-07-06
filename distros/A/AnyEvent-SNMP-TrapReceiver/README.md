[![Actions Status](https://github.com/bojanra/AnyEvent-SNMP-TrapReceiver/actions/workflows/test.yml/badge.svg)](https://github.com/bojanra/AnyEvent-SNMP-TrapReceiver/actions)
# NAME

AnyEvent::SNMP::TrapReceiver - SNMP trap receiver by help of AnyEvent

# SYNOPSIS

    use AnyEvent::SNMP::TrapReceiver;

    my $cond = AnyEvent->condvar;

    my $echo_server = AnyEvent::SNMP::TrapReceiver->new(
        bind => ['0.0.0.0', 162],
        cb => sub {
            my ( $trap) = @_;
        },
    );

    my $done = $cond->recv;

# DESCRIPTION

This is a wrapper for the AnyEvent::Handle::UDP with embedded SNMP trap decoder.

Currently only v1 and v2c traps are supported.

The trap decoder code was copied from Net::SNMPTrapd by Michael Vincent.

# ATTRIBUTES

## bind

The IP address and port to bind the UDP listener/handle.

## cb

The codeblock to be called when a trap is received.

# TIPS&TRICKS

The default port for SNMP traps is 162. In Linux ports below 1024 are privileged ports and typically
only root can acccess these ports. If you don't want to run your script as root user you can use

    iptables -A PREROUTING -t nat -i eth0 -p udp -m udp --dport 162 -j REDIRECT --to-ports 1162

to redirect the port.
You can go even further and redirect only traps from specific sources to your app

    iptables -A PREROUTING -t nat -i eth0 -s 192.168.33.16/32 -p udp -m udp --dport 162 -j REDIRECT --to-ports 1162

# LICENSE

Copyright (C) Bojan Ramšak.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Bojan Ramšak <bojanr@gmx.net>

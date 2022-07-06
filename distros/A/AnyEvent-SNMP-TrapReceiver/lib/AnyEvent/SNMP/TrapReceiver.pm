package AnyEvent::SNMP::TrapReceiver;
use 5.010;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle::UDP;
use Convert::ASN1;
use Carp;

our $VERSION = "0.16";

########################################################
# Start Variables
########################################################
use constant SNMPTRAPD_DEFAULT_PORT => 162;

my @TRAPTYPES = qw(COLDSTART WARMSTART LINKDOWN LINKUP AUTHFAIL EGPNEIGHBORLOSS ENTERPRISESPECIFIC);
our $LASTERROR;

my $asn = Convert::ASN1->new;
$asn->prepare( "
    PDU ::= SEQUENCE {
        version   INTEGER,
        community STRING,
        pdu_type  PDUs
    }
    PDUs ::= CHOICE {
        response        Response_PDU,
        trap            Trap_PDU,
        inform_request  InformRequest_PDU,
        snmpv2_trap     SNMPv2_Trap_PDU
    }
    Response_PDU      ::= [2] IMPLICIT PDUv2
    Trap_PDU          ::= [4] IMPLICIT PDUv1
    InformRequest_PDU ::= [6] IMPLICIT PDUv2
    SNMPv2_Trap_PDU   ::= [7] IMPLICIT PDUv2

    IPAddress ::= [APPLICATION 0] STRING
    Counter32 ::= [APPLICATION 1] INTEGER
    Guage32   ::= [APPLICATION 2] INTEGER
    TimeTicks ::= [APPLICATION 3] INTEGER
    Opaque    ::= [APPLICATION 4] STRING
    Counter64 ::= [APPLICATION 6] INTEGER

    PDUv1 ::= SEQUENCE {
        ent_oid         OBJECT IDENTIFIER,
        agent_addr      IPAddress,
        generic_trap    INTEGER,
        specific_trap   INTEGER,
        timeticks       TimeTicks,
        varbindlist     VARBINDS
    }
    PDUv2 ::= SEQUENCE {
        request_id      INTEGER,
        error_status    INTEGER,
        error_index     INTEGER,
        varbindlist     VARBINDS
    }
    VARBINDS ::= SEQUENCE OF SEQUENCE {
        oid    OBJECT IDENTIFIER,
        value  CHOICE {
            integer   INTEGER,
            string    STRING,
            oid       OBJECT IDENTIFIER,
            ipaddr    IPAddress,
            counter32 Counter32,
            guage32   Guage32,
            timeticks TimeTicks,
            opaque    Opaque,
            counter64 Counter64,
            null      NULL
        }
    }
" );
my $snmpasn = $asn->find('PDU');
########################################################
# End Variables
########################################################

sub new {
    my ( $class, %args ) = @_;
    my $self = bless { cb => $args{cb} || croak('cb not given'), }, $class;

    my $bindTo;
    if ( exists $args{bind} ) {
        $bindTo = $args{bind};
    } else {
        $bindTo = [ '0.0.0.0', SNMPTRAPD_DEFAULT_PORT ],;
    }

    $self->{server} = AnyEvent::Handle::UDP->new(
        bind    => $bindTo,
        on_recv => sub {
            my $trap = _handle_trap(@_);

            $self->format($trap);

            &{ $self->{cb} }($trap);
        }
    );

    return $self;
} ## end sub new

sub _handle_trap {
    my ( $data, $ae_handle, $client_addr ) = @_;

    my $trap = $snmpasn->decode($data);

    # get the sender IP
    my ( $port, $addr ) = AnyEvent::Socket::unpack_sockaddr($client_addr);

    # humanize
    $trap->{remoteaddr} = format_address($addr);
    $trap->{remoteport} = $port;

    return $trap;
} ## end sub _handle_trap

sub format {
    my ( $self, $trap ) = @_;

    # version starts at '1'
    $trap->{version} += 1;

    # unify v1 and v2c traps
    if ( exists $trap->{pdu_type}{snmpv2_trap} ) {
        %$trap = ( %{ delete $trap->{pdu_type}{snmpv2_trap} }, %$trap );
    } else {
        %$trap = ( %{ delete $trap->{pdu_type}{trap} }, %$trap );
    }
    delete $trap->{pdu_type};

    if ( exists $trap->{agent_addr} ) {
        $trap->{agent_addr} = format_address( $trap->{agent_addr} );
    }

    if ( exists $trap->{generic_trap} ) {
        $trap->{generic_trap} = $TRAPTYPES[ $trap->{generic_trap} ];
    }

    # uptime
    if ( exists $trap->{timeticks} ) {
        my $timeticks = 0xffffffff & $trap->{timeticks};
        $trap->{timeticks} = $timeticks;
        my @uptime = (
            int( $timeticks / 8640000 ),    # days
            int( ( $timeticks % 8640000 ) / 360000 ),    # hours
            int( ( $timeticks % 360000 ) / 6000 ),       # minutes
            int( ( $timeticks % 6000 ) / 100 ),          # seconds
        );
        $trap->{uptime} = \@uptime;
    } ## end if ( exists $trap->{timeticks...})

    # convert varbindlist to key->value
    foreach my $var ( @{ $trap->{varbindlist} } ) {
        my $oid   = $var->{oid};
        my $value = $var->{value};
        $trap->{oid}{$oid} = ( values( %{$value} ) )[0];
    }

    delete $trap->{varbindlist};

    return $trap;
} ## end sub format

1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::SNMP::TrapReceiver - SNMP trap receiver by help of AnyEvent

=head1 SYNOPSIS

    use AnyEvent::SNMP::TrapReceiver;

    my $cond = AnyEvent->condvar;

    my $echo_server = AnyEvent::SNMP::TrapReceiver->new(
        bind => ['0.0.0.0', 162],
        cb => sub {
            my ( $trap) = @_;
        },
    );

    my $done = $cond->recv;

=head1 DESCRIPTION

This is a wrapper for the AnyEvent::Handle::UDP with embedded SNMP trap decoder.

Currently only v1 and v2c traps are supported.

The trap decoder code was copied from Net::SNMPTrapd by Michael Vincent.

=head1 ATTRIBUTES

=head2 bind

The IP address and port to bind the UDP listener/handle.

=head2 cb

The codeblock to be called when a trap is received.

=head1 TIPS&TRICKS

The default port for SNMP traps is 162. In Linux ports below 1024 are privileged ports and typically
only root can acccess these ports. If you don't want to run your script as root user you can use

  iptables -A PREROUTING -t nat -i eth0 -p udp -m udp --dport 162 -j REDIRECT --to-ports 1162

to redirect the port.
You can go even further and redirect only traps from specific sources to your app

  iptables -A PREROUTING -t nat -i eth0 -s 192.168.33.16/32 -p udp -m udp --dport 162 -j REDIRECT --to-ports 1162


=head1 LICENSE

Copyright (C) Bojan Ramšak.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bojan Ramšak E<lt>bojanr@gmx.netE<gt>

=cut


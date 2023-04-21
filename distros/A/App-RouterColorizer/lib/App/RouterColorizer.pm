#!/usr/bin/env perl

#
# Copyright (C) 2021-2023 Joelle Maslak
# All Rights Reserved - See License
#

# ABSTRACT: Colorize router CLI output

use v5.22;
use strict;
use warnings;

package App::RouterColorizer;
$App::RouterColorizer::VERSION = '1.231100';
use Moose;

use feature 'signatures';
no warnings 'experimental::signatures';

use English;
use Import::Into;
use List::Util qw(any);
use Regexp::Common qw/net number/;

# Ugly! But we need multidimensional arrays to work to get access to the
# syntactic sugar in Regexp::Common. Unfortunately, this feature didn't
# exist until recently (it was defaulting to being on).
BEGIN {
    if ( $PERL_VERSION gt v5.33.0 ) {
        feature->import::into( __PACKAGE__, qw(multidimensional) );
    }
}

our $GREEN  = "\e[32m";      # Green ANSI code
our $RED    = "\e[1;31m";    # Bold + Red ANSI code
our $ORANGE = "\e[33m";      # Orange
our $INFO   = "\e[36m";      # Cyan
our $RESET  = "\e[0m";

our @BGCOLORS = (
    "\e[30m\e[47m",    # black on white
    "\e[30m\e[41m",    # black on red
    "\e[30m\e[42m",    # black on green
    "\e[30m\e[43m",    # black on yellow (orange)
    "\e[37m\e[44m",    # white on blue
    "\e[30m\e[45m",    # black on magenta
    "\e[30m\e[46m",    # black on cyan
);

our $NUM      = qr/$RE{num}{real}/;
our $INT      = qr/$RE{num}{int}{-sign => ''}/;
our $POSINT   = qr/(?!0)$INT/;
our $LOWLIGHT = qr/ (?: -[3-9][0-9]\. [0-9]{1,2} )
                  | (?: - \s Inf)
                  | (?: -2 [5-9] \. [0-9]{1,2} )/xx;
our $VERYLL = qr/ (?: -[4-9][0-9]\. [0-9]{1,2} )/xx;
our $LIGHT  = qr/ (?: $NUM ) | (?: N\/A ) /xx;

our $GOODRETURNLOSS = qr/ (?: 29\.[0-9]+ )
                        | (?: [3-9][0-9]+\.[0-9]+ )/xx;
our $WARNRETURNLOSS = qr/ (?: 2[0-8]\.[0-9]+ )
                        | (?: 1[6-9]\.[0-9]+ )/xx;
our $BADRETURNLOSS = qr/ (?: 1[0-5]\.[0-9]+ )
                       | (?:  [0-9]\.[0-9]+ )/xx;

our $IPV4CIDR = qr/ $RE{net}{IPv4}
                   (?: \/
                       (?:
                             (?:[12][0-9])
                           | (?:3[0-2])
                           | (?:[0-9])
                        )
                    )?
                /xx;

our $IPV6CIDR = qr/ $RE{net}{IPv6}
                   (?: \/
                       (?:
                             (?:1[01][0-9])
                           | (?:12[0-8])
                           | (?:[1-9][0-9])
                           | (?:[0-9])
                        )
                    )?
                /xx;

our $BIGALARMS    = qr/critical|major|minor|warning/;
our $LITTLEALARMS = qr/info/;
our $BIGOVERRIDES = qr/   (?:\QRx Remote Fault\E)
                        | (?:\QFar End Client Signal Fail\E)
                    /xx;

our @INTERFACE_IGNORES = ( "bytes", "packets input", "packets output", "multicast" );
our @INTERFACE_INFOS   = ( "PAUSE input", "PAUSE output", "pause input" );

our $STP_GOOD  = qr/forwarding|FWD/;
our $STP_WARN  = qr/learning|LRN/;
our $STP_BAD   = qr/discarding|BLK/;
our $STP_TYPES = qr/designated|root|alternate|Desg|Root|Altn/;

our @bgcolors = (
    "\e[30m\e[47m",    # black on white
    "\e[30m\e[41m",    # black on red
    "\e[30m\e[42m",    # black on green
    "\e[30m\e[43m",    # black on yellow (orange)
    "\e[37m\e[44m",    # white on blue
    "\e[30m\e[45m",    # black on magenta
    "\e[30m\e[46m",    # black on cyan
);

sub format_text ( $self, $text ) {
    # Remove Arista "more" prompt
    $text =~ s/ \x1b \[ \Q3m --More-- \E \x1b \[ 23m \x1b \[ K \r \x1b \[ K //gmsxx;

    # Break into lines
    my $output = '';
    while ( $text =~ m/([^\n\r]*[\r]?[\n]?)/g ) {
        $output .= $self->_parse_line($1);
    }
    return $output;
}

sub _parse_line ( $self, $text ) {
    my ( $line, $eol ) = $text =~ m/([^\n]*)(\n?)/;

    # We want to strip out the control characters at the start of the
    # line. This is kind of black magic...
    my $preamble = '';
    if ( $line =~ s/^ ( .* (?<! \x1b \[23m) \x1b (?: \[K | M)) //sxx ) {
        $preamble = $1;
    }

    # Arista "More" prompt (should this be in the Arista parse-line?)
    $line =~ s/ ^ ( \x1b \[ \Q3m --More-- \E .* \x0d \x1b \[K )//sxx;

    # A space that is backspaced over
    $line =~ s/ \Q \E \x08 //gxx;

    my $trailer = "";
    if ( $line =~ s/(\x0d) $//sxx ) {
        $trailer = $1;
    }

    $line = $self->_parse_line_arista($line);
    $line = $self->_parse_line_vyos($line);
    $line = $self->_parse_line_junos($line);
    $line = $self->_parse_line_ciena($line);

    # IPv4
    $line =~ s/($IPV4CIDR)/$self->_ipv4ify($1)/egxx;

    # IPv6
    $line =~ s/ ( (?<! [a-fA-F0-9:\-]) $IPV6CIDR (?! [\w:\.\/]) ) /$self->_ipv6ify($1)/egxx;

    # Numbers
    # We need to make sure we don't highlight undesirably, such as in an
    # escape sequence.
    $line =~ s/ (
                    (?<! [:\.0-9]) (?<! \e \[) (?<! \e \[\?)
                    [0-9]+ (?! [:0-9])
                ) /$self->_numerify($1)/egxx;

    return "$preamble$line$trailer$eol";
}

sub _parse_line_arista ( $self, $line ) {
    #
    # Arista & Cisco
    #

    # BGP
    $line =~ s/^ ( \Q  BGP state is Established\E \N* ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( \Q  BGP state is \E            \N* ) $/$self->_colorize($1, $RED)/exx;

    $line =~
s/^ ( \Q  Last \E (?: sent || rcvd) \  (?: socket-error || notification) : \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~
      s/^ ( \ \ (?: Inbound || Outbound) \Q route map is \E \N* )$/$self->_colorize($1, $INFO)/exx;
    $line =~
s/^ ( \Q  Inherits configuration from and member of peer-group \E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~
      s/^ ( \Q    \E (?: IPv4 | IPv6) \Q Unicast:     \E \N* ) $/$self->_colorize($1, $INFO)/exx;
    $line =~
s/^ ( \Q  Configured maximum total number of routes is \E \d+ (?: \Q, warning limit is \E \d+ )? ) $/$self->_colorize($1, $INFO)/exx;

    # BGP Errors
    my $errors = qr/
        ^
        \Q    \E
        (?:
            \QAS path loop detection\E
            | \QEnforced First AS\E
            | \QMalformed MPBGP routes\E
            | \QAS path loop detection\E
            | \QOriginator ID matches local router ID\E
            | \QNexthop matches local IP address\E
            | \QResulting in removal of all paths in update (treat as withdraw)\E
            | \QResulting in AFI\E \/ \QSAFI disable\E
            | \QResulting in attribute ignore\E
            | \QDisabled AFI\E \/ \QSAFIs\E
            | \QIPv4 labeled-unicast NLRIs dropped due to excessive labels\E
            | \QIPv6 labeled-unicast NLRIs dropped due to excessive labels\E
            | \QIPv4 local address not available\E
            | \QIPv6 local address not available\E
            | \QUnexpected IPv6 nexthop for IPv4 routes\E
        )
        \Q: \E
        $POSINT
        $
    /xx;
    $line =~ s/($errors)/$self->_colorize($1, $RED)/e;

    $line =~ s/^ ( \QBGP neighbor is \E \N+ ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( (?: Local | Remote) \Q TCP address is \E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    #
    # Interfaces
    #

    # We look for information lines
    if ( $line =~ m/^     ((?:$INT [^,]+, )*$INT [^,]+)$/ ) {
        my (%values) =
          map { reverse split / /, $_, 2 } split ', ', $1;

        if ( any { exists( $values{$_} ) } @INTERFACE_IGNORES ) {
            # Do nothing.
        } elsif ( any { exists( $values{$_} ) } @INTERFACE_INFOS ) {
            $line = $self->_colorize( $line, $INFO );
        } elsif ( any { $values{$_} } keys %values ) {
            $line = $self->_colorize( $line, $RED );
        } else {
            $line = $self->_colorize( $line, $GREEN );
        }
    }

    my $INTERFACE = qr/ [A-Z] \S+ /xx;
    my $INTSHORT  = qr/ [A-Z][a-z][0-9] \S* /xx;

    # "show int" up/down
    $line =~
s/^ ( $INTERFACE \Q is up, line protocol is up\E (:? \Q (connected)\E )? \s? ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~
s/^ ( $INTERFACE \Q is administratively down,\E \N+                          ) $/$self->_colorize($1, $ORANGE)/exx;
    $line =~
s/^ ( $INTERFACE \Q is \E \N+ \Q, line protocol is \E \N+                    ) $/$self->_colorize($1, $RED)/exx;

    $line =~ s/^ ( \Q  Up \E   \N+ ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( \Q  Down \E \N+ ) $/$self->_colorize($1, $RED)/exx;

    # "show int" description lines
    $line =~ s/^ ( (?: \Q \E|\Q   \E)? \Q Description: \E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    # "show int" rates
    $line =~
s/^ ( \Q  \E $NUM \s \w+ \s (?: input | output) \s rate \s $NUM \s \N+ ) $/$self->_colorize($1, $INFO)/exx;

    # "show int status"
    $line =~ s/^ ( $INTSHORT \N+ \Q connected \E   \N+ ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( $INTSHORT \N+ \Q disabled \E    \N+ ) $/$self->_colorize($1, $ORANGE)/exx;
    $line =~ s/^ ( $INTSHORT \N+ \Q errdisabled \E \N+ ) $/$self->_colorize($1, $RED)/exx;
    $line =~ s/^ ( $INTSHORT \N+ \Q notconnect \E  \N+ ) $/$self->_colorize($1, $RED)/exx;

    # "show int description"
    $line =~
      s/^ ( $INTSHORT \s+ up             \s+ up  (?: \s+ \N+)? ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~
s/^ ( $INTSHORT \s+ \Qadmin down\E \s+ \S+ (?: \s+ \N+)? ) $/$self->_colorize($1, $ORANGE)/exx;
    $line =~
      s/^ ( $INTSHORT \s+ down           \s+ \S+ (?: \s+ \N+)? ) $/$self->_colorize($1, $RED)/exx;

    # "show int transceiver" (Arista)
    $line =~
s/^ ( $INTSHORT (?: \s+ $LIGHT){4} \s+ $LOWLIGHT \s+ \S+ \s ago ) $/$self->_colorize($1, $RED)/exx;
    $line =~
s/^ ( $INTSHORT (?: \s+ $LIGHT){5}               \s+ \S+ \s ago ) $/$self->_colorize($1, $INFO)/exx;
    $line =~
s/^ ( $INTSHORT (?: \s+ N\/A  ){6} \s*                          ) $/$self->_colorize($1, $ORANGE)/exx;

    # "show int transceiver" (Cisco)
    $line =~
      s/^ ( $INTSHORT (?: \s+ $LIGHT){3} \s+ $LOWLIGHT ) \s+ $/$self->_colorize($1, $RED)/exx;
    $line =~
      s/^ ( $INTSHORT (?: \s+ $LIGHT){4}               ) \s+ $/$self->_colorize($1, $INFO)/exx;

    #
    # LLDP Neighbors Detail
    #
    $line =~
s/^ ( \QInterface\E \s \S+ \s detected \s $POSINT \Q LLDP neighbors:\E ) $/$self->_colorize($1, $INFO)/exx;
    $line =~
      s/^ ( \Q  Neighbor \E \S+ \s age \s $POSINT \s seconds ) $/$self->_colorize($1, $INFO)/exx;
    $line =~
s/^ ( \Q  Discovered \E \N+ \Q; Last changed \E \N+ \s ago ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( \Q  - System Name: \E \N+ ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( \Q    Port ID     :\E \N+ ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( \Q    Management Address        : \E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    #
    # Show Spanning-Tree
    #
    $line =~
s/^ ( $INTSHORT \s+ $STP_TYPES\s+ $STP_GOOD \s+ [0-9]+ \s+ [0-9]+\.[0-9]+ \s+ P2p .* ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~
s/^ ( $INTSHORT \s+ $STP_TYPES\s+ $STP_WARN \s+ [0-9]+ \s+ [0-9]+\.[0-9]+ \s+ P2p .* ) $/$self->_colorize($1, $ORANGE)/exx;
    $line =~
s/^ ( $INTSHORT \s+ $STP_TYPES\s+ $STP_BAD  \s+ [0-9]+ \s+ [0-9]+\.[0-9]+ \s+ P2p .* ) $/$self->_colorize($1, $RED)/exx;


    # show bgp rpki cache (Arista)
    $line =~ s/^ (State: \s synced) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ (State: \s .*    ) $/$self->_colorize($1, $RED)/exx;

    $line =~ s/^ (Connection: \s Active \s .*) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ (Connection: \s .*          ) $/$self->_colorize($1, $RED)/exx;

    return $line;
}

sub _parse_line_junos ( $self, $line ) {

    #
    # JunOS
    #

    # Show Interfaces
    $line =~
s/^ ( \QPhysical interface: \E \S+ \Q Enabled, Physical link is Up\E   ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~
s/^ ( \QPhysical interface: \E \S+ \Q Enabled, Physical link is Down\E ) $/$self->_colorize($1, $RED)/exx;
    $line =~
s/^ ( \QPhysical interface: \E \S+ \s \S+ \Q Physical link is Down\E   ) $/$self->_colorize($1, $ORANGE)/exx;
    $line =~
s/^ ( \QPhysical interface: \E \S+                                     ) $/$self->_colorize($1, $INFO)/exx;

    $line =~ s/^ ( \Q  Logical interface \E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~ s/^ ( \Q  Last flapped   : \E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~ s/^ ( \Q  Input rate     : \E $NUM \N+ ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( \Q  Output rate    : \E $NUM \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~ s/^ ( \Q    Input packets : \E $NUM \N+ ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( \Q    Output packets: \E $NUM \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~ s/^ ( \Q  Active alarms  : None\E ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( \Q  Active alarms  : \E \N+ ) $/$self->_colorize($1, $RED)/exx;
    $line =~ s/^ ( \Q  Active defects : None\E ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( \Q  Active defects : \E \N+ ) $/$self->_colorize($1, $RED)/exx;

    my $AE    = qr/ (?: ae [0-9\.]+          ) /xx;
    my $BME   = qr/ (?: bme [0-9\.]+         ) /xx;
    my $CBP   = qr/ (?: cbp [0-9\.]+         ) /xx;
    my $ETH   = qr/ (?: [gx] e- [0-9\/\.]+   ) /xx;
    my $IRB   = qr/ (?: irb [0-9\/\.]*       ) /xx;
    my $JSRV  = qr/ (?: jsrv [0-9\.]*        ) /xx;
    my $LO    = qr/ (?: lo [0-9\.]+          ) /xx;
    my $ME    = qr/ (?: me [0-9\.]+          ) /xx;
    my $PFE   = qr/ (?: pf [eh] - [0-9\/\.]+ ) /xx;
    my $PIP   = qr/ (?: pip [0-9\/\.]+       ) /xx;
    my $VCP   = qr/ (?: vcp- [0-9\/\.]+      ) /xx;
    my $VLAN  = qr/ (?: vlan\. [0-9]+        ) /xx;
    my $OTHER = qr/
            (:? fti|fxp|gr|ip|lsq|lt|mt|sp|pp|ppd|ppe|st ) (:?-)? [0-9\/\.]+
          | gr-\S+
          | dsc | esi | gre | ipip | jsrv | lsi
          | mtun | pimd | pime | rbeb | tap | vlan | vme | vtep
    /xx;

    my $IFACES = qr/$AE|$BME|$CBP|$ETH|$IRB|$LO|$ME|$JSRV|$PFE|$PIP|$VCP|$VLAN|$OTHER/xx;

    $line =~ s/^ ( (?: $IFACES) \s+ up \s+ up \N*   ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ (     $ETH     \s+ VCP             ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( (?: $IFACES) \s+ up \s+ down \N* ) $/$self->_colorize($1, $RED)/exx;
    $line =~ s/^ ( (?: $IFACES) \s+ down \s+ \N*    ) $/$self->_colorize($1, $ORANGE)/exx;

    # Errors
    $line =~ s/^ ( \Q    Bit errors \E \s+ 0           ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( \Q    Bit errors \E \s+ 0           ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~ s/^ ( \Q    Errored blocks \E \s+ [1-9][0-9]+ ) $/$self->_colorize($1, $RED)/exx;
    $line =~ s/^ ( \Q    Errored blocks \E \s+ 0           ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~
      s/^ ( \Q    FEC \E \S+ \s Errors (?: \s Rate)? \s+ 0   ) $/$self->_colorize($1, $GREEN)/exx;
    $line =~
      s/^ ( \Q    FEC \E \S+ \s Errors (?: \s Rate)? \s+ \N+ ) $/$self->_colorize($1, $RED)/exx;

    # show interfaces diagnostics optics
    $line =~ s/^ ( \Q    Laser output power \E \s+ : \s $NUM \N+ ) $/$self->_colorize($1, $RED)/exx;
    $line =~
s/^ ( \Q    Laser output power \E   \s+ : \s+ $NUM \Q mW \/ \E $LOWLIGHT \s dBm ) $/$self->_colorize($1, $RED)/exx;
    $line =~
s/^ ( \Q    Laser output power \E   \s+ : \s+ $NUM \Q mW \/ \E $LIGHT    \s dBm ) $/$self->_colorize($1, $INFO)/exx;
    $line =~
s/^ ( \Q    Laser receiver power \E \s+ : \s+ $NUM \Q mW \/ \E $LOWLIGHT \s dBm ) $/$self->_colorize($1, $RED)/exx;
    $line =~
s/^ ( \Q    Laser receiver power \E \s+ : \s+ $NUM \Q mW \/ \E $LIGHT    \s dBm ) $/$self->_colorize($1, $INFO)/exx;
    $line =~
s/^ ( \Q    Receiver signal average optical power \E \s+ : \s+ $NUM \Q mW \/ \E $LOWLIGHT \s dBm ) $/$self->_colorize($1, $RED)/exx;
    $line =~
s/^ ( \Q    Receiver signal average optical power \E \s+ : \s+ $NUM \Q mW \/ \E $LIGHT    \s dBm ) $/$self->_colorize($1, $INFO)/exx;

    return $line;
}

sub _parse_line_vyos ( $self, $line ) {

    #
    # VyOS (Stuff the Arista/Cisco commands did not do)
    #

    # BGP
    $line =~ s/^ ( \Q  BGP state = \E (?!Established) \N* ) $/$self->_colorize($1, $RED)/exx;
    $line =~
      s/^ ( \Q  BGP state = Established\E              \N* ) $/$self->_colorize($1, $GREEN)/exx;

    $line =~
s/^ ( \Q  Route map for \E (?: incoming|outgoing ) \Q advertisements is \E \N* ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( \Q  \E \S+ \Q peer-group member\E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~ s/^ ( \Q  \E $INT \Q accepted prefixes\E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    $line =~ s/^ ( \QLocal host: \E   \N+ ) $/$self->_colorize($1, $INFO)/exx;
    $line =~ s/^ ( \QForeign host: \E \N+ ) $/$self->_colorize($1, $INFO)/exx;

    return $line;
}

sub _parse_line_ciena ( $self, $line ) {

    #
    # Ciena
    #

    # Admin/Operational state for multiple commands
    $line =~
s/^ ( \| \s? \QAdmin State \E \s+ \| ) ( \s? \QEnabled \E )  ( \N+ ) $/$1.$self->_colorize($2, $GREEN).$3/exx;
    $line =~
s/^ ( \| \s? \QAdmin State \E \s+ \| ) ( \s? \QDisabled \E ) ( \N+ ) $/$1.$self->_colorize($2, $ORANGE).$3/exx;
    $line =~
s/^ ( \| \s? \QAdmin State \E \s+ \| ) ( [^|]+ )             ( \N+ ) $/$1.$self->_colorize($2, $RED).$3/exx;

    $line =~
s/^ ( \| \s? \QOperational State \E \s+ \| ) ( \s? \QUp           \E ) ( \N+ ) $/$1.$self->_colorize($2, $GREEN).$3/exx;
    $line =~
s/^ ( \| \s? \QOperational State \E \s+ \| ) ( \s? \QInitializing \E ) ( \N+ ) $/$1.$self->_colorize($2, $ORANGE).$3/exx;
    $line =~
s/^ ( \| \s? \QOperational State \E \s+ \| ) ( [^|]+ )                 ( \N+ ) $/$1.$self->_colorize($2, $RED).$3/exx;

    # xcvr show xcvr N/N
    $line =~ s/ ^ ( \| ) ( \Q Tx Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5/exx;
    $line =~ s/ ^ ( \| ) ( \Q Tx Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+ ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5/exx;

    $line =~ s/ ^ ( \| ) ( \Q Rx Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5/exx;
    $line =~ s/ ^ ( \| ) ( \Q Rx Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+ ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5/exx;

    # xcvr show xcvr status
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Tx Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Tx Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+  ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Rx Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Rx Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+  ) ( \N+ ) $/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5/exx;

    # ptp show ptp x/x [status]
    $line =~
s/^ ( \| (?: \s Transmitter)? \Q State \E \s+ \| ) ( \Q Enabled \E \s+  ) ( \| ) ( \Q Up \E|\Q Enabled \E )( \N+ ) $/
        $1.$self->_colorize($2, $GREEN).$3.$self->_colorize($4, $GREEN).$5/exx;
    $line =~
s/^ ( \| (?: \s Transmitter)? \Q State \E \s+ \| ) ( \Q Enabled \E \s+  ) ( \| ) ( [^|]+                  )( \N+ ) $/
        $1.$self->_colorize($2, $GREEN).$3.$self->_colorize($4, $RED).$5/exx;
    $line =~
s/^ ( \| (?: \s Transmitter)? \Q State \E \s+ \| ) ( \Q Disabled \E \s+ ) ( \| ) ( [^|]+                  )( \N+ ) $/
        $1.$self->_colorize($2, $ORANGE).$3.$self->_colorize($4, $ORANGE).$5/exx;

    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5.$self->_colorize($6, $RED).$7/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \| ) ( \s+ $LIGHT  \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5.$self->_colorize($6, $INFO).$7/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+  ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5.$self->_colorize($6, $RED).$7/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+  ) ( \| ) ( \s+ $LIGHT  \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5.$self->_colorize($6, $INFO).$7/exx;

    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Aggregate Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5.$self->_colorize($6, $RED).$7/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Aggregate Power (dBm)\E \s* ) ( \| ) ( \s+ $VERYLL \s+ ) ( \| ) ( \s+ $LIGHT  \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $RED).$5.$self->_colorize($6, $INFO).$7/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Aggregate Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+  ) ( \| ) ( \s+ $VERYLL \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5.$self->_colorize($6, $RED).$7/exx;
    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Actual Aggregate Power (dBm)\E \s* ) ( \| ) ( \s+ $LIGHT \s+  ) ( \| ) ( \s+ $LIGHT  \s+ ) ( \N+ )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5.$self->_colorize($6, $INFO).$7/exx;

    $line =~
s/ ^ ( \| \s+ [0-9]* \s* \| ) ( \Q Span Loss (dB)\E \s* ) ( \| ) ( \s+ $NUM \s+ ) ( \| ) ( \s+ $NUM \s+ ) ( \| )$/
        $1.$self->_colorize($2, $INFO).$3.$self->_colorize($4, $INFO).$5.$self->_colorize($6, $INFO).$7/exx;

    $line =~
s/^ ( \| \s+ \| ) ( \Q Optical Return Loss \E \( \QdB\E \) ) ( \s+ \| \s+ ) ( $GOODRETURNLOSS ) (\s+ \| ) $/
        $1.$self->_colorize($2, $GREEN).$3.$self->_colorize($4, $GREEN).$5/exx;
    $line =~
s/^ ( \| \s+ \| ) ( \Q Optical Return Loss \E \( \QdB\E \) ) ( \s+ \| \s+ ) ( $WARNRETURNLOSS ) (\s+ \| ) $/
        $1.$self->_colorize($2, $ORANGE).$3.$self->_colorize($4, $ORANGE).$5/exx;
    $line =~
s/^ ( \| \s+ \| ) ( \Q Optical Return Loss \E \( \QdB\E \) ) ( \s+ \| \s+ ) ( $BADRETURNLOSS  ) (\s+ \| ) $/
        $1.$self->_colorize($2, $RED).$3.$self->_colorize($4, $RED).$5/exx;

    # alarm show
    $line =~ s/ ^ ( \| ) ( \s* [0-9]* ) ( \| ) ( \s+ ) ( \| ) ( [^|]+ ) ( \| ) ( \s+ [0-9]+ )
                  ( \| ) ( \s* $BIGALARMS|$LITTLEALARMS \s* ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ )
                  ( \| ) ( \s+ $BIGOVERRIDES \s+ ) ( \| ) $/
        $1.$self->_colorize($2, $ORANGE).
        $3.$self->_colorize($4, $ORANGE).
        $5.$self->_colorize($6, $ORANGE).
        $7.$self->_colorize($8, $ORANGE).
        $9.$self->_colorize($10, $ORANGE).
        $11.$self->_colorize($12, $ORANGE).
        $13.$self->_colorize($14, $ORANGE).
        $15.$self->_colorize($16, $ORANGE).
        $17/exx;
    $line =~ s/ ^ ( \| ) ( \s* [0-9]* ) ( \| ) ( \s+ ) ( \| ) ( [^|]+ ) ( \| ) ( \s+ [0-9]+ )
                  ( \| ) ( \s* $BIGALARMS|$LITTLEALARMS \s* ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) $/
        $1.$self->_colorize($2, $RED).
        $3.$self->_colorize($4, $RED).
        $5.$self->_colorize($6, $RED).
        $7.$self->_colorize($8, $RED).
        $9.$self->_colorize($10, $RED).
        $11.$self->_colorize($12, $RED).
        $13.$self->_colorize($14, $RED).
        $15.$self->_colorize($16, $RED).
        $17/exx;
    $line =~
      s/ ^ ( \| ) ( \s+ [0-9]* ) ( \| ) ( \s+ \QY\E \s* ) ( \| ) ( [^|]+ ) ( \| ) ( \s+ [0-9]+ )
                  ( \| ) ( \s* $BIGALARMS \s* ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) $/
        $1.$self->_colorize($2, $ORANGE).
        $3.$self->_colorize($4, $ORANGE).
        $5.$self->_colorize($6, $ORANGE).
        $7.$self->_colorize($8, $ORANGE).
        $9.$self->_colorize($10, $ORANGE).
        $11.$self->_colorize($12, $ORANGE).
        $13.$self->_colorize($14, $ORANGE).
        $15.$self->_colorize($16, $ORANGE).
        $17/exx;
    $line =~
      s/ ^ ( \| ) ( \s+ [0-9]* ) ( \| ) ( \s+ \QY\E \s* ) ( \| ) ( [^|]+ ) ( \| ) ( \s+ [0-9]+ )
                  ( \| ) ( \s* $LITTLEALARMS \s* ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) $/
        $1.$self->_colorize($2, $INFO).
        $3.$self->_colorize($4, $INFO).
        $5.$self->_colorize($6, $INFO).
        $7.$self->_colorize($8, $INFO).
        $9.$self->_colorize($10, $INFO).
        $11.$self->_colorize($12, $INFO).
        $13.$self->_colorize($14, $INFO).
        $15.$self->_colorize($16, $INFO).
        $17/exx;

    # Errors
    $line =~ s/ ^ ( \QSHELL \E \S+ \Q FAILURE\E \N+ ) $/$self->_colorize($1, $RED)/exx;

    # ptp show
    $line =~
      s/ ^ ( \| ) ( [^|]+ ) ( \| ) ( \Q Ena \E  ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( \QUp\E \s+ ) ( \| ) ( [^|]+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) /
        $1.$self->_colorize($2, $GREEN).
        $3.$self->_colorize($4, $GREEN).
        $5.$self->_colorize($6, $GREEN).
        $7.$self->_colorize($8, $GREEN).
        $9.$self->_colorize($10, $GREEN).
        $11.$self->_colorize($12, $GREEN).
        $13.$self->_colorize($14, $GREEN).
        $15.$self->_colorize($16, $GREEN).
        $17.$self->_colorize($18, $GREEN).
        $19.$self->_colorize($20, $GREEN).
        $21.$self->_colorize($22, $GREEN).
        $23/exx;
    $line =~
      s/ ^ ( \| ) ( [^|]+ ) ( \| ) ( \Q Ena \E  ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) /
        $1.$self->_colorize($2, $RED).
        $3.$self->_colorize($4, $RED).
        $5.$self->_colorize($6, $RED).
        $7.$self->_colorize($8, $RED).
        $9.$self->_colorize($10, $RED).
        $11.$self->_colorize($12, $RED).
        $13.$self->_colorize($14, $RED).
        $15.$self->_colorize($16, $RED).
        $17.$self->_colorize($18, $RED).
        $19.$self->_colorize($20, $RED).
        $21.$self->_colorize($22, $RED).
        $23/exx;
    $line =~
      s/ ^ ( \| ) ( [^|]+ ) ( \| ) ( \Q Dis \E  ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) /
        $1.$self->_colorize($2, $ORANGE).
        $3.$self->_colorize($4, $ORANGE).
        $5.$self->_colorize($6, $ORANGE).
        $7.$self->_colorize($8, $ORANGE).
        $9.$self->_colorize($10, $ORANGE).
        $11.$self->_colorize($12, $ORANGE).
        $13.$self->_colorize($14, $ORANGE).
        $15.$self->_colorize($16, $ORANGE).
        $17.$self->_colorize($18, $ORANGE).
        $19.$self->_colorize($20, $ORANGE).
        $21.$self->_colorize($22, $ORANGE).
        $23/exx;

    # module show
    $line =~ s/ ^ ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( \Q Enabled \E \s+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( \Q Up \E           \s+ ) ( \| ) ( [^|]+ ) ( \| ) $ /
        $1.$self->_colorize($2, $GREEN).
        $3.$self->_colorize($4, $GREEN).
        $5.$self->_colorize($6, $GREEN).
        $7.$self->_colorize($8, $GREEN).
        $9.$self->_colorize($10, $GREEN).
        $11.$self->_colorize($12, $GREEN).
        $13/exx;
    $line =~ s/ ^ ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( \Q Enabled \E \s+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( \Q Initializing \E \s+ ) ( \| ) ( [^|]+ ) ( \| ) $ /
        $1.$self->_colorize($2, $ORANGE).
        $3.$self->_colorize($4, $ORANGE).
        $5.$self->_colorize($6, $ORANGE).
        $7.$self->_colorize($8, $ORANGE).
        $9.$self->_colorize($10, $ORANGE).
        $11.$self->_colorize($12, $ORANGE).
        $13/exx;
    $line =~ s/ ^ ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( \Q Enabled \E \s+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( [^|]+                  ) ( \| ) ( [^|]+ ) ( \| ) $ /
        $1.$self->_colorize($2, $RED).
        $3.$self->_colorize($4, $RED).
        $5.$self->_colorize($6, $RED).
        $7.$self->_colorize($8, $RED).
        $9.$self->_colorize($10, $RED).
        $11.$self->_colorize($12, $RED).
        $13/exx;
    $line =~ s/ ^ ( \| ) ( [^|]+ ) ( \| ) ( [^|]+ ) ( \| ) ( \Q Disabled \E \s+ )
                  ( \| ) ( [^|]+ ) ( \| ) ( [^|]+                  ) ( \| ) ( [^|]+ ) ( \| ) $ /
        $1.$self->_colorize($2, $ORANGE).
        $3.$self->_colorize($4, $ORANGE).
        $5.$self->_colorize($6, $ORANGE).
        $7.$self->_colorize($8, $ORANGE).
        $9.$self->_colorize($10, $ORANGE).
        $11.$self->_colorize($12, $ORANGE).
        $13/exx;

    # Success for dumps
    $line =~ s/^ ( \QSuccess! Preparing state dump...\E \s* ) $/ $self->_colorize($1, $GREEN)/exx;

    # Logout message
    $line =~ s/^ ( \QTerminal will be disconnected in 1 minute if it remains inactive.\E )/
        $self->_colorize($1, $RED)/exx;

    # Warning message
    $line =~ s/^ (\QWARNING:\E) / $self->_colorize($1, $ORANGE)/exx;
    $line =~ s/^ (\Q  You cannot abort the restart operation once it has started.\E ) $/
        $self->_colorize($1, $ORANGE)/exx;

    # Error messages when something isn't disabled first
    $line =~ s/^ (\QERROR: \E .* disabled ) $/ $self->_colorize($1, $RED)/exx;


    return $line;
}

sub _ipv4ify ( $self, $ip ) {
    my ( $subnet, $len ) = split "/", $ip;
    $len //= 32;

    my (@oct) = split /\./, $subnet;
    my $val   = 0;
    foreach my $i (@oct) {
        $val *= 256;
        $val += $i;
    }
    $val = $val * 256 + $len;
    my $color = $BGCOLORS[ $val % scalar(@BGCOLORS) ];
    return $self->_colorize( $ip, $color );
}

sub _ipv6ify ( $self, $ip ) {
    my ( $subnet, $len ) = split "/", $ip;
    $len //= 128;

    my ( $first, $second ) = split "::", $subnet;

    my (@fparts) = split /:/, $first;
    push( @fparts, ( '', '', '', '', '', '', '', '' ) );
    @fparts = @fparts[ 0 .. 7 ];

    my (@sparts);
    if ( defined($second) ) {
        (@sparts) = reverse split /:/, $second;
    }
    push( @sparts, ( '', '', '', '', '', '', '', '' ) );
    @sparts = reverse @sparts[ 0 .. 7 ];

    my $val = 0;
    for my $i ( 0 .. 7 ) {
        $val *= 16;
        $val += hex( $fparts[$i] . $sparts[$i] );
    }
    $val *= 32;
    $val += $len;

    my $color = $BGCOLORS[ $val % scalar(@BGCOLORS) ];
    return $self->_colorize( $ip, $color );
}

sub _numerify ( $self, $num ) {
    my $output = "";
    while ( length($num) > 3 ) {
        $output = substr( $num, -3 ) . $output;
        $num    = substr( $num, 0, length($num) - 3 );

        my $next3;
        if ( length($num) > 3 ) {
            $next3 = substr( $num, -3 );
            $num   = substr( $num, 0, length($num) - 3 );
        } else {
            $next3 = $num;
            $num   = '';
        }
        $output = $self->_highlight($next3) . $output;
    }
    $output = $num . $output;

    return $output;
}

sub _highlight ( $self, $str ) {
    return "\e[4m$str\e[24m";
}

sub _colorize ( $self, $text, $color ) {
    $text = $color . $text;
    $text =~ s/ \Q$RESET\E / $color /;
    $text = $text . $RESET;
    return $text;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::RouterColorizer - Colorize router CLI output

=head1 VERSION

version 1.231100

=head1 DESCRIPTION

This module colorizes the output of router output, using.

The output will be colorized based on detection of key strings as they
might be sent from Arista, Cisco, Juniper, and VyOS routers/switches and
Ciena WDM devices.  It may also work on other router outputs, but these
have not been used for development.

=head1 METHODS

=head2 new

  my $colorizer = App::RouterColorizer->new()

Instnatiates a new instance of C<App::RouterColorizer>.

=head2 format_text

  $colorized_text = $colorizer->format_text($text)

This method colorizes/formats the text, as provided in C<$text>.

  /usr/bin/ssh router.example.com | router-colorizer.pl

=head1 COLOR CODING

Color coding is used, which assumes a black background on your terminal.
The colors used indicate different kinds of output. Note that most lines
of output are not colorized, only "important" (as defined by me!) lines
are colorized.

=over 4

=item C<green>

Green text is used to signify "good" values. For instance, in the output
from C<show interfaces> on an Arista router, seeing lines indicating the
circuit is "up" and not showing errors will show in green.

=item C<orange>

Orange text is used to show things that aren't "good" but also aren't "bad."
For instance, administratively down interfaces in C<show interfaces status>
will typically show as orange.

=item C<red>

Red text indicates error conditions, such as errors being seen on the
output of C<show interfaces>.

=item C<cyan>

Cyan text indicates potentially important text, seperated out from text
that is not-so-important.  For instance, in C<show bgp neighbors>, cyan
is used to point out lines indicating which route map is being used.

=back

=head1 IP Address Colorization

IP addresses are also colorized.  These are colorized one of several colors,
all with a colorized background, based on the IP/CIDR address.  Thus, an
IP address like C<1.2.3.4> will always be the same color, which should make
it easier to spot potential transposition or copy mistakes (if it shows up
sometimes as white-on-blue, but other times as black-on-red, it's not the
same address!).

=head1 Number Grouping/Underlines

The progarm also underlines alternating groups of 3 digits as they appear
in digit strings.  This is used to assist people who might have dyslexia
or other visual processing differences, to allow them to quickly determine
if 1000000 is 1,000,000 or 10,000,000.

=head1 Methods

=head1 BUGS

None known, however it is certainly possible that I am less than perfect. If
you find any bug you believe has security implications, I would greatly
appreciate being notified via email sent to C<jmaslak@antelope.net> prior
to public disclosure. In the event of such notification, I will attempt to
work with you to develop a plan for fixing the bug.

All other bugs can be reported via email to C<jmaslak@antelope.net> or by
using the GitHub issue tracker
at L<https://github.com/jmaslak/App-RouterColorizer/issues>

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021-2023 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package CryoTel::CryoCon;
use warnings;
use strict;
use IO::Socket::INET;
use base 'Exporter';
our @EXPORT = qw(getcc %CryoTelFunctionsA %CryoTelFunctionsB %CryoTelFunctionsC %CryoTelFunctionsD);
our $VERSION = '0.0.6';
our $MODDATE = '07-08-09';

=head1 NAME

CryoTel::CryoCon - A module for interfacing with CryoTel Cryocontrollers via TCP

=head1 SYNOPSIS

use CryoTel::CryoCon;

=head1 REQUIRES

Only core modules required

=head1 DESCRIPTION

Function library for interfacing with CryoTel Cryocontrollers

=head1 AUTHOR/LICENSE

Perl Module CryoTel::CryoCon - Function library for interfacing with CryoTel Cryocontrollers. Copyright (C) 2009 Stanford University, Authored by Sam Kerr kerr@cpan.org

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA


=head2 Functions

1 Function and 4 hashes of functions (one for each channel) exported by default.

getcc();
%CryoTelFunctionsA
%CryoTelFunctionsB
%CryoTelFunctionsC
%CryoTelFunctionsD

 Each hash contains a code reference to getcc with supplied arguments. 1 function currently 'getCurrentTemp'. 

&{$CryoTelFunctionsA{getCurrentTempA}};


=head3 getcc() - Send CryoCon a command as an argument

$temp = getcc('input? a');

=cut


our %CryoTelFunctionsA = (
					getCurrentTemp => sub {return getcc('input? a')},
					
					);

our %CryoTelFunctionsB = (
					getCurrentTemp => sub {return getcc('input? b')},
					);

our %CryoTelFunctionsC = (
					getCurrentTemp => sub {return getcc('input? c')},
					);

our %CryoTelFunctionsD = (
					getCurrentTemp => sub {return getcc('input? d')},
					);

sub getcc{
my $arg = shift;
my $sock = IO::Socket::INET->new(PeerAddr => '192.168.0.5',
                                 PeerPort => '5000',
                                 Proto    => 'tcp',
								 Type => SOCK_STREAM)
							or
			die "Could not open socket to CryoCon, $!\n";

print $sock "$arg";

my $line = <$sock>;
print "$line\n";
close($sock);
}

__END__
Interesting ports on 192.168.0.5:
Not shown: 1714 closed ports
PORT   STATE SERVICE VERSION
80/tcp open  http?
1 service unrecognized despite returning data. If you know the service/version, please submit the following fingerprint at http://www.insecure.org/cgi-bin/servicefp-submit.cgi :
SF-Port80-TCP:V=4.68%I=7%D=7/3%Time=4A4E4EF3%P=i686-pc-linux-gnu%r(HTTPOpt
SF:ions,20,"HTTP/1\.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(RTSPRequest
SF:,20,"HTTP/1\.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(X11Probe,20,"HT
SF:TP/1\.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(RPCCheck,20,"HTTP/1\.1
SF:\x20501\x20Not\x20Implemented\r\n\r\n")%r(DNSVersionBindReq,20,"HTTP/1\
SF:.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(DNSStatusRequest,20,"HTTP/1
SF:\.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(Help,20,"HTTP/1\.1\x20501\
SF:x20Not\x20Implemented\r\n\r\n")%r(SSLSessionReq,20,"HTTP/1\.1\x20501\x2
SF:0Not\x20Implemented\r\n\r\n")%r(SMBProgNeg,20,"HTTP/1\.1\x20501\x20Not\
SF:x20Implemented\r\n\r\n")%r(LDAPBindReq,20,"HTTP/1\.1\x20501\x20Not\x20I
SF:mplemented\r\n\r\n")%r(SIPOptions,20,"HTTP/1\.1\x20501\x20Not\x20Implem
SF:ented\r\n\r\n")%r(LANDesk-RC,20,"HTTP/1\.1\x20501\x20Not\x20Implemented
SF:\r\n\r\n")%r(TerminalServer,20,"HTTP/1\.1\x20501\x20Not\x20Implemented\
SF:r\n\r\n")%r(NCP,20,"HTTP/1\.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(
SF:NotesRPC,20,"HTTP/1\.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(WMSRequ
SF:est,20,"HTTP/1\.1\x20501\x20Not\x20Implemented\r\n\r\n")%r(oracle-tns,2
SF:0,"HTTP/1\.1\x20501\x20Not\x20Implemented\r\n\r\n");
MAC Address: 00:50:C2:6F:40:E8 (Ieee Registration Authority)
No OS matches for host (If you know what OS is running on it, see http://nmap.org/submit/ ).
TCP/IP fingerprint:
OS:SCAN(V=4.68%D=7/3%OT=80%CT=1%CU=37920%PV=Y%DS=1%G=Y%M=0050C2%TM=4A4E4F17
OS:%P=i686-pc-linux-gnu)SEQ(SP=0%GCD=0%ISR=0%TI=I%II=I%SS=S%TS=U)OPS(O1=M5A
OS:0%O2=M5A0%O3=M5A0%O4=M5A0%O5=M5A0%O6=M5A0)WIN(W1=1000%W2=1000%W3=1000%W4
OS:=1000%W5=1000%W6=1000)ECN(R=Y%DF=N%T=FE%W=1000%O=M5A0%CC=N%Q=)T1(R=Y%DF=
OS:N%T=FE%S=O%A=S+%F=AS%RD=0%Q=)T2(R=Y%DF=N%T=FE%W=0%S=Z%A=O%F=R%O=%RD=0%Q=
OS:)T3(R=Y%DF=N%T=FE%W=1000%S=O%A=S+%F=AS%O=M5A0%RD=0%Q=)T4(R=N)T4(R=Y%DF=N
OS:%T=FE%W=0%S=A%A=Z%F=R%O=%RD=0%Q=)T5(R=Y%DF=N%T=FE%W=0%S=Z%A=S+%F=AR%O=%R
OS:D=0%Q=)T6(R=Y%DF=N%T=FE%W=0%S=A%A=Z%F=R%O=%RD=0%Q=)T7(R=Y%DF=N%T=FE%W=0%
OS:S=Z%A=O%F=R%O=%RD=0%Q=)U1(R=Y%DF=N%T=FA%TOS=0%IPL=38%UN=0%RIPL=G%RID=G%R
OS:IPCK=G%RUCK=G%RUL=G%RUD=G)IE(R=Y%DFI=N%T=FA%TOSI=Z%CD=2%SI=S%DLI=S)

Network Distance: 1 hop

OS and Service detection performed. Please report any incorrect results at http://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 339.239 seconds


Starting Nmap 4.68 ( http://nmap.org ) at 2009-07-03 11:36 PDT
Interesting ports on 192.168.0.5:
Not shown: 1714 closed ports
PORT   STATE SERVICE
80/tcp open  http
MAC Address: 00:50:C2:6F:40:E8 (Ieee Registration Authority)

Nmap done: 1 IP address (1 host up) scanned in 293.232 seconds


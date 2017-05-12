package Cisco::SNMP::Line;

##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use strict;
use warnings;

use Net::SNMP qw(:asn1);
use Cisco::SNMP;

our $VERSION = $Cisco::SNMP::VERSION;

our @ISA = qw(Cisco::SNMP);

##################################################
# Start Public Module
##################################################

sub _trmsrvOID {
    return '1.3.6.1.4.1.9.2.9'
}

sub _lineOID {
    return _trmsrvOID . '.2.1'
}

sub lineOIDs {
    return qw(Active Type Autobaud SpeedIn SpeedOut Flow Modem Location Term ScrLen ScrWid Esc Tmo Sestmo Rotary Uses Nses User Noise Number TimeActive)
}

sub _sessOID {
    return _trmsrvOID . '.3.1'
}

sub sessOIDs {
    return qw(Type Direction Address Name Current Idle Line)
}

sub line_clear {
    my $self  = shift;

    my $session = $self->{_SESSION_};

    my %params;
    my %args;
    if (@_ == 1) {
        ($params{lines}) = @_;
        if (!defined($params{lines} = Cisco::SNMP::_get_range($params{lines}))) {
            return undef
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?range$/i) || (/^-?line(?:s)?$/i)) {
                if (!defined($params{lines} = Cisco::SNMP::_get_range($args{$_}))) {
                    return undef
                }
            }
        }
    }

    if (!defined $params{lines}) {
        $params{lines} = Cisco::SNMP::_snmpwalk($session, _lineOID() . '.20');
        if (!defined $params{lines}) {
            $Cisco::SNMP::LASTERROR = "Cannot get lines to clear";
            return undef
        }
    }

    my @lines;
    for (@{$params{lines}}) {
        if (defined $session->set_request(_trmsrvOID . '.10.0', INTEGER, $_)) {
            push @lines, $_
        } else {
            $Cisco::SNMP::LASTERROR = "Failed to clear line $_";
            return undef
        }
    }
    return \@lines
}

sub line_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my @LINEKEYS = lineOIDs();
    for my $oid (0..$#LINEKEYS) {
        $ret{$LINEKEYS[$oid]} = Cisco::SNMP::_snmpwalk($session, _lineOID() . '.' . ($oid+1));
        if (!defined $ret{$LINEKEYS[$oid]}) {
            $Cisco::SNMP::LASTERROR = "Cannot get line `$LINEKEYS[$oid]' info";
            return undef
        }
    }

    my %LineTypes = (
        2 => 'CON',
        3 => 'TRM',
        4 => 'LNP',
        5 => 'VTY',
        6 => 'AUX'
    );
    my %LineModem = (
        2 => 'none',
        3 => 'callin',
        4 => 'callout',
        5 => 'cts-reqd',
        6 => 'ri-is-cd',
        7 => 'inout'
    );
    my %LineFlow = (
        2 => 'none',
        3 => 'sw-in',
        4 => 'sw-out',
        5 => 'sw-both',
        6 => 'hw-in',
        7 => 'hw-out',
        8 => 'hw-both'
    );
    my %LineInfo;
    for my $lines (0..$#{$ret{$LINEKEYS[19]}}) {
        my %LineInfoHash;
        for (0..$#LINEKEYS) {
            if ($_ == 1) {
                $LineInfoHash{$LINEKEYS[$_]} = exists $LineTypes{$ret{$LINEKEYS[$_]}->[$lines]} ? $LineTypes{$ret{$LINEKEYS[$_]}->[$lines]} : $ret{$LINEKEYS[$_]}->[$lines]
            } elsif ($_ == 5) {
                $LineInfoHash{$LINEKEYS[$_]} = exists $LineFlow{$ret{$LINEKEYS[$_]}->[$lines]} ? $LineFlow{$ret{$LINEKEYS[$_]}->[$lines]} : $ret{$LINEKEYS[$_]}->[$lines]
            } elsif ($_ == 6) {
                $LineInfoHash{$LINEKEYS[$_]} = exists $LineModem{$ret{$LINEKEYS[$_]}->[$lines]} ? $LineModem{$ret{$LINEKEYS[$_]}->[$lines]} : $ret{$LINEKEYS[$_]}->[$lines]
            } else {
                $LineInfoHash{$LINEKEYS[$_]} = $ret{$LINEKEYS[$_]}->[$lines]
            }
        }
        $LineInfo{$ret{$LINEKEYS[19]}->[$lines]} = \%LineInfoHash
    }
    return bless \%LineInfo, $class
}

for (lineOIDs()) {
    Cisco::SNMP::_mk_accessors_hash_1('line', $_)
}

sub line_sessions {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %ret;
    my @SESSIONKEYS = sessOIDs();
    for my $oid (0..$#SESSIONKEYS) {
        $ret{$SESSIONKEYS[$oid]} = Cisco::SNMP::_snmpwalk($session, _sessOID() . '.' . ($oid+1));
        if (!defined $ret{$SESSIONKEYS[$oid]}) {
            $Cisco::SNMP::LASTERROR = "Cannot get session `$SESSIONKEYS[$oid]' info";
            return undef
        }
    }

    my %SessionTypes = (
        1 => 'unknown',
        2 => 'PAD',
        3 => 'stream',
        4 => 'rlogin',
        5 => 'telnet',
        6 => 'TCP',
        7 => 'LAT',
        8 => 'MOP',
        9 => 'SLIP',
        10 => 'XRemote',
        11 => 'rshell'
    );
    my %SessionDir = (
        1 => 'unknown',
        2 => 'IN',
        3 => 'OUT'
    );
    my %SessionInfo;
    for my $sess (0..$#{$ret{$SESSIONKEYS[6]}}) {
        my %SessionInfoHash;
        for (0..$#SESSIONKEYS) {
            if ($_ == 0) {
                $SessionInfoHash{$SESSIONKEYS[$_]} = exists($SessionTypes{$ret{$SESSIONKEYS[$_]}->[$sess]}) ? $SessionTypes{$ret{$SESSIONKEYS[$_]}->[$sess]} : $ret{$SESSIONKEYS[$_]}->[$sess]
            } elsif ($_ == 1) {
                $SessionInfoHash{$SESSIONKEYS[$_]} = exists($SessionDir{$ret{$SESSIONKEYS[$_]}->[$sess]}) ? $SessionDir{$ret{$SESSIONKEYS[$_]}->[$sess]} : $ret{$SESSIONKEYS[$_]}->[$sess]
            } else {
                $SessionInfoHash{$SESSIONKEYS[$_]} = $ret{$SESSIONKEYS[$_]}->[$sess]
            }
        }
        push @{$SessionInfo{$ret{$SESSIONKEYS[6]}->[$sess]}}, \%SessionInfoHash
    }
    return bless \%SessionInfo, $class
}

for (sessOIDs()) {
    Cisco::SNMP::_mk_accessors_hash_2('line', 'sess', $_)
}

sub line_message {
    my $self = shift;

    my $session = $self->{_SESSION_};

    my %params = (
        message => 'Test Message.',
        lines   => [-1]
    );

    my %args;
    if (@_ == 1) {
        ($params{message}) = @_
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?message$/i) {
                $params{message} = $args{$_}
            } elsif (/^-?line(?:s)?$/i) {
                if (!defined($params{lines} = Cisco::SNMP::_get_range($args{$_}))) {
                    return undef
                }
            }
        }
    }

    my $response;
    my @lines;
    for (@{$params{lines}}) {
          # Lines
        my $response = $session->set_request(_trmsrvOID() . '.4.0', INTEGER, $_);
          # Interval (reissue)
        $response = $session->set_request(_trmsrvOID() . '.5.0', INTEGER, 0);
          # Duration
        $response = $session->set_request(_trmsrvOID() . '.6.0', INTEGER, 0);
          # Text (256 chars)
        $response = $session->set_request(_trmsrvOID() . '.7.0', OCTET_STRING, $params{message});
          # Temp Banner (1=no 2=append)
        $response = $session->set_request(_trmsrvOID() . '.8.0', INTEGER, 1);
          # Send
        $response = $session->set_request(_trmsrvOID() . '.9.0', INTEGER, 1);
        if (defined $response) {
            push @lines, $_
        } else {
            $Cisco::SNMP::LASTERROR = "Failed to send message to line $_";
            return undef
        }
    }
    # clear message
    $session->set_request(_trmsrvOID() . '.7.0', OCTET_STRING, "");
    if ($lines[0] == -1) { $lines[0] = "ALL" }
    return \@lines
}

sub line_numberof {
    my $self = shift;

    my $session = $self->{_SESSION_};

    my $response;
    if (!defined($response = $session->get_request( -varbindlist => [_trmsrvOID . '.1.0'] ))) {
        $Cisco::SNMP::LASTERROR = "Cannot get number of lines";
        return undef
    } else {
        return $response->{_trmsrvOID() . '.1.0'}
    }
}

no strict 'refs';
# get_ direct
my @OIDS = lineOIDs();
for my $o (0..$#OIDS) {
    *{"get_line" . $OIDS[$o]} = sub {
        my $self  = shift;
        my ($val) = @_;

        if (!defined $val) { $val = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_lineOID() . '.' . ($o+1) . '.' . $val]
        );
        return $r->{_lineOID() . '.' . ($o+1) . '.' . $val}
    }
}

@OIDS = sessOIDs();
for my $o (0..$#OIDS) {
    *{"get_sess" . $OIDS[$o]} = sub {
        my $self  = shift;
        my ($val1, $val2) = @_;

        if (!defined $val1) { $val1 = 0 }
        if (!defined $val2) { $val2 = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_sessOID() . '.' . ($o+1) . '.' . "$val1.$val2"]
        );
        return $r->{_sessOID() . '.' . ($o+1) . '.' . "$val1.$val2"}
    }
}

##################################################
# End Public Module
##################################################

1;

__END__

##################################################
# Start POD
##################################################

=head1 NAME

Cisco::SNMP::Line - Line Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Line;

=head1 DESCRIPTION

The following methods are for line management.  Lines on Cisco devices
refer to console, auxillary and terminal lines for user interaction.
These methods implement the C<OLD-CISCO-TS-MIB> which is not available
on some newer forms of IOS.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::Line object

  my $cm = Cisco::SNMP::Line->new([OPTIONS]);

Create a new B<Cisco::SNMP::Line> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 lineOIDs() - return OID names

  my @lineOIDs = $cm->lineOIDs();

Return list of Line MIB object ID names.

=head2 sessOIDs() - return OID names

  my @sessOIDs = $cm->sessOIDs();

Return list of Session MIB object ID names.

=head2 line_clear() - clear connection to line

  my $line = $cm->line_clear([OPTIONS]);

Clear the line (disconnect interactive session).  Called with no
arguments, clear all lines.  Called with one argument, interpreted as
the lines to clear.

  Option     Description                            Default
  ------     -----------                            -------
  -lines     Line or range of lines (, and -)       (all)

To specify individual lines, provide their number:

  my $line = $cm->line_clear(2);

Clear line 2.  To specify a range of lines, provide a range:

  my $line = $cm->line_clear('2-4,6,9-11');

Clear lines 2 3 4 6 9 10 11.

If successful, returns a pointer to an array containing the lines cleared.

=head2 line_info() - return line info

  my $lineinfo = $cm->line_info();

Populate a data structure with line information.  If successful,
returns a pointer to a hash containing line information.

  $lineinfo->{0}->{'Number', 'TimeActive', ...}
  $lineinfo->{1}->{'Number', 'TimeActive', ...}
  ...
  $lineinfo->{n}->{'Number', 'TimeActive', ...}

Allows the following accessors to be called.

=head3 lineActive() - return line active

  $lineinfo->lineActive([#]);

Return the active of the line at index '#'.  Defaults to 0.

=head3 lineType() - return line type

  $lineinfo->lineType([#]);

Return the type of the line at index '#'.  Defaults to 0.

=head3 lineAutobaud() - return line autobaud

  $lineinfo->lineAutobaud([#]);

Return the autobaud of the line at index '#'.  Defaults to 0.

=head3 lineSpeedIn() - return line speedin

  $lineinfo->lineSpeedIn([#]);

Return the speedin of the line at index '#'.  Defaults to 0.

=head3 lineSpeedOut() - return line speedout

  $lineinfo->lineSpeedOut([#]);

Return the speedout of the line at index '#'.  Defaults to 0.

=head3 lineFlow() - return line flow

  $lineinfo->lineFlow([#]);

Return the flow of the line at index '#'.  Defaults to 0.

=head3 lineModem() - return line modem

  $lineinfo->lineModem([#]);

Return the modem of the line at index '#'.  Defaults to 0.

=head3 lineLocation() - return line location

  $lineinfo->lineLocation([#]);

Return the location of the line at index '#'.  Defaults to 0.

=head3 lineTerm() - return line term

  $lineinfo->lineTerm([#]);

Return the term of the line at index '#'.  Defaults to 0.

=head3 lineScrLen() - return line scrlen

  $lineinfo->lineScrLen([#]);

Return the scrlen of the line at index '#'.  Defaults to 0.

=head3 lineScrWid() - return line scrwid

  $lineinfo->lineScrWid([#]);

Return the scrwid of the line at index '#'.  Defaults to 0.

=head3 lineEsc() - return line esc

  $lineinfo->lineEsc([#]);

Return the esc of the line at index '#'.  Defaults to 0.

=head3 lineTmo() - return line tmo

  $lineinfo->lineTmo([#]);

Return the tmo of the line at index '#'.  Defaults to 0.

=head3 lineSestmo() - return line sestmo

  $lineinfo->lineSestmo([#]);

Return the sestmo of the line at index '#'.  Defaults to 0.

=head3 lineRotary() - return line rotary

  $lineinfo->lineRotary([#]);

Return the rotary of the line at index '#'.  Defaults to 0.

=head3 lineUses() - return line uses

  $lineinfo->lineUses([#]);

Return the uses of the line at index '#'.  Defaults to 0.

=head3 lineNses() - return line number of sessions

  $lineinfo->lineNses([#]);

Return the number of sessions of the line at index '#'.  Defaults to 0.

=head3 lineUser() - return line user

  $lineinfo->lineUser([#]);

Return the user of the line at index '#'.  Defaults to 0.

=head3 lineNoise() - return line noise

  $lineinfo->lineNoise([#]);

Return the noise of the line at index '#'.  Defaults to 0.

=head3 lineNumber() - return line number

  $lineinfo->lineNumber([#]);

Return the number of the line at index '#'.  Defaults to 0.

=head3 lineTimeActive() - return line timeactive

  $lineinfo->lineTimeActive([#]);

Return the timeactive of the line at index '#'.  Defaults to 0.

=head2 line_sessions() - return session info for lines

  my $session = $cm->line_sessions();

Populate a data structure with the session information per line.  If
successful, returns a pointer to a hash containing session information.

  $sessions->{1}->[0]->{'Session', 'Type', 'Dir' ...}
                  [1]->{'Session', 'Type', 'Dir' ...}
                  ...
  ...
  $sessions->{n}->[0]->{'Session', 'Type', 'Dir' ...}

First hash value is the line number, next array is the list of current
sessions per the line number.

Allows the following accessors to be called.

=head3 sessType() - return session type

  $sessions->sessType([$line[,$sess]]);

Return the type of the session on line $line, session index $sess.  Defaults to 0.

=head3 sessDirection() - return session direction

  $sessions->sessDirection([$line[,$sess]]);

Return the direction of the session on line $line, session index $sess.  Defaults to 0.

=head3 sessAddress() - return session address

  $sessions->sessAddress([$line[,$sess]]);

Return the address of the session on line $line, session index $sess.  Defaults to 0.

=head3 sessName() - return session name

  $sessions->sessName([$line[,$sess]]);

Return the name of the session on line $line, session index $sess.  Defaults to 0.

=head3 sessCurrent() - return session current

  $sessions->sessCurrent([$line[,$sess]]);

Return the current of the session on line $line, session index $sess.  Defaults to 0.

=head3 sessIdle() - return session idle

  $sessions->sessIdle([$line[,$sess]]);

Return the idle of the session on line $line, session index $sess.  Defaults to 0.

=head3 sessLine() - return session line

  $sessions->sessLine([$line[,$sess]]);

Return the line of the session on line $line, session index $sess.  Defaults to 0.

=head2 line_message() - send message to line

  my $line = $cm->line_message([OPTIONS]);

Send a message to the line.  With no arguments, a "Test Message" is
sent to all lines.  If 1 argument is provided, interpreted as the
message to send to all lines.  Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -lines     Line or range of lines (, and -)       (all)
  -message   Double-quote delimited string          "Test Message"

If successful, returns a pointer to an array containing the lines
messaged.

=head2 line_numberof() - return number of lines

  my $line = $cm->line_numberof();

If successful, returns the number of lines on the device.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::Line> object 
directly to access the values directly.

=over 4

=item B<get_lineActive> (#)

=item B<get_lineType> (#)

=item B<get_lineAutobaud> (#)

=item B<get_lineSpeedIn> (#)

=item B<get_lineSpeedOut> (#)

=item B<get_lineFlow> (#)

=item B<get_lineModem> (#)

=item B<get_lineLocation> (#)

=item B<get_lineTerm> (#)

=item B<get_lineScrLen> (#)

=item B<get_lineScrWid> (#)

=item B<get_lineEsc> (#)

=item B<get_lineTmo> (#)

=item B<get_lineSestmo> (#)

=item B<get_lineRotary> (#)

=item B<get_lineUses> (#)

=item B<get_lineNses> (#)

=item B<get_lineUser> (#)

=item B<get_lineNoise> (#)

=item B<get_lineNumber> (#)

=item B<get_lineTimeActive> (#)

Get Line OIDs where (#) is the OID instance, not the index from 
C<line_info>.  If (#) not provided, uses 0.

=item B<get_sessType> (l,s)

=item B<get_sessDirection> (l,s)

=item B<get_sessAddress> (l,s)

=item B<get_sessName> (l,s)

=item B<get_sessCurrent> (l,s)

=item B<get_sessIdle> (l,s)

=item B<get_sessLine> (l,s)

Get Session OIDs where (l) is the OID instance of the line and (s) is the 
OID instance of the session on that line.  If (l,s) not provided, uses 0.

=back

=head1 INHERITED METHODS

The following are inherited methods.  See B<Cisco::SNMP> for more information.

=over 4

=item B<close>

=item B<error>

=item B<session>

=back

=head1 EXPORT

None by default.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
C<bin> install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut

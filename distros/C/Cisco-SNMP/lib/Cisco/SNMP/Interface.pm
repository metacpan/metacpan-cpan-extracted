package Cisco::SNMP::Interface;

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

sub _ifOID {
    return '1.3.6.1.2.1.2.2.1'
}

sub ifOIDs {
    return qw(Index Description Type MTU Speed PhysAddress AdminStatus OperStatus LastChange Duplex Name Alias)
}

sub ipOIDs {
    return qw(Addr NetMask)
}

sub ifMetricUserOIDs {
    return qw(Multicasts Broadcasts Octets Unicasts Discards Errors Unknowns)
}

sub ifMetricOIDs {
    return qw(InMulticasts OutMulticasts InBroadcasts OutBroadcasts InOctets OutOctets InUnicasts OutUnicasts InDiscards OutDiscards InErrors OutErrors InUnknowns)
}

sub _ifMetricOIDVals {
    return qw(InOctets 10 OutOctets 16 InUnicasts 11 OutUnicasts 17 InDiscards 13 OutDiscards 19 InErrors 14 OutErrors 20 InUnknowns 15)
}

sub interface_getbyindex {
    my $self = shift;

    my $session = $self->{_SESSION_};

    my $uIfx;
    my %args;
    if (@_ == 1) {
        ($uIfx) = @_;
        if ($uIfx !~ /^\d+$/) {
            $Cisco::SNMP::LASTERROR = "Invalid ifIndex `$uIfx'";
            return undef
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?interface$/i) || (/^-?index$/i)) {
                if ($args{$_} =~ /^\d+$/) {
                    $uIfx = $args{$_}
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid ifIndex `$args{$_}'";
                    return undef
                }
            }
        }
    }
    if (!defined $uIfx) {
        $Cisco::SNMP::LASTERROR = "No ifIndex provided";
        return undef
    }
    my $rIf  = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.2');
    if (!defined $rIf) {
        $Cisco::SNMP::LASTERROR = "Cannot get interface names from device";
        return undef
    }
    my $rIfx = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.1');

    for (0..$#{$rIfx}) {
        if ($rIfx->[$_] == $uIfx) {
            return $rIf->[$_]
        }
    }
    $Cisco::SNMP::LASTERROR = "Cannot get interface for ifIndex `$uIfx'";
    return undef
}

sub interface_getbyname {
    my $self = shift;

    my $session = $self->{_SESSION_};

    my %params = (
        'index' => 0
    );

    my %args;
    if (@_ == 1) {
        ($params{uIf}) = @_
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface$/i) {
                $params{uIf} = $args{$_}
            } elsif (/^-?index$/i) {
                if ($args{$_} == 1) {
                    $params{index} = 1
                }
            }
        }
    }
    if (!exists($params{uIf})) {
        $Cisco::SNMP::LASTERROR = "No interface provided";
        return undef
    }

    my $rIf  = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.2');
    if (!defined $rIf) {
        $Cisco::SNMP::LASTERROR = "Cannot get interface names from device";
        return undef
    }
    my $rIfx = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.1');

    # user Provided
    # split Gig0/1 into 'Gig' '0/1'
    my @parts = split /([0-9])/, $params{uIf}, 2;
    my $uIfNamePart =  shift @parts;
    my $uIfNumPart  =  "@parts";
       $uIfNumPart  =~ s/\s+//;

    my @matches;
    my $idx;
    for (0..$#{$rIf}) {
        # Real Names
        @parts = split /([0-9])/, $rIf->[$_], 2;
        my $rIfNamePart =  shift @parts;
        my $rIfNumPart  =  "@parts";
           $rIfNumPart  =~ s/\s+//;
        if (($rIfNamePart =~ /^$uIfNamePart/i) && ($rIfNumPart eq $uIfNumPart)) {
            push @matches, $rIf->[$_];
            $idx = $rIfx->[$_]
        }
    }
    if (@matches == 1) {
        if ($params{index} == 0) {
            return "@matches"
        } else {
            return $idx
        }
    } elsif (@matches == 0) {
        $Cisco::SNMP::LASTERROR = "Cannot find interface `$params{uIf}'";
        return undef
    } else {
        print "Interface `$params{uIf}' not specific enough - [@matches]";
        return undef
    }
}

sub interface_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %params = (
        'ifs' => [-1]
    );

    my %args;
    if (@_ == 1) {
        ($params{ifs}) = @_;
        if (!defined($params{ifs} = Cisco::SNMP::_get_range($params{ifs}))) {
            return undef
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface(?:s)?$/i) {
                if (!defined($params{ifs} = Cisco::SNMP::_get_range($args{$_}))) {
                    return undef
                }
            }
        }
    }

    my %IfInfo;
    for my $ifs (@{$params{ifs}}) {

        my $interface;
        if ($ifs == -1) {
            $interface = ''
        } else {
            $interface = '.' . $ifs
        }

        my %ret;
        my @IFKEYS = ifOIDs();
        # -3 because last key (Duplex Name Alias) are different OID
        for my $oid (0..$#IFKEYS-3) {
            $ret{$IFKEYS[$oid]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.' . ($oid+1) . $interface);
            if (!defined $ret{$IFKEYS[$oid]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFKEYS[$oid]'";
                return undef
            }
        }
        # Name Alias are different OID
        $ret{Name} = Cisco::SNMP::_snmpwalk($session, '.1.3.6.1.2.1.31.1.1.1.1' . $interface);
        $ret{Alias} = Cisco::SNMP::_snmpwalk($session, '.1.3.6.1.2.1.31.1.1.1.18' . $interface);
        # Duplex is different OID
        my $OIDS;
        ($OIDS, $ret{$IFKEYS[9]}) = Cisco::SNMP::_snmpwalk($session, '1.3.6.1.2.1.10.7.2.1.19' . $interface);
        my %duplexIfs;
        for (0..$#{$OIDS}) {
            # split the OID at dots
            my @if = split /\./, $OIDS->[$_];
            # take the last value, which is the ifIndex equal to value returned
            $duplexIfs{$if[$#if]} = $ret{$IFKEYS[9]}->[$_]
        }

        my %UpDownStatus = (
            1 => 'UP',
            2 => 'DOWN',
            3 => 'TEST',
            4 => 'UNKNOWN',
            5 => 'DORMANT',
            6 => 'NOTPRESENT',
            7 => 'LOWLAYERDOWN'
        );
        my %DuplexType = (
            1 => 'UNKNOWN',
            2 => 'HALF',
            3 => 'FULL'
        );
        for my $idx (0..$#{$ret{$IFKEYS[0]}}) {
            my %IfInfoHash;
            for (0..$#IFKEYS) {
                if ($_ == 5) {
                    $IfInfoHash{$IFKEYS[$_]} = ($ret{$IFKEYS[$_]}->[$idx] =~ /^\0/) ? unpack('H12', $ret{$IFKEYS[$_]}->[$idx]) : (($ret{$IFKEYS[$_]}->[$idx] =~ /^0x/) ? substr($ret{$IFKEYS[$_]}->[$idx],2) : $ret{$IFKEYS[$_]}->[$idx])
                } elsif (($_ == 6) || ($_ == 7)) {
                    $IfInfoHash{$IFKEYS[$_]} = exists($UpDownStatus{$ret{$IFKEYS[$_]}->[$idx]}) ? $UpDownStatus{$ret{$IFKEYS[$_]}->[$idx]} : $ret{$IFKEYS[$_]}->[$idx]
                } elsif ($_ == 9) {
                    # if $duplexIfs{ifIndex}, not necessarily the current array index
                    if (exists $duplexIfs{$ret{$IFKEYS[0]}->[$idx]}) {
                        $IfInfoHash{$IFKEYS[$_]} = exists($DuplexType{$duplexIfs{$ret{$IFKEYS[0]}->[$idx]}}) ? $DuplexType{$duplexIfs{$ret{$IFKEYS[0]}->[$idx]}} : $duplexIfs{$ret{$IFKEYS[0]}->[$idx]}
                    } else {
                        $IfInfoHash{$IFKEYS[$_]} = ''
                    }
                } else {
                    $IfInfoHash{$IFKEYS[$_]} = $ret{$IFKEYS[$_]}->[$idx]
                }
            }
            $IfInfo{$ret{$IFKEYS[0]}->[$idx]} = \%IfInfoHash
        }
    }
    return bless \%IfInfo, $class
}

for (ifOIDs()) {
    Cisco::SNMP::_mk_accessors_hash_1('if', $_)
}

sub interface_metrics {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %params = (
        'ifs' => [-1],
    );
    # assume all metrics
    my @IFMETRICUSERKEYS = ifMetricUserOIDs();
    for (@IFMETRICUSERKEYS) {
        $params{$_} = 1
    }

    my %args;
    if (@_ == 1) {
        ($params{ifs}) = @_;
        if (!defined($params{ifs} = Cisco::SNMP::_get_range($params{ifs}))) {
            return undef
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface(?:s)?$/i) {
                if (!defined($params{ifs} = Cisco::SNMP::_get_range($args{$_}))) {
                    return undef
                }
            } elsif (/^-?metric(?:s)?$/i) {
                # metrics provided - only use provided
                for (@IFMETRICUSERKEYS) {
                    $params{$_} = 0
                }
                if (ref($args{$_}) eq 'ARRAY') {
                    $params{oids} = '';
                    for my $mets (@{$args{$_}}) {
                        if (exists($params{ucfirst(lc($mets))})) {
                            $params{ucfirst(lc($mets))} = 1
                        } else {
                            $Cisco::SNMP::LASTERROR = "Invalid metric `$mets'";
                            return undef
                        }
                    }
                } else {
                    $params{oids} = '';
                    if (exists($params{ucfirst(lc($args{$_}))})) {
                        $params{ucfirst(lc($args{$_}))} = 1
                    } else {
                        $Cisco::SNMP::LASTERROR = "Invalid metric `$args{$_}'";
                        return undef
                    }
                }
            }
        }
    }

    my %IfMetric;
    my @IFMETRICKEYS = ifMetricOIDs();
    for my $ifs (@{$params{ifs}}) {

        my $interface;
        if ($ifs == -1) {
            $interface = ''
        } else {
            $interface = '.' . $ifs
        }

        my %ret;
        $ret{Index} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.1' . $interface);
        if (!defined $ret{Index}) {
            $Cisco::SNMP::LASTERROR = "Cannot get ifIndex `$interface'";
            return undef
        }
        # multicasts
        if ($params{$IFMETRICUSERKEYS[0]}) {
            # In
            $ret{$IFMETRICKEYS[0]} = Cisco::SNMP::_snmpwalk($session, '1.3.6.1.2.1.31.1.1.1.2' . $interface);
            if (!defined $ret{$IFMETRICKEYS[0]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[0]'";
                return undef
            }
            # Out
            $ret{$IFMETRICKEYS[1]} = Cisco::SNMP::_snmpwalk($session, '1.3.6.1.2.1.31.1.1.1.4' . $interface);
            if (!defined $ret{$IFMETRICKEYS[1]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[1]'";
                return undef
            }
        }
        # broadcasts
        if ($params{$IFMETRICUSERKEYS[1]}) {
            # In
            $ret{$IFMETRICKEYS[2]} = Cisco::SNMP::_snmpwalk($session, '1.3.6.1.2.1.31.1.1.1.3' . $interface);
            if (!defined $ret{$IFMETRICKEYS[2]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[2]'";
                return undef
            }
            # Out
            $ret{$IFMETRICKEYS[3]} = Cisco::SNMP::_snmpwalk($session, '1.3.6.1.2.1.31.1.1.1.5' . $interface);
            if (!defined $ret{$IFMETRICKEYS[3]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[3]'";
                return undef
            }
        }
        # octets
        if ($params{$IFMETRICUSERKEYS[2]}) {
            # In
            $ret{$IFMETRICKEYS[4]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.10' . $interface);
            if (!defined $ret{$IFMETRICKEYS[4]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[4]'";
                return undef
            }
            # Out
            $ret{$IFMETRICKEYS[5]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.16' . $interface);
            if (!defined $ret{$IFMETRICKEYS[5]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[5]'";
                return undef
            }
        }
        # unicasts
        if ($params{$IFMETRICUSERKEYS[3]}) {
            # In
            $ret{$IFMETRICKEYS[6]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.11' . $interface);
            if (!defined $ret{$IFMETRICKEYS[6]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[6]'";
                return undef
            }
            # Out
            $ret{$IFMETRICKEYS[7]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.17' . $interface);
            if (!defined $ret{$IFMETRICKEYS[7]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[7]'";
                return undef
            }
        }
        # discards
        if ($params{$IFMETRICUSERKEYS[4]}) {
            # In
            $ret{$IFMETRICKEYS[8]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.13' . $interface);
            if (!defined $ret{$IFMETRICKEYS[8]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[8]'";
                return undef
            }
            # Out
            $ret{$IFMETRICKEYS[9]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.19' . $interface);
            if (!defined $ret{$IFMETRICKEYS[9]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[9]'";
                return undef
            }
        }
        # errors
        if ($params{$IFMETRICUSERKEYS[5]}) {
            # In
            $ret{$IFMETRICKEYS[10]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.14' . $interface);
            if (!defined $ret{$IFMETRICKEYS[10]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[10]'";
                return undef
            }
            # Out
            $ret{$IFMETRICKEYS[11]} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.20' . $interface);
            if (!defined $ret{$IFMETRICKEYS[11]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[11]'";
                return undef
            }
        }
        # unknowns
        if ($params{$IFMETRICUSERKEYS[6]}) {
            # In
            $ret{$IFMETRICKEYS[12]}  = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.15' . $interface);
            if (!defined $ret{$IFMETRICKEYS[12]}) {
                $Cisco::SNMP::LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[12]'";
                return undef
            }
        }

        for my $idx (0..$#{$ret{Index}}) {
            my %IfMetricHash;
            for (0..$#IFMETRICKEYS) {
                $IfMetricHash{$IFMETRICKEYS[$_]}  = $ret{$IFMETRICKEYS[$_]}->[$idx]
            }
            $IfMetric{$ret{Index}->[$idx]} = \%IfMetricHash
        }
    }
    return bless \%IfMetric, $class
}

for (ifMetricOIDs()) {
    Cisco::SNMP::_mk_accessors_hash_1('if', $_)
}

sub interface_utilization {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %params = (
        'polling' => 10
    );

    my %args;
    if (@_ != 1) {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?polling$/i) || (/^-?interval$/i)) {
                if (($args{$_} =~ /^\d+$/) && ($args{$_} > 0)) {
                    $params{polling} = $args{$_}
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid polling interval `$args{$_}'";
                    return undef
                }
            } elsif (/^-?recursive$/i) {
                $params{recur} = $args{$_}
            }
        }
    }

    my $prev;
    if (exists($params{recur}) && (ref($params{recur}) eq __PACKAGE__)) {
        $prev = $params{recur}
    } else {
        if (!defined($prev = $self->interface_metrics(@_))) {
            $Cisco::SNMP::LASTERROR = "Cannot get initial utilization: " . $Cisco::SNMP::LASTERROR;
            return undef
        }
    }
    sleep $params{polling};
    my $curr;
    if (!defined($curr = $self->interface_metrics(@_))) {
        $Cisco::SNMP::LASTERROR = "Cannot get current utilization: " . $Cisco::SNMP::LASTERROR;
        return undef
    }

    my %IfUtil;
    my @IFMETRICKEYS = ifMetricOIDs();
    for my $ifs (sort {$a <=> $b} (keys(%{$prev}))) {
        my %IfUtilHash;
        for (0..$#IFMETRICKEYS) {
            if (($_ == 4) || ($_ == 5)) {
                $IfUtilHash{$IFMETRICKEYS[$_]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[$_]})  ? (($curr->{$ifs}->{$IFMETRICKEYS[$_]}  - $prev->{$ifs}->{$IFMETRICKEYS[$_]}) * 8) / $params{polling} : undef;
            } else {
                $IfUtilHash{$IFMETRICKEYS[$_]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[$_]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[$_]}  - $prev->{$ifs}->{$IFMETRICKEYS[$_]})      / $params{polling} : undef;
            }
        }
        $IfUtil{$ifs} = \%IfUtilHash
    }
    $prev = bless \%IfUtil, $class;
    return wantarray ? ($prev, $curr) : $prev
}

sub interface_updown {
    my $self = shift;

    my $session = $self->{_SESSION_};

    my %op     = (
        'UP'   => 1,
        'DOWN' => 2
    );
    my %params = (
        'oper' => $op{UP}
    );

    my %args;
    my $oper = 'UP';
    if (@_ == 1) {
        ($params{ifs}) = @_;
        if (!defined($params{ifs} = Cisco::SNMP::_get_range($params{ifs}))) {
            return undef
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface(?:s)?$/i) {
                if (!defined($params{ifs} = Cisco::SNMP::_get_range($args{$_}))) {
                    return undef
                }
            } elsif ((/^-?operation$/i) || (/^-?command$/i)) {
                if (exists($op{uc($args{$_})})) {
                    $params{oper} = $op{uc($args{$_})};
                    $oper = uc($args{$_})
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid operation `$args{$_}'";
                    return undef
                }
            }
        }
    }

    if (!defined $params{ifs}) {
        $params{ifs} = Cisco::SNMP::_snmpwalk($session, _ifOID() . '.1');
        if (!defined $params{ifs}) {
            $Cisco::SNMP::LASTERROR = "Cannot get interfaces to $oper";
            return undef
        }
    }

    my @intf;
    for (@{$params{ifs}}) {
        if (defined $session->set_request(_ifOID() . '.7.' . $_, INTEGER, $params{oper})) {
            push @intf, $_
        } else {
            $Cisco::SNMP::LASTERROR = "Failed to $oper interface $_";
            return undef
        }
    }
    return \@intf
}

no strict 'refs';
# get_ direct
my @OIDS = ifOIDs();
# -3 because last keys (Duplex Name Alias) are different OID
for my $o (0..$#OIDS-3) {
    *{"get_if" . $OIDS[$o]} = sub {
        my $self  = shift;
        my ($val) = @_;

        if (!defined $val) { $val = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_ifOID() . '.' . ($o+1) . '.' . $val]
        );
        return $r->{_ifOID() . '.' . ($o+1) . '.' . $val}
    }
}

sub get_ifDuplex {
    my $self  = shift;
    my ($val) = @_;

    if (!defined $val) { $val = 0 }
    my $s = $self->session;
    my $r = $s->get_request(
        varbindlist => ['1.3.6.1.2.1.10.7.2.1.19.' . $val]
    );
    return $r->{'1.3.6.1.2.1.10.7.2.1.19.' . $val}
}

sub get_ifName {
    my $self  = shift;
    my ($val) = @_;

    if (!defined $val) { $val = 0 }
    my $s = $self->session;
    my $r = $s->get_request(
        varbindlist => ['1.3.6.1.2.1.31.1.1.1.1.' . $val]
    );
    return $r->{'1.3.6.1.2.1.31.1.1.1.1.' . $val}
}

sub get_ifAlias {
    my $self  = shift;
    my ($val) = @_;

    if (!defined $val) { $val = 0 }
    my $s = $self->session;
    my $r = $s->get_request(
        varbindlist => ['1.3.6.1.2.1.31.1.1.1.18.' . $val]
    );
    return $r->{'1.3.6.1.2.1.31.1.1.1.18.' . $val}
}

my %OIDS = _ifMetricOIDVals();
for my $o (keys(%OIDS)) {
    *{"get_if" . $o} = sub {
        my $self  = shift;
        my ($val) = @_;

        if (!defined $val) { $val = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => [_ifOID() . '.' . $OIDS{$o} . '.' . $val]
        );
        return $r->{_ifOID() . '.' . $OIDS{$o} . '.' . $val}
    }
}

@OIDS = qw(InMulticasts InBroadcasts OutMulticasts OutBroadcasts);
for my $o (0..3) {
    *{"get_if" . $OIDS[$o]} = sub {
        my $self  = shift;
        my ($val) = @_;

        if (!defined $val) { $val = 0 }
        my $s = $self->session;
        my $r = $s->get_request(
            varbindlist => ['1.3.6.1.2.1.31.1.1.1.' . ($o+2) . '.' . $val]
        );
        return $r->{'1.3.6.1.2.1.31.1.1.1.' . ($o+2) . '.' . $val}
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

Cisco::SNMP::Interface - Interfaces Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Interface;

=head1 DESCRIPTION

The following methods are for interface management.  These methods
implement the C<IF-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::Interface object

  my $cm = Cisco::SNMP::Interface->new([OPTIONS]);

Create a new B<Cisco::SNMP::Interface> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

=head2 ifOIDs() - return OID names

  my @ifOIDs = $cm->ifOIDs();

Return list of Interface MIB object ID names.

=head2 ipOIDs() - return OID names

  my @ipOIDs = $cm->ipOIDs();

Return list of IP MIB object ID names.

=head2 ifMetricOIDs() - return OID names

  my @ifMetricOIDs = $cm->ifMetricOIDs();

Return list of Interface metric MIB object ID names.

=head2 ifMetricUserOIDs() - return OID names

  my @ifMetricUserOIDs = $cm->ifMetricUserOIDs();

Return list of Interface metric MIB object ID names without the 'In'/'Out' 
prefix.

=head2 interface_getbyindex() - get interface name by ifIndex

  my $interface = $cm->interface_getbyindex([OPTIONS]);

Resolve an ifIndex to the full interface name.  Called with one
argument, interpreted as the interface ifIndex to resolve.

  Option     Description                            Default
  ------     -----------                            -------
  -index     The ifIndex to resolve                 -REQUIRED-

Returns the full interface name string.

=head2 interface_getbyname() - get interface name/ifIndex by string

  my $interface = $cm->interface_getbyname([OPTIONS]);

Get the full interface name or ifIndex number by the Cisco 'shortcut'
name.  For example, 'gig0/1' or 's0/1' resolves to 'GigabitEthernet0/1'
and 'Serial0/1' respectively.  Called with one argument, interpreted
as the interface string to resolve.

  Option     Description                            Default
  ------     -----------                            -------
  -index     Return ifIndex instead (boolean)       0
  -interface String to resolve                      -REQUIRED-

Returns a string with the full interface name or ifIndex - if C<-index>
boolean flag is set.

=head2 interface_info() - return interface info

  my $ifs = $cm->interface_info([OPTIONS]);

Populate a data structure with interface information.  Called with no
arguments, populates data structure for all interfaces.  Called with
one argument, interpreted as the interface(s) to retrieve information for.

  Option     Description                            Default
  ------     -----------                            -------
  -interface ifIndex or range of ifIndex (, and -)  (all)

Interface information consists of the following MIB entries (exludes
counter-type interface metrics):

  Index
  Description
  Type
  MTU
  Speed
  PhysAddress
  AdminStatus
  OperStatus
  LastChange
  Duplex

B<NOTE:>  Duplex is found in the C<EtherLike-MIB> and thus will not
be populated for non-Ethernet interface types.

If successful, returns a pointer to a hash containing interface
information.

  $ifs->{1}->{'Index', 'Description', ...}
  $ifs->{2}->{'Index', 'Description', ...}
  ...
  $ifs->{n}->{'Index', 'Description', ...}

Allows the following accessors to be called.

=head3 ifIndex() - return interface index

  $ifs->ifIndex([#]);

Return the index of the interface at index '#'.  Defaults to 0.

=head3 ifDescription() - return interface description

  $ifs->ifDescription([#]);

Return the description of the interface at index '#'.  Defaults to 0.

=head3 ifType() - return interface type

  $ifs->ifType([#]);

Return the type of the interface at index '#'.  Defaults to 0.

=head3 ifMTU() - return interface MTU

  $ifs->ifMTU([#]);

Return the MTU of the interface at index '#'.  Defaults to 0.

=head3 ifSpeed() - return interface speed

  $ifs->ifSpeed([#]);

Return the speed of the interface at index '#'.  Defaults to 0.

=head3 ifPhysAddress() - return interface physical address

  $ifs->ifPhysAddress([#]);

Return the physical address of the interface at index '#'.  Defaults to 0.

=head3 ifAdminStatus() - return interface admin status

  $ifs->ifAdminStatus([#]);

Return the admin status of the interface at index '#'.  Defaults to 0.

=head3 ifOperStatus() - return interface operational status

  $ifs->ifOperStatus([#]);

Return the operational status of the interface at index '#'.  Defaults to 0.

=head3 ifLastChange() - return interface last change

  $ifs->ifLastChange([#]);

Return the last change of the interface at index '#'.  Defaults to 0.

=head3 ifDuplex() - return interface duplex

  $ifs->ifDuplex([#]);

Return the duplex of the interface at index '#'.  Defaults to 0.

=head3 ifName() - return interface name

  $ifs->ifName([#]);

Return the name of the interface at index '#'.  Defaults to 0.

=head3 ifAlias() - return interface alias

  $ifs->ifAlias([#]);

Return the alias of the interface at index '#'.  Defaults to 0.

=head2 interface_metrics() - return interface metrics

  my $ifs = $cm->interface_metrics([OPTIONS]);

Populate a data structure with interface metrics.

B<NOTE:>  This method only provides the counter values - do B<NOT>
confuse this with I<utilization>.  This is the raw number of "metric"
types seen since the counter was last reset.

Called with no arguments, populates data structure for all interfaces.
Called with one argument, interpreted as the interface(s) to retrieve
metrics for.

  Option     Description                            Default
  ------     -----------                            -------
  -interface ifIndex or range of ifIndex (, and -)  (all)
  -metrics   Metric or array of metrics to return   (all)
             eg:    -metrics => 'octets'
             eg:    -metrics => [octets, ...]
               (or) -metrics => \@mets

Interface metrics consist of the following MIB entries:

  Multicasts   (count of packets in/out)
  Broadcasts   (count of packets in/out)
  Octets       (count of octets  in/out)
  Unicasts     (count of packets in/out)
  Discards     (count of packets in/out)
  Errors       (count of packets in/out)
  Unknowns *   (count of packets in)

B<NOTE:>  Providing an above value for C<-metrics> returns the I<In>
and I<Out> counter for the metric; except for I<Unknowns>, which does
not have an I<Out> counter.

If successful, returns a pointer to a hash containing interface metrics.

  $ifs->{1}->{'InMulticasts', 'OutMulticasts', 'InOctets', ...}
  $ifs->{2}->{'InMulticasts', 'OutMulticasts', 'InOctets', ...}
  ...
  $ifs->{n}->{'InMulticasts', 'OutMulticasts', 'InOctets', ...}

Allows the following accessors to be called.

=head3 ifInMulticasts() - return interface InMulticasts

  $ifs->ifInMulticasts([#]);

Return the InMulticasts of the interface at index '#'.  Defaults to 0.

=head3 ifOutMulticasts() - return interface OutMulticasts

  $ifs->ifOutMulticasts([#]);

Return the OutMulticasts of the interface at index '#'.  Defaults to 0.

=head3 ifInBroadcasts() - return interface InBroadcasts

  $ifs->ifInBroadcasts([#]);

Return the InBroadcasts of the interface at index '#'.  Defaults to 0.

=head3 ifOutBroadcasts() - return interface OutBroadcasts

  $ifs->ifOutBroadcasts([#]);

Return the OutBroadcasts of the interface at index '#'.  Defaults to 0.

=head3 ifInOctets() - return interface InOctets

  $ifs->ifInOctets([#]);

Return the InOctets of the interface at index '#'.  Defaults to 0.

=head3 ifOutOctets() - return interface OutOctets

  $ifs->ifOutOctets([#]);

Return the OutOctets of the interface at index '#'.  Defaults to 0.

=head3 ifInUnicasts() - return interface InUnicasts

  $ifs->ifInUnicasts([#]);

Return the InUnicasts of the interface at index '#'.  Defaults to 0.

=head3 ifOutUnicasts() - return interface OutUnicasts

  $ifs->ifOutUnicasts([#]);

Return the OutUnicasts of the interface at index '#'.  Defaults to 0.

=head3 ifInDiscards() - return interface InDiscards

  $ifs->ifInDiscards([#]);

Return the InDiscards of the interface at index '#'.  Defaults to 0.

=head3 ifOutDiscards() - return interface OutDiscards

  $ifs->ifOutDiscards([#]);

Return the OutDiscards of the interface at index '#'.  Defaults to 0.

=head3 ifInErrors() - return interface InErrors

  $ifs->ifInErrors([#]);

Return the InErrors of the interface at index '#'.  Defaults to 0.

=head3 ifOutErrors() - return interface OutErrors

  $ifs->ifOutErrors([#]);

Return the OutErrors of the interface at index '#'.  Defaults to 0.

=head3 ifInUnknowns() - return interface InUnknowns

  $ifs->ifInUnknowns([#]);

Return the InUnknowns of the interface at index '#'.  Defaults to 0.

=head2 interface_utilization() - return interface utilization

  my $ifs = $cm->interface_utilization([OPTIONS]);

or

  my ($ifs, $recur);
  ($ifs, $recur) = $cm->interface_utilization(
      [OPTIONS]
      -recursive => $recur
  );

Populate a data structure with interface utilizations.

B<NOTE:>  This method processes the counter values described in the
C<interface_metrics> method and returns utilizations in packets or
octets per second.  This is done by retrieving the metrics, waiting
for a 'polling interval' of time, retrieving the metrics again and
finally processing the utilizations, populating and returning the
data structure.

Called with no arguments, populates data structure for all interfaces.
Called with one argument, interpreted as the interface(s) to retrieve
metrics for.

  Option     Description                            Default
  ------     -----------                            -------
  -interface ifIndex or range of ifIndex (, and -)  (all)
  -metrics   Metric or array of metrics to return   (all)
             eg:    -metrics => 'octets'
             eg:    -metrics => [octets, ...]
               (or) -metrics => \@mets
  -polling   The polling interval in seconds        10
  -recursive Variable with previous results         -none-

Interface utilizations consist of the following MIB entries:

  Multicasts   (packets/second in/out)
  Broadcasts   (packets/second in/out)
  Octets       (bits/second in/out)
  Unicasts     (packets/second in/out)
  Discards     (packets/second in/out)
  Errors       (packets/second in/out)
  Unknowns *   (packets/second in)

B<NOTE:>  Providing an above value for C<-metrics> returns the I<In>
and I<Out> utilization for the metric; except for I<Unknowns>, which
does not have an I<Out> counter.

If successful, returns a pointer to a hash containing interface
utilizations.

  $ifs->{1}->{'InMulticasts', 'OutMulticasts', 'InOctets', ...}
  $ifs->{2}->{'InMulticasts', 'OutMulticasts', 'InOctets', ...}
  ...
  $ifs->{n}->{'InMulticasts', 'OutMulticasts', 'InOctets', ...}

=head3 Notes on Interface Utilization

As previously mentioned, interface utilization is computed by retrieving
interface metrics, waiting for a 'polling interval' of time, retrieving
interface metrics again and calculating the difference (and other math
in the case of octets).  To accomplish this, the following is executed:

  User calls 'interface_utilization'

    'interface_utilization' method calls 'interface_metrics' method
    'interface_utilization' method waits for 'polling' seconds
    'interface_utilization' method calls 'interface_metrics' method
    'interface_utilization' method performs calculations and returns

  User program continues

This works well to get the interface utilization over a single polling
interval.  However, if the user program were to repeatedly obtain
interface utilization statistics (for example, using a while() loop),
this method can be improved.

Consider for example:

  my ($ifs, $recur);
  while (1) {
      ($ifs, $recur) = $cm->interface_utilization(
          -recursive => $recur
      );
      printf "%i\n", $ifs->{'1'}->{InOctets}
  }

The C<-recursive> option along with an array return value ($ifs, $recur)
allows the user to specify 2 return values:  the first is the interface
utilization statistics, the second is the interface metrics retrieved
in the C<interface_utilization> method's second call to the
C<interface_metrics> method.  Upon first execution, this value is empty
and the C<interface_utilization> method calls C<interface_metrics> twice.
However, on subsequent calls to the C<interface_utilization> method, it
skips the first call to the C<interface_metrics> method and just uses
the previously obtained metrics found in $recur.  This streamlines the
utilization calculations by saving time, bandwidth and processing power
on both the device running this script and the device under test.

To illustrate, assume we poll a device at 'T' polling intervals.  We
retrieve the metrics (M) at each interval and calculate the utilization
(U) for each interval.

  |---- T ---|---- T ---|---- T ---|
  M1         M2         M3         M4

  Utilization 1 = M2 - M1
  Utilization 2 = M3 - M2
  Utilization 3 = M4 - M3

B<WITHOUT> the C<-recursive> option, the following less efficient (but
still effective) operation occurs:

   |---- T ---||---- T ---||---- T ---|
  M1         M2M3        M4M5        M6

  Utilization 1 = M2 - M1
  Utilization 2 = M4 - M3
  Utilization 3 = M6 - M5

=head2 interface_updown() - admin up/down interface

  my $interface = $cm->interface_updown([OPTIONS]);

Admin up or down the interface.  Called with no arguments, admin up
all interfaces.  Called with one argument, interpreted as the
interface(s) to admin up.

  Option     Description                            Default
  ------     -----------                            -------
  -interface ifIndex or range of ifIndex (, and -)  (all)
  -operation 'up' or 'down'                         'up'

To specify individual interfaces, provide their number:

  my $interface = $cm->interface_updown(2);

Admin up ifIndex 2.  To specify a range of interfaces, provide a
range:

  my $interface = $cm->interface_updown(
      -operation => 'down',
      -interface => '2-4,6,9-11'
  );

Admin down ifIndex 2 3 4 6 9 10 11.

If successful, returns a pointer to an array containing the interfaces
admin up/down.

=head1 DIRECT ACCESS METHODS

The following methods can be called on the B<Cisco::SNMP::Interface> object 
directly to access the values directly.

=over 4

=item B<get_ifIndex> (#)

=item B<get_ifDescription> (#)

=item B<get_ifType> (#)

=item B<get_ifMTU> (#)

=item B<get_ifSpeed> (#)

=item B<get_ifPhysAddress> (#)

=item B<get_ifAdminStatus> (#)

=item B<get_ifOperStatus> (#)

=item B<get_ifLastChange> (#)

=item B<get_ifDuplex> (#)

=item B<get_ifName> (#)

=item B<get_ifAlias> (#)

=item B<get_ifInMulticasts> (#)

=item B<get_ifOutMulticasts> (#)

=item B<get_ifInBroadcasts> (#)

=item B<get_ifOutBroadcasts> (#)

=item B<get_ifInOctets> (#)

=item B<get_ifOutOctets> (#)

=item B<get_ifInUnicasts> (#)

=item B<get_ifOutUnicasts> (#)

=item B<get_ifInDiscards> (#)

=item B<get_ifOutDiscards> (#)

=item B<get_ifInErrors> (#)

=item B<get_ifOutErrors> (#)

=item B<get_ifInUnknowns> (#)

Get Interface OIDs where (#) is the OID instance, not the index from 
C<interface_info> or C<interface_metrics>.  If (#) not provided, uses 0.

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

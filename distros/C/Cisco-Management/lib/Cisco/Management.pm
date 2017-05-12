package Cisco::Management;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Exporter;

our $VERSION = '0.09';

use Sys::Hostname;
use Socket qw(inet_ntoa AF_INET IPPROTO_TCP);
use Net::SNMP qw(:asn1 :snmp DEBUG_ALL);
# use Net::IPv6Addr;
my $HAVE_Net_IPv6Addr = 0;
if ($Socket::VERSION >= 1.94) {
    eval "use Net::IPv6Addr 0.2";
    if(!$@) {
        $HAVE_Net_IPv6Addr = 1
    }
}

my $AF_INET6 = eval { Socket::AF_INET6() };
my $AF_UNSPEC = eval { Socket::AF_UNSPEC() };
my $AI_NUMERICHOST = eval { Socket::AI_NUMERICHOST() };
my $NI_NUMERICHOST = eval { Socket::NI_NUMERICHOST() };

our @ISA          = qw(Exporter);
our @EXPORT       = qw();
our %EXPORT_TAGS  = (
                     'password' => [qw(password_decrypt password_encrypt)],
                     'hashkeys' => [qw(@IPKEYS @IFKEYS @LINEKEYS @SESSIONKEYS @IFMETRICUSERKEYS @IFMETRICKEYS @CPUKEYS @MEMKEYS @INVENTORYKEYS)]
                    );
our @EXPORT_OK    = map {@{$EXPORT_TAGS{$_}}} keys(%EXPORT_TAGS);
$EXPORT_TAGS{ALL} = [ @EXPORT_OK ];

########################################################
# Start Variables
########################################################
# Cisco's XOR key
my @xlat = ( 0x64, 0x73, 0x66, 0x64, 0x3B, 0x6B, 0x66, 0x6F, 0x41, 0x2C,
             0x2E, 0x69, 0x79, 0x65, 0x77, 0x72, 0x6B, 0x6C, 0x64, 0x4A,
             0x4B, 0x44, 0x48, 0x53, 0x55, 0x42, 0x73, 0x67, 0x76, 0x63,
             0x61, 0x36, 0x39, 0x38, 0x33, 0x34, 0x6E, 0x63, 0x78, 0x76,
             0x39, 0x38, 0x37, 0x33, 0x32, 0x35, 0x34, 0x6B, 0x3B, 0x66,
             0x67, 0x38, 0x37
           );

our @IFKEYS      = qw(Index Description Type MTU Speed PhysAddress AdminStatus OperStatus LastChange Duplex);
our @IPKEYS      = qw(IPAddress IPMask);

our @LINEKEYS    = qw(Active Type Autobaud SpeedIn SpeedOut Flow Modem Location Term ScrLen ScrWid Esc Tmo Sestmo Rotary Uses Nses User Noise Number TimeActive);
our @SESSIONKEYS = qw(Type Direction Address Name Current Idle Line);

our @IFMETRICUSERKEYS = qw(Multicasts Broadcasts Octets Unicasts Discards Errors Unknowns);
our @IFMETRICKEYS     = qw(InMulticasts OutMulticasts InBroadcasts OutBroadcasts InOctets OutOctets InUnicasts OutUnicasts InDiscards OutDiscards InErrors OutErrors InUnknowns);

our @CPUKEYS = qw(Name 5sec 1min 5min);
our @MEMKEYS = qw(Name Alternate Valid Used Free LargestFree Total);

our @INVENTORYKEYS = qw(Descr VendorType ContainedIn Class ParentRelPos Name HardwareRev FirmwareRev SoftwareRev SerialNum MfgName ModelName Alias AssetID IsFRU);

our $LASTERROR;
########################################################
# End Variables
########################################################

########################################################
# Start Public Module
########################################################

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    my $family;
    my %params = (
        version   => 1,
        port      => 161,
        timeout   => 10
    );

    my %args;
    if (@_ == 1) {
        ($params{'hostname'}) = @_
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?port$/i) {
                $params{'port'} = $args{$_}
            } elsif (/^-?community$/i) {
                $params{'community'} = $args{$_}
            } elsif (/^-?family$/i) {
                 if ($args{$_} =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
                    if ($args{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
                        $params{'domain'} = 'udp';
                        $family = AF_INET
                    } else {
                        $params{'domain'} = 'udp6';
                        $family = $AF_INET6
                    }
                } else {
                    $LASTERROR = "Invalid family `$args{$_}'";
                    return(undef)
                }
            } elsif ((/^-?hostname$/i) || (/^-?(?:de?st|peer)?addr$/i)) {
                $params{'hostname'} = $args{$_}
            } elsif (/^-?timeout$/i) {
                $params{'timeout'} = $args{$_}
            } elsif (/^-?version$/i) {
                $params{'version'} = $args{$_}
            # pass through
            } else {
                $params{$_} = $args{$_}
            }
        }
    }

    # set default community string if not provided and SNMP version 1 or 2
    if (($params{'version'} <= 2) && !defined($params{'community'})) {
        $params{'community'} = 'private'
    }

    # hostname must be defined
    if (!defined($params{'hostname'})) {
        $params{'hostname'} = hostname
    }

    # resolve hostname our way
    if (defined(my $ret = _resolv($params{'hostname'}, $family))) {
        $params{'hostname'} = $ret->{'addr'};
        $family = $ret->{'family'};
        if ($family == AF_INET) {
            $params{'domain'} = 'udp'
        } else {
            $params{'domain'} = 'udp6'
        }
    } else {
        return undef
    }

    my ($session, $error) = Net::SNMP->session(%params);

    if (!defined($session)) {
        $LASTERROR = "Error creating Net::SNMP object: $error";
        return(undef)
    }

    return bless {
                  %params,       # merge user parameters
                  'family' => $family,
                  '_SESSION_' => $session
                 }, $class
}

sub session {
    my $self = shift;
    return $self->{'_SESSION_'}
}

sub config_copy {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my $cc;
    foreach my $key (keys(%{$self})) {
        # everything but '_xxx_'
        $key =~ /^\_.+\_$/ and next;
        $cc->{$key} = $self->{$key}
    }

    my %params = (
        op         => 'wr',
        catos      => 0,
        timeout    => 10,
        source     => 4,
        dest       => 3
    );

    my %args;
    if (@_ == 1) {
        $LASTERROR = "Insufficient number of args";
        return(undef)
    } else {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?(?:tftp)?server$/i) || (/^-?tftp$/)) {
                $params{'tftpserver'} = $args{$_}
            } elsif (/^-?catos$/i) {
                if ($args{$_} == 1) {
                    $params{'catos'} = 1
                }
            } elsif (/^-?timeout$/i) {
                $params{'timeout'} = $args{$_}
            } elsif (/^-?family$/i) {
                 if ($args{$_} =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
                    if ($args{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
                        $params{'family'} = AF_INET
                    } else {
                        $params{'family'} = $AF_INET6
                    }
                } else {
                    $LASTERROR = "Invalid family `$args{$_}'";
                    return(undef)
                }
            } elsif (/^-?source$/i) {
                if ($args{$_} =~ /^run(?:ning)?(?:-config)?$/i) {
                    $params{'source'} = 4
                } elsif ($args{$_} =~ /^start(?:up)?(?:-config)?$/i) {
                    $params{'source'} = 3
                } else {
                    $params{'source'} = 1;
                    $params{'op'}     = 'put';
                    $params{'file'}   = $args{$_}
                }
            } elsif (/^-?dest(?:ination)?$/i) {
                if ($args{$_} =~ /^run(?:ning)?(?:-config)?$/i) {
                    $params{'dest'} = 4
                } elsif ($args{$_} =~ /^start(?:up)?(?:-config)?$/i) {
                    $params{'dest'} = 3
                } else {
                    $params{'dest'} = 1;
                    $params{'op'}   = 'get';
                    $params{'file'} = $args{$_}
                }
            }
        }
    }
    $cc->{'_CONFIGCOPY_'}{'_params_'} = \%params;

    if ($params{'source'} == $params{'dest'}) {
        $LASTERROR = "Source and destination cannot be same";
        return(undef)
    }

    # tftpserver must be defined if put/get
    if (($params{'op'} ne "wr") && !defined($params{'tftpserver'})) {
        $params{'tftpserver'} = hostname
    }

    # inherit from new()
    if (!defined($params{'family'})) {
        $params{'family'} = $self->{'family'};
    }

    # resolve tftpserver our way
    if (defined($params{'tftpserver'})) {
        if (defined(my $ret = _resolv($params{'tftpserver'}, $params{'family'}))) {
            $params{'tftpserver'} = $ret->{'addr'};
            $params{'family'}     = $ret->{'family'}
        } else {
            return undef
        }
        if ($params{'catos'} && ($params{'family'} == $AF_INET6)) {
            $LASTERROR = "CatOS does not support IPv6";
            return undef
        }
    }

    my $response;
    my $instance = int(rand(1024)+1024);
    my %ioserr = (
        1 => "Unknown",
        2 => "Bad file name",
        3 => "Timeout",
        4 => "No memory",
        5 => "No config",
        6 => "Unsupported protocol",
        7 => "Config apply fail",
        8 => "System not ready",
        9 => "Request abort"
    );

    # wr mem
    if ($params{'op'} eq 'wr') {
        if ($params{'catos'}) {
            $LASTERROR = "CatOS does not support `copy run start'";
            return(undef)
        }
        # ccCopyEntryRowStatus (5 = createAndWait, 6 = destroy)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);

        if (!defined($response)) {
            $LASTERROR = "`copy run start' NOT SUPPORTED - trying old way";
            $response = $session->set_request('1.3.6.1.4.1.9.2.1.54.0', INTEGER, 1);
            if (defined($response)) {
                return bless $cc, $class
            } else {
                $LASTERROR = "`copy run start' FAILED (new and old)";
                return(undef)
            }
        }

          # ccCopySourceFileType (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.3.' . $instance, INTEGER, $params{'source'});
          # ccCopyDestFileType (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.4.' . $instance, INTEGER, $params{'dest'})

    # TFTP PUT/GET (to/from device)
    } else {
        $response = _config_copy(\%params, $session, $instance);
        if ($response == 0) {
            return bless $cc, $class
        } elsif ($response == -1) {
            return(undef)
        }
        # $response == 1, continue ...
    }

    # ccCopyEntryRowStatus (4 = createAndGo, 6 = destroy)
    $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 1);

    # Check status, wait done
    $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance);
    if (!defined($response)) {
        $LASTERROR = "tftp NOT SUPPORTED (after setup)";
        return(undef)
    }

    # loop and check response - error if timeout
    my $loop = 0;
    while ($response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance} <= 2) {
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance);
        if (!defined($response)) {
            $LASTERROR = "IOS TFTP `$params{'op'}' FAILED - cannot verify completion";
            return(undef)
        }
        if ($loop++ == $params{'timeout'}) {
            $LASTERROR = "IOS TFTP `$params{'op'}' FAILED - timeout during completion verification";
            return(undef)
        }
        sleep 1
    }

    # Success
    if ($response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance} == 3) {
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.11.' . $instance);
        $cc->{'_CONFIGCOPY_'}{'StartTime'} = $response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.11.' . $instance};
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.12.' . $instance);
        $cc->{'_CONFIGCOPY_'}{'EndTime'}   = $response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.12.' . $instance};
        $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);
        return bless $cc, $class
    # Error
    } elsif ($response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance} == 4) {
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.13.' . $instance);
        $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);
        $LASTERROR = "IOS TFTP `$params{'op'}' FAILED - " . $ioserr{$response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.13.' . $instance}};
        return(undef)
    } else {
        $LASTERROR = "Cannot determine success or failure";
        return(undef)
    }
}

sub config_copy_starttime {
    my $self = shift;
    return $self->{'_CONFIGCOPY_'}{'StartTime'}
}

sub config_copy_endtime {
    my $self = shift;
    return $self->{'_CONFIGCOPY_'}{'EndTime'}
}

sub cpu_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my ($type, $cpu5min);
    # IOS releases < 12.0(3)T
    if (($cpu5min = &_snmpgetnext($session,"1.3.6.1.4.1.9.2.1.58")) && (defined($cpu5min->[0]))) {
        $type = 1
    # 12.0(3)T < IOS releases < 12.2(3.5)
    } elsif (($cpu5min = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.5")) && (defined($cpu5min->[0]))) {
        $type = 2
    # IOS releases > 12.2(3.5)
    } elsif (($cpu5min = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.8")) && (defined($cpu5min->[0]))) {
        $type = 3
    } else {
        $LASTERROR = "Cannot determine CPU type";
        return(undef)
    }

    my %cpuType = (
        1 => 'IOS releases < 12.0(3)T',
        2 => '12.0(3)T < IOS releases < 12.2(3.5)',
        3 => 'IOS releases > 12.2(3.5)'
    );

    my @cpuName;
    # Get multiple CPU names
    if ($type > 1) {
        my $temp = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.2");
        for (0..$#{$temp}) {
            if (defined(my $result = $session->get_request( -varbindlist => ['1.3.6.1.2.1.47.1.1.1.1.7.' . $temp->[$_]] ))) {
                $cpuName[$_] = $result->{'1.3.6.1.2.1.47.1.1.1.1.7.' . $temp->[$_]}
            } else {
                $LASTERROR = "Cannot get CPU name for type `$cpuType{$type}'";
                return(undef)
            }
        }
    }

    my ($cpu5sec, $cpu1min);
    if ($type == 1) {
        $cpu5min = &_snmpgetnext($session,"1.3.6.1.4.1.9.2.1.58");
        $cpu5sec = &_snmpgetnext($session,"1.3.6.1.4.1.9.2.1.56");
        $cpu1min = &_snmpgetnext($session,"1.3.6.1.4.1.9.2.1.57")
    } elsif ($type == 2) {
        $cpu5min = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.5");
        $cpu5sec = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.3");
        $cpu1min = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.4")
    } elsif ($type == 3) {
        $cpu5min = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.8");
        $cpu5sec = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.6");
        $cpu1min = &_snmpgetnext($session,"1.3.6.1.4.1.9.9.109.1.1.1.1.7")
    } else { }

    my @CPUInfo;
    for my $cpu (0..$#{$cpu5min}) {
        my %CPUInfoHash;
        $CPUInfoHash{'Name'}   = $cpuName[$cpu];
        $CPUInfoHash{'5sec'}   = $cpu5sec->[$cpu];
        $CPUInfoHash{'1min'}   = $cpu1min->[$cpu];
        $CPUInfoHash{'5min'}   = $cpu5min->[$cpu];
        $CPUInfoHash{'_type_'} = $cpuType{$type};
        push @CPUInfo, \%CPUInfoHash
    }
    return \@CPUInfo
}

sub interface_getbyindex {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my $uIfx;
    my %args;
    if (@_ == 1) {
        ($uIfx) = @_;
        if ($uIfx !~ /^\d+$/) {
            $LASTERROR = "Invalid ifIndex `$uIfx'";
            return(undef)
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?interface$/i) || (/^-?index$/i)) {
                if ($args{$_} =~ /^\d+$/) {
                    $uIfx = $args{$_}
                } else {
                    $LASTERROR = "Invalid ifIndex `$args{$_}'";
                    return(undef)
                }
            }
        }
    }
    if (!defined($uIfx)) {
        $LASTERROR = "No ifIndex provided";
        return(undef)
    }
    my $rIf  = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.2');
    if (!defined($rIf)) {
        $LASTERROR = "Cannot get interface names from device";
        return(undef)
    }
    my $rIfx = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.1');

    for (0..$#{$rIfx}) {
        if ($rIfx->[$_] == $uIfx) {
            return $rIf->[$_]
        }
    }
    $LASTERROR = "Cannot get interface for ifIndex `$uIfx'";
    return(undef)
}

sub interface_getbyname {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %params = (
        'index' => 0
    );

    my %args;
    if (@_ == 1) {
        ($params{'uIf'}) = @_;
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface$/i) {
                $params{'uIf'} = $args{$_}
            } elsif (/^-?index$/i) {
                if ($args{$_} == 1) {
                    $params{'index'} = 1
                }
            }
        }
    }
    if (!exists($params{'uIf'})) {
        $LASTERROR = "No interface provided";
        return(undef)
    }

    my $rIf  = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.2');
    if (!defined($rIf)) {
        $LASTERROR = "Cannot get interface names from device";
        return(undef)
    }
    my $rIfx = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.1');

    # user Provided
    my @parts = split /([0-9])/, $params{'uIf'}, 2;
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
        if ($params{'index'} == 0) {
            return "@matches"
        } else {
            return $idx
        }
    } elsif (@matches == 0) {
        $LASTERROR = "Cannot find interface `$params{'uIf'}'";
        return(undef)
    } else {
        print "Interface `$params{'uIf'}' not specific enough - [@matches]";
        return(undef)
    }
}

sub interface_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %params = (
        'ifs' => [-1]
    );

    my %args;
    if (@_ == 1) {
        ($params{'ifs'}) = @_;
        if (!defined($params{'ifs'} = _get_range($params{'ifs'}))) {
            return(undef)
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface(?:s)?$/i) {
                if (!defined($params{'ifs'} = _get_range($args{$_}))) {
                    return(undef)
                }
            }
        }
    }

    my %IfInfo;
    for my $ifs (@{$params{'ifs'}}) {

        my $interface;
        if ($ifs == -1) {
            $interface = ''
        } else {
            $interface = '.' . $ifs
        }

        my %ret;
        for my $oid (1..$#IFKEYS) {
            $ret{$IFKEYS[$oid-1]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.' . $oid . $interface);
            if (!defined($ret{$IFKEYS[$oid-1]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFKEYS[$oid-1]'";
                return(undef)
            }
        }
        # Duplex is different OID
        my $OIDS;
        ($OIDS, $ret{$IFKEYS[9]}) = &_snmpgetnext($session, '1.3.6.1.2.1.10.7.2.1.19' . $interface);
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
            $IfInfoHash{$IFKEYS[0]} = $ret{$IFKEYS[0]}->[$idx];
            $IfInfoHash{$IFKEYS[1]} = $ret{$IFKEYS[1]}->[$idx];
            $IfInfoHash{$IFKEYS[2]} = $ret{$IFKEYS[2]}->[$idx];
            $IfInfoHash{$IFKEYS[3]} = $ret{$IFKEYS[3]}->[$idx];
            $IfInfoHash{$IFKEYS[4]} = $ret{$IFKEYS[4]}->[$idx];
            $IfInfoHash{$IFKEYS[5]} = ($ret{$IFKEYS[5]}->[$idx] =~ /^\0/) ? unpack('H12', $ret{$IFKEYS[5]}->[$idx]) : (($ret{$IFKEYS[5]}->[$idx] =~ /^0x/) ? substr($ret{$IFKEYS[5]}->[$idx],2) : $ret{$IFKEYS[5]}->[$idx]);
            $IfInfoHash{$IFKEYS[6]} = exists($UpDownStatus{$ret{$IFKEYS[6]}->[$idx]}) ? $UpDownStatus{$ret{$IFKEYS[6]}->[$idx]} : $ret{$IFKEYS[6]}->[$idx];
            $IfInfoHash{$IFKEYS[7]} = exists($UpDownStatus{$ret{$IFKEYS[7]}->[$idx]}) ? $UpDownStatus{$ret{$IFKEYS[7]}->[$idx]} : $ret{$IFKEYS[7]}->[$idx];
            $IfInfoHash{$IFKEYS[8]} = $ret{$IFKEYS[8]}->[$idx];
            # if $duplexIfs{ifIndex}, not necessarily the current array index
            if (exists $duplexIfs{$ret{$IFKEYS[0]}->[$idx]}) {
                $IfInfoHash{$IFKEYS[9]} = exists($DuplexType{$duplexIfs{$ret{$IFKEYS[0]}->[$idx]}}) ? $DuplexType{$duplexIfs{$ret{$IFKEYS[0]}->[$idx]}} : $duplexIfs{$ret{$IFKEYS[0]}->[$idx]}
            } else {
                $IfInfoHash{$IFKEYS[9]} = ''
            }
            $IfInfo{$ret{$IFKEYS[0]}->[$idx]} = \%IfInfoHash
        }
    }
    return bless \%IfInfo, $class
}

sub interface_ip {
    my ($self, $arg) = @_;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    # IP Info
    my $IPIndex   = &_snmpgetnext($session, '1.3.6.1.2.1.4.20.1.2');
    if (!defined($IPIndex)) {
        $LASTERROR = "Cannot get interface IP info";
        return(undef)
    }
    my %ret;
    $ret{$IPKEYS[0]} = &_snmpgetnext($session, '1.3.6.1.2.1.4.20.1.1');
    $ret{$IPKEYS[1]} = &_snmpgetnext($session, '1.3.6.1.2.1.4.20.1.3');

    my %mask = (
        "0.0.0.0"         => 0,  "128.0.0.0"       => 1,  "192.0.0.0"       => 2,
        "224.0.0.0"       => 3,  "240.0.0.0"       => 4,  "248.0.0.0"       => 5,
        "252.0.0.0"       => 6,  "254.0.0.0"       => 7,  "255.0.0.0"       => 8,
        "255.128.0.0"     => 9,  "255.192.0.0"     => 10, "255.224.0.0"     => 11,
        "255.240.0.0"     => 12, "255.248.0.0"     => 13, "255.252.0.0"     => 14,
        "255.254.0.0"     => 15, "255.255.0.0"     => 16, "255.255.128.0"   => 17,
        "255.255.192.0"   => 18, "255.255.224.0"   => 19, "255.255.240.0"   => 20,
        "255.255.248.0"   => 21, "255.255.252.0"   => 22, "255.255.254.0"   => 23,
        "255.255.255.0"   => 24, "255.255.255.128" => 25, "255.255.255.192" => 26,
        "255.255.255.224" => 27, "255.255.255.240" => 28, "255.255.255.248" => 29,
        "255.255.255.252" => 30, "255.255.255.254" => 31, "255.255.255.255" => 32
    );

    my %IPInfo;
    for (0..$#{$IPIndex}) {
        my %IPInfoHash;
        $IPInfoHash{$IPKEYS[0]} = $ret{$IPKEYS[0]}->[$_];
        if (defined($arg) && ($arg >= 1)) {
            $IPInfoHash{$IPKEYS[1]} = $mask{$ret{$IPKEYS[1]}->[$_]}
        } else {
            $IPInfoHash{$IPKEYS[1]} = $ret{$IPKEYS[1]}->[$_]
        }
        push @{$IPInfo{$IPIndex->[$_]}}, \%IPInfoHash
    }
    return bless \%IPInfo, $class
}

sub interface_metrics {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %params = (
        'ifs' => [-1],
    );
    # assume all metrics
    for (@IFMETRICUSERKEYS) {
        $params{$_} = 1
    }

    my %args;
    if (@_ == 1) {
        ($params{'ifs'}) = @_;
        if (!defined($params{'ifs'} = _get_range($params{'ifs'}))) {
            return(undef)
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface(?:s)?$/i) {
                if (!defined($params{'ifs'} = _get_range($args{$_}))) {
                    return(undef)
                }
            } elsif (/^-?metric(?:s)?$/i) {
                # metrics provided - only use provided
                for (@IFMETRICUSERKEYS) {
                    $params{$_} = 0
                }
                if (ref($args{$_}) eq 'ARRAY') {
                    $params{'oids'} = '';
                    for my $mets (@{$args{$_}}) {
                        if (exists($params{ucfirst(lc($mets))})) {
                            $params{ucfirst(lc($mets))} = 1
                        } else {
                            $LASTERROR = "Invalid metric `$mets'";
                            return(undef)
                        }
                    }
                } else {
                    $params{'oids'} = '';
                    if (exists($params{ucfirst(lc($args{$_}))})) {
                        $params{ucfirst(lc($args{$_}))} = 1
                    } else {
                        $LASTERROR = "Invalid metric `$args{$_}'";
                        return(undef)
                    }
                }
            }
        }
    }

    my %IfMetric;
    for my $ifs (@{$params{'ifs'}}) {

        my $interface;
        if ($ifs == -1) {
            $interface = ''
        } else {
            $interface = '.' . $ifs
        }

        my %ret;
        $ret{'Index'} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.1' . $interface);
        if (!defined($ret{'Index'})) {
            $LASTERROR = "Cannot get ifIndex `$interface'";
            return(undef)
        }
        # multicasts
        if ($params{$IFMETRICUSERKEYS[0]}) {
            # In
            $ret{$IFMETRICKEYS[0]} = &_snmpgetnext($session, '1.3.6.1.2.1.31.1.1.1.2' . $interface);
            if (!defined($ret{$IFMETRICKEYS[0]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[0]'";
                return(undef)
            }
            # Out
            $ret{$IFMETRICKEYS[1]} = &_snmpgetnext($session, '1.3.6.1.2.1.31.1.1.1.4' . $interface);
            if (!defined($ret{$IFMETRICKEYS[1]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[1]'";
                return(undef)
            }
        }
        # broadcasts
        if ($params{$IFMETRICUSERKEYS[1]}) {
            # In
            $ret{$IFMETRICKEYS[2]} = &_snmpgetnext($session, '1.3.6.1.2.1.31.1.1.1.3' . $interface);
            if (!defined($ret{$IFMETRICKEYS[2]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[2]'";
                return(undef)
            }
            # Out
            $ret{$IFMETRICKEYS[3]} = &_snmpgetnext($session, '1.3.6.1.2.1.31.1.1.1.5' . $interface);
            if (!defined($ret{$IFMETRICKEYS[3]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[3]'";
                return(undef)
            }
        }
        # octets
        if ($params{$IFMETRICUSERKEYS[2]}) {
            # In
            $ret{$IFMETRICKEYS[4]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.10' . $interface);
            if (!defined($ret{$IFMETRICKEYS[4]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[4]'";
                return(undef)
            }
            # Out
            $ret{$IFMETRICKEYS[5]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.16' . $interface);
            if (!defined($ret{$IFMETRICKEYS[5]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[5]'";
                return(undef)
            }
        }
        # unicasts
        if ($params{$IFMETRICUSERKEYS[3]}) {
            # In
            $ret{$IFMETRICKEYS[6]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.11' . $interface);
            if (!defined($ret{$IFMETRICKEYS[6]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[6]'";
                return(undef)
            }
            # Out
            $ret{$IFMETRICKEYS[7]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.17' . $interface);
            if (!defined($ret{$IFMETRICKEYS[7]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[7]'";
                return(undef)
            }
        }
        # discards
        if ($params{$IFMETRICUSERKEYS[4]}) {
            # In
            $ret{$IFMETRICKEYS[8]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.13' . $interface);
            if (!defined($ret{$IFMETRICKEYS[8]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[8]'";
                return(undef)
            }
            # Out
            $ret{$IFMETRICKEYS[9]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.19' . $interface);
            if (!defined($ret{$IFMETRICKEYS[9]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[9]'";
                return(undef)
            }
        }
        # errors
        if ($params{$IFMETRICUSERKEYS[5]}) {
            # In
            $ret{$IFMETRICKEYS[10]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.14' . $interface);
            if (!defined($ret{$IFMETRICKEYS[10]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[10]'";
                return(undef)
            }
            # Out
            $ret{$IFMETRICKEYS[11]} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.20' . $interface);
            if (!defined($ret{$IFMETRICKEYS[11]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[11]'";
                return(undef)
            }
        }
        # unknowns
        if ($params{$IFMETRICUSERKEYS[6]}) {
            # In
            $ret{$IFMETRICKEYS[12]}  = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.15' . $interface);
            if (!defined($ret{$IFMETRICKEYS[12]})) {
                $LASTERROR = "Cannot get interface `$interface' `$IFMETRICKEYS[12]'";
                return(undef)
            }
        }

        for my $idx (0..$#{$ret{'Index'}}) {
            my %IfMetricHash;
            $IfMetricHash{$IFMETRICKEYS[0]}  = $ret{$IFMETRICKEYS[0]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[1]}  = $ret{$IFMETRICKEYS[1]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[2]}  = $ret{$IFMETRICKEYS[2]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[3]}  = $ret{$IFMETRICKEYS[3]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[4]}  = $ret{$IFMETRICKEYS[4]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[5]}  = $ret{$IFMETRICKEYS[5]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[6]}  = $ret{$IFMETRICKEYS[6]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[7]}  = $ret{$IFMETRICKEYS[7]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[8]}  = $ret{$IFMETRICKEYS[8]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[9]}  = $ret{$IFMETRICKEYS[9]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[10]} = $ret{$IFMETRICKEYS[10]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[11]} = $ret{$IFMETRICKEYS[11]}->[$idx];
            $IfMetricHash{$IFMETRICKEYS[12]} = $ret{$IFMETRICKEYS[12]}->[$idx];
            $IfMetric{$ret{'Index'}->[$idx]} = \%IfMetricHash
        }
    }
    return bless \%IfMetric, $class
}

sub interface_utilization {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %params = (
        'polling' => 10
    );

    my %args;
    if (@_ != 1) {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?polling$/i) || (/^-?interval$/i)) {
                if (($args{$_} =~ /^\d+$/) && ($args{$_} > 0)) {
                    $params{'polling'} = $args{$_}
                } else {
                    $LASTERROR = "Invalid polling interval `$args{$_}'";
                    return(undef)
                }
            } elsif (/^-?recursive$/i) {
                $params{'recur'} = $args{$_}
            }
        }
    }

    my $prev;
    if (exists($params{'recur'}) && (ref($params{'recur'}) eq __PACKAGE__)) {
        $prev = $params{'recur'}
    } else {
        if (!defined($prev = $self->interface_metrics(@_))) {
            $LASTERROR = "Cannot get initial utilization: " . $LASTERROR;
            return(undef)
        }
    }
    sleep $params{'polling'};
    my $curr;
    if (!defined($curr = $self->interface_metrics(@_))) {
        $LASTERROR = "Cannot get current utilization: " . $LASTERROR;
        return(undef)
    }

    my %IfUtil;
    for my $ifs (sort {$a <=> $b} (keys(%{$prev}))) {
        my %IfUtilHash;
        $IfUtilHash{$IFMETRICKEYS[0]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[0]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[0]}  - $prev->{$ifs}->{$IFMETRICKEYS[0]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[1]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[1]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[1]}  - $prev->{$ifs}->{$IFMETRICKEYS[1]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[2]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[2]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[2]}  - $prev->{$ifs}->{$IFMETRICKEYS[2]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[3]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[3]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[3]}  - $prev->{$ifs}->{$IFMETRICKEYS[3]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[4]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[4]})  ? (($curr->{$ifs}->{$IFMETRICKEYS[4]}  - $prev->{$ifs}->{$IFMETRICKEYS[4]}) * 8) / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[5]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[5]})  ? (($curr->{$ifs}->{$IFMETRICKEYS[5]}  - $prev->{$ifs}->{$IFMETRICKEYS[5]}) * 8) / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[6]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[6]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[6]}  - $prev->{$ifs}->{$IFMETRICKEYS[6]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[7]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[7]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[7]}  - $prev->{$ifs}->{$IFMETRICKEYS[7]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[8]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[8]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[8]}  - $prev->{$ifs}->{$IFMETRICKEYS[8]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[9]}  = defined($curr->{$ifs}->{$IFMETRICKEYS[9]})  ?  ($curr->{$ifs}->{$IFMETRICKEYS[9]}  - $prev->{$ifs}->{$IFMETRICKEYS[9]})      / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[10]} = defined($curr->{$ifs}->{$IFMETRICKEYS[10]}) ?  ($curr->{$ifs}->{$IFMETRICKEYS[10]} - $prev->{$ifs}->{$IFMETRICKEYS[10]})     / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[11]} = defined($curr->{$ifs}->{$IFMETRICKEYS[11]}) ?  ($curr->{$ifs}->{$IFMETRICKEYS[11]} - $prev->{$ifs}->{$IFMETRICKEYS[11]})     / $params{'polling'} : undef;
        $IfUtilHash{$IFMETRICKEYS[12]} = defined($curr->{$ifs}->{$IFMETRICKEYS[12]}) ?  ($curr->{$ifs}->{$IFMETRICKEYS[12]} - $prev->{$ifs}->{$IFMETRICKEYS[12]})     / $params{'polling'} : undef;
        $IfUtil{$ifs} = \%IfUtilHash
    }
    $prev = bless \%IfUtil, $class;
    return wantarray ? ($prev, $curr) : $prev
}

sub interface_updown {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %op     = (
        'UP'   => 1,
        'DOWN' => 2
    );
    my %params = (
        'oper' => $op{'UP'}
    );

    my %args;
    my $oper = 'UP';
    if (@_ == 1) {
        ($params{'ifs'}) = @_;
        if (!defined($params{'ifs'} = _get_range($params{'ifs'}))) {
            return(undef)
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?interface(?:s)?$/i) {
                if (!defined($params{'ifs'} = _get_range($args{$_}))) {
                    return(undef)
                }
            } elsif ((/^-?operation$/i) || (/^-?command$/i)) {
                if (exists($op{uc($args{$_})})) {
                    $params{'oper'} = $op{uc($args{$_})};
                    $oper = uc($args{$_})
                } else {
                    $LASTERROR = "Invalid operation `$args{$_}'";
                    return(undef)
                }
            }
        }
    }

    if (!defined($params{'ifs'})) {
        $params{'ifs'} = &_snmpgetnext($session, '1.3.6.1.2.1.2.2.1.1');
        if (!defined($params{'ifs'})) {
            $LASTERROR = "Cannot get interfaces to $oper";
            return(undef)
        }
    }

    my @intf;
    for (@{$params{'ifs'}}) {
        if (defined($session->set_request('1.3.6.1.2.1.2.2.1.7.' . $_, INTEGER, $params{'oper'}))) {
            push @intf, $_
        } else {
            $LASTERROR = "Failed to $oper interface $_";
            return(undef)
        }
    }
    return \@intf
}

sub line_clear {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %params;
    my %args;
    if (@_ == 1) {
        ($params{'lines'}) = @_;
        if (!defined($params{'lines'} = _get_range($params{'lines'}))) {
            return(undef)
        }
    } else {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?range$/i) || (/^-?line(?:s)?$/i)) {
                if (!defined($params{'lines'} = _get_range($args{$_}))) {
                    return(undef)
                }
            }
        }
    }

    if (!defined($params{'lines'})) {
        $params{'lines'} = &_snmpgetnext($session, '1.3.6.1.4.1.9.2.9.2.1.20');
        if (!defined($params{'lines'})) {
            $LASTERROR = "Cannot get lines to clear";
            return(undef)
        }
    }

    my @lines;
    for (@{$params{'lines'}}) {
        if (defined($session->set_request('1.3.6.1.4.1.9.2.9.10.0', INTEGER, $_))) {
            push @lines, $_
        } else {
            $LASTERROR = "Failed to clear line $_";
            return(undef)
        }
    }
    return \@lines
}

sub line_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %ret;
    for my $oid (1..$#LINEKEYS + 1) {
        $ret{$LINEKEYS[$oid-1]} = &_snmpgetnext($session, '1.3.6.1.4.1.9.2.9.2.1.' . $oid);
        if (!defined($ret{$LINEKEYS[$oid-1]})) {
            $LASTERROR = "Cannot get line `$LINEKEYS[$oid-1]' info";
            return(undef)
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
        $LineInfoHash{$LINEKEYS[20]} = $ret{$LINEKEYS[20]}->[$lines];
        $LineInfoHash{$LINEKEYS[19]} = $ret{$LINEKEYS[19]}->[$lines];
        $LineInfoHash{$LINEKEYS[18]} = $ret{$LINEKEYS[18]}->[$lines];
        $LineInfoHash{$LINEKEYS[17]} = $ret{$LINEKEYS[17]}->[$lines];
        $LineInfoHash{$LINEKEYS[16]} = $ret{$LINEKEYS[16]}->[$lines];
        $LineInfoHash{$LINEKEYS[15]} = $ret{$LINEKEYS[15]}->[$lines];
        $LineInfoHash{$LINEKEYS[14]} = $ret{$LINEKEYS[14]}->[$lines];
        $LineInfoHash{$LINEKEYS[13]} = $ret{$LINEKEYS[13]}->[$lines];
        $LineInfoHash{$LINEKEYS[12]} = $ret{$LINEKEYS[12]}->[$lines];
        $LineInfoHash{$LINEKEYS[11]} = $ret{$LINEKEYS[11]}->[$lines];
        $LineInfoHash{$LINEKEYS[10]} = $ret{$LINEKEYS[10]}->[$lines];
        $LineInfoHash{$LINEKEYS[9]}  = $ret{$LINEKEYS[9]}->[$lines];
        $LineInfoHash{$LINEKEYS[8]}  = $ret{$LINEKEYS[8]}->[$lines];
        $LineInfoHash{$LINEKEYS[7]}  = $ret{$LINEKEYS[7]}->[$lines];
        $LineInfoHash{$LINEKEYS[6]}  = exists($LineModem{$ret{$LINEKEYS[6]}->[$lines]}) ? $LineModem{$ret{$LINEKEYS[6]}->[$lines]} : $ret{$LINEKEYS[6]}->[$lines];
        $LineInfoHash{$LINEKEYS[5]}  = exists($LineFlow{$ret{$LINEKEYS[5]}->[$lines]}) ? $LineFlow{$ret{$LINEKEYS[5]}->[$lines]} : $ret{$LINEKEYS[5]}->[$lines];
        $LineInfoHash{$LINEKEYS[4]}  = $ret{$LINEKEYS[4]}->[$lines];
        $LineInfoHash{$LINEKEYS[3]}  = $ret{$LINEKEYS[3]}->[$lines];
        $LineInfoHash{$LINEKEYS[2]}  = $ret{$LINEKEYS[2]}->[$lines];
        $LineInfoHash{$LINEKEYS[1]}  = exists($LineTypes{$ret{$LINEKEYS[1]}->[$lines]}) ? $LineTypes{$ret{$LINEKEYS[1]}->[$lines]} : $ret{$LINEKEYS[1]}->[$lines];
        $LineInfoHash{$LINEKEYS[0]}  = $ret{$LINEKEYS[0]}->[$lines];
        $LineInfo{$ret{$LINEKEYS[19]}->[$lines]} = \%LineInfoHash
    }
    return bless \%LineInfo, $class
}

sub line_sessions {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %ret;
    for my $oid (1..$#SESSIONKEYS + 1) {
        $ret{$SESSIONKEYS[$oid-1]} = &_snmpgetnext($session, '1.3.6.1.4.1.9.2.9.3.1.' . $oid);
        if (!defined($ret{$SESSIONKEYS[$oid-1]})) {
            $LASTERROR = "Cannot get session `$SESSIONKEYS[$oid-1]' info";
            return(undef)
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
        $SessionInfoHash{$SESSIONKEYS[6]} = $ret{$SESSIONKEYS[6]}->[$sess];
        $SessionInfoHash{$SESSIONKEYS[5]} = $ret{$SESSIONKEYS[5]}->[$sess];
        $SessionInfoHash{$SESSIONKEYS[4]} = $ret{$SESSIONKEYS[4]}->[$sess];
        $SessionInfoHash{$SESSIONKEYS[3]} = $ret{$SESSIONKEYS[3]}->[$sess];
        $SessionInfoHash{$SESSIONKEYS[2]} = $ret{$SESSIONKEYS[2]}->[$sess];
        $SessionInfoHash{$SESSIONKEYS[1]} = exists($SessionDir{$ret{$SESSIONKEYS[1]}->[$sess]}) ? $SessionDir{$ret{$SESSIONKEYS[1]}->[$sess]} : $ret{$SESSIONKEYS[1]}->[$sess];
        $SessionInfoHash{$SESSIONKEYS[0]} = exists($SessionTypes{$ret{$SESSIONKEYS[0]}->[$sess]}) ? $SessionTypes{$ret{$SESSIONKEYS[0]}->[$sess]} : $ret{$SESSIONKEYS[0]}->[$sess];
        push @{$SessionInfo{$ret{$SESSIONKEYS[6]}->[$sess]}}, \%SessionInfoHash
    }
    return bless \%SessionInfo, $class
}

sub line_message {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %params = (
        message => 'Test Message.',
        lines   => [-1]
    );

    my %args;
    if (@_ == 1) {
        ($params{'message'}) = @_
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?message$/i) {
                $params{'message'} = $args{$_}
            } elsif (/^-?line(?:s)?$/i) {
                if (!defined($params{'lines'} = _get_range($args{$_}))) {
                    return(undef)
                }
            }
        }
    }

    my $response;
    my @lines;
    for (@{$params{'lines'}}) {
          # Lines
        my $response = $session->set_request("1.3.6.1.4.1.9.2.9.4.0", INTEGER, $_);
          # Interval (reissue)
        $response = $session->set_request("1.3.6.1.4.1.9.2.9.5.0", INTEGER, 0);
          # Duration
        $response = $session->set_request("1.3.6.1.4.1.9.2.9.6.0", INTEGER, 0);
          # Text (256 chars)
        $response = $session->set_request("1.3.6.1.4.1.9.2.9.7.0", OCTET_STRING, $params{'message'});
          # Temp Banner (1=no 2=append)
        $response = $session->set_request("1.3.6.1.4.1.9.2.9.8.0", INTEGER, 1);
          # Send
        $response = $session->set_request("1.3.6.1.4.1.9.2.9.9.0", INTEGER, 1);
        if (defined($response)) {
            push @lines, $_
        } else {
            $LASTERROR = "Failed to send message to line $_";
            return(undef)
        }
    }
    # clear message
    $session->set_request("1.3.6.1.4.1.9.2.9.7.0", OCTET_STRING, "");
    if ($lines[0] == -1) { $lines[0] = "ALL" }
    return \@lines
}

sub line_numberof {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my $response;
    if (!defined($response = $session->get_request( -varbindlist => ['1.3.6.1.4.1.9.2.9.1.0'] ))) {
        $LASTERROR = "Cannot get number of lines";
        return(undef)
    } else {
        return $response->{'1.3.6.1.4.1.9.2.9.1.0'}
    }
}

sub memory_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my %ret;
    # only +1 because last key (Total) isn't an OID; rather, calculated from 2 other OIDs
    for my $oid (2..$#MEMKEYS + 1) {
        $ret{$MEMKEYS[$oid-2]} = &_snmpgetnext($session, '1.3.6.1.4.1.9.9.48.1.1.1.' . $oid);
        if (!defined($ret{$MEMKEYS[$oid-2]})) {
            $LASTERROR = "Cannot get memory `$MEMKEYS[$oid-2]' info";
            return(undef)
        }
    }

    my @MemInfo;
    for my $mem (0..$#{$ret{$MEMKEYS[0]}}) {
        my %MemInfoHash;
        $MemInfoHash{$MEMKEYS[0]} =  $ret{$MEMKEYS[0]}->[$mem];
        $MemInfoHash{$MEMKEYS[1]} =  $ret{$MEMKEYS[1]}->[$mem];
        $MemInfoHash{$MEMKEYS[2]} = ($ret{$MEMKEYS[2]}->[$mem] == 1) ? 'TRUE' : 'FALSE';
        $MemInfoHash{$MEMKEYS[3]} =  $ret{$MEMKEYS[3]}->[$mem];
        $MemInfoHash{$MEMKEYS[4]} =  $ret{$MEMKEYS[4]}->[$mem];
        $MemInfoHash{$MEMKEYS[5]} =  $ret{$MEMKEYS[5]}->[$mem];
        $MemInfoHash{$MEMKEYS[6]} =  $ret{$MEMKEYS[3]}->[$mem] + $ret{$MEMKEYS[4]}->[$mem];
        push @MemInfo, \%MemInfoHash
    }
    return \@MemInfo
}

sub proxy_ping {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my $pp;
    foreach my $key (keys(%{$self})) {
        # everything but '_xxx_'
        $key =~ /^\_.+\_$/ and next;
        $pp->{$key} = $self->{$key}
    }

    my %params = (
        count  => 1,
        size   => 64,
        wait   => 1,
    );

    my %args;
    if (@_ == 1) {
        ($params{'host'}) = @_;
    } else {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?host(?:name)?$/i) || (/^-?dest(?:ination)?$/i)) {
                $params{'host'} = $args{$_};
            } elsif (/^-?size$/i) {
                if ($args{$_} =~ /^\d+$/) {
                    $params{'size'} = $args{$_}
                } else {
                    $LASTERROR = "Invalid size `$args{$_}'";
                    return(undef)
                }
            } elsif (/^-?family$/i) {
                 if ($args{$_} =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
                    if ($args{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
                        $params{'family'} = AF_INET
                    } else {
                        $params{'family'} = $AF_INET6
                    }
                } else {
                    $LASTERROR = "Invalid family `$args{$_}'";
                    return(undef)
                }
            } elsif (/^-?count$/i) {
                if ($args{$_} =~ /^\d+$/) {
                    $params{'count'} = $args{$_}
                } else {
                    $LASTERROR = "Invalid count `$args{$_}'";
                    return(undef)
                }
            } elsif ((/^-?wait$/i) || (/^-?timeout$/i)) {
                if ($args{$_} =~ /^\d+$/) {
                    $params{'wait'} = $args{$_}
                } else {
                    $LASTERROR = "Invalid wait time `$args{$_}'";
                    return(undef)
                }
            } elsif (/^-?vrf(?:name)?$/i) {
                $params{'vrf'} = $args{$_}
            }
        }
    }
    $pp->{_PROXYPING_}{'_params_'} = \%params;

    # host must be defined
    if (!defined($params{'host'})) {
        $params{'host'} = hostname
    }

    # inherit from new()
    if (!defined($params{'family'})) {
        $params{'family'} = $self->{'family'};
    }

    # resolve host our way
    if (defined(my $ret = _resolv($params{'host'}, $params{'family'}))) {
        $params{'host'}   = $ret->{'addr'};
        $params{'family'} = $ret->{'family'}
    } else {
        return undef
    }

    my $instance = int(rand(1024)+1024);
      # Prepare object by clearing row
    my $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance, INTEGER, 6);
    if (!defined($response)) {
        $LASTERROR = "proxy ping NOT SUPPORTED";
        return(undef)
    }

    # Convert destination to Hex equivalent
    my $dest;
    if ($params{'family'} == AF_INET) {
        for (split(/\./, $params{'host'})) {
            $dest .= sprintf("%02x",$_)
        }
    } else {
        if ($HAVE_Net_IPv6Addr) {
            my $addr = Net::IPv6Addr->new($params{'host'});
            my @dest = $addr->to_array;
            $dest .= join '', $_ for (@dest)
        } else {
            $LASTERROR = "Socket > 1.94 and Net::IPv6Addr required";
            return(undef)
        }
    }

      # ciscoPingEntryStatus (5 = createAndWait, 6 = destroy)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance, INTEGER, 6);
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance, INTEGER, 5);
      # ciscoPingEntryOwner (<anyname>)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.15.' . $instance, OCTET_STRING, __PACKAGE__);
      # ciscoPingProtocol (1 = IP, 20 = IPv6)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.2.' . $instance, INTEGER, ($params{'family'} == AF_INET) ? 1 : 20);
    if (!defined($response)) {
        $LASTERROR = "Device does not support ciscoPingProtocol 20 (IPv6)";
        return(undef)
    }
      # ciscoPingAddress (NOTE: hex string, not regular IP)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.3.' . $instance, OCTET_STRING, pack('H*', $dest));
      # ciscoPingPacketTimeout (in ms)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.6.' . $instance, INTEGER32, $params{'wait'}*100);
      # ciscoPingDelay (Set gaps (in ms) between successive pings)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.7.' . $instance, INTEGER32, $params{'wait'}*100);
      # ciscoPingPacketCount
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.4.' . $instance, INTEGER, $params{'count'});
      # ciscoPingPacketSize (protocol dependent)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.5.' . $instance, INTEGER, $params{'size'});

    if (exists($params{'vrf'})) {
          # ciscoPingVrfName (<name>)
        $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.17.' . $instance, OCTET_STRING, $params{'vrf'})
    }
      # Verify ping is ready (ciscoPingEntryStatus = 2)
    $response = $session->get_request('1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance);
    if (defined($response->{'1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance})) {
        if ($response->{'1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance} != 2) {
            $LASTERROR = "Ping not ready";
            return(undef)
        }
    } else {
        $LASTERROR = "proxy ping NOT SUPPORTED (after setup)";
        return(undef)
    }

      # ciscoPingEntryStatus (1 = activate)
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance, INTEGER, 1);

    # Wait sample interval
    sleep $params{'wait'};

      # Get results
    $response = $session->get_table('1.3.6.1.4.1.9.9.16.1.1.1');
    $pp->{'_PROXYPING_'}{'Sent'}     = $response->{'1.3.6.1.4.1.9.9.16.1.1.1.9.' . $instance}  || 0;
    $pp->{'_PROXYPING_'}{'Received'} = $response->{'1.3.6.1.4.1.9.9.16.1.1.1.10.' . $instance} || 0;
    $pp->{'_PROXYPING_'}{'Minimum'}  = $response->{'1.3.6.1.4.1.9.9.16.1.1.1.11.' . $instance} || 0;
    $pp->{'_PROXYPING_'}{'Average'}  = $response->{'1.3.6.1.4.1.9.9.16.1.1.1.12.' . $instance} || 0;
    $pp->{'_PROXYPING_'}{'Maximum'}  = $response->{'1.3.6.1.4.1.9.9.16.1.1.1.13.' . $instance} || 0;

      # destroy entry
    $response = $session->set_request('1.3.6.1.4.1.9.9.16.1.1.1.16.' . $instance, INTEGER, 6);
    return bless $pp, $class
}

sub proxy_ping_sent {
    my $self = shift;
    return $self->{'_PROXYPING_'}{'Sent'}
}

sub proxy_ping_received {
    my $self = shift;
    return $self->{'_PROXYPING_'}{'Received'}
}

sub proxy_ping_minimum {
    my $self = shift;
    return $self->{'_PROXYPING_'}{'Minimum'}
}

sub proxy_ping_average {
    my $self = shift;
    return $self->{'_PROXYPING_'}{'Average'}
}

sub proxy_ping_maximum {
    my $self = shift;
    return $self->{'_PROXYPING_'}{'Maximum'}
}

sub system_info {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my $sysinfo;
    foreach my $key (keys(%{$self})) {
        # everything but '_xxx_'
        $key =~ /^\_.+\_$/ and next;
        $sysinfo->{$key} = $self->{$key}
    }

    my $response = &_snmpgetnext($session, '1.3.6.1.2.1.1');
    if (defined($response)) {

        if (defined($response->[0])) { $sysinfo->{'_SYSINFO_'}{'Description'} = $response->[0] }
        if (defined($response->[1])) { $sysinfo->{'_SYSINFO_'}{'ObjectID'}    = $response->[1] }
        if (defined($response->[2])) { $sysinfo->{'_SYSINFO_'}{'Uptime'}      = $response->[2] }
        if (defined($response->[3])) { $sysinfo->{'_SYSINFO_'}{'Contact'}     = $response->[3] }
        if (defined($response->[4])) { $sysinfo->{'_SYSINFO_'}{'Name'}        = $response->[4] }
        if (defined($response->[5])) { $sysinfo->{'_SYSINFO_'}{'Location'}    = $response->[5] }
        if (defined($response->[6])) { $sysinfo->{'_SYSINFO_'}{'Services'}    = $response->[6] }

        return bless $sysinfo, $class
    } else {
        $LASTERROR = "Cannot read system MIB";
        return(undef)
    }
}

sub system_info_description {
    my $self = shift;
    return $self->{'_SYSINFO_'}{'Description'}
}

sub system_info_objectID {
    my $self = shift;
    return $self->{'_SYSINFO_'}{'ObjectID'}
}

sub system_info_uptime {
    my $self = shift;
    return $self->{'_SYSINFO_'}{'Uptime'}
}

sub system_info_contact {
    my $self = shift;
    return $self->{'_SYSINFO_'}{'Contact'}
}

sub system_info_name {
    my $self = shift;
    return $self->{'_SYSINFO_'}{'Name'}
}

sub system_info_location {
    my $self = shift;
    return $self->{'_SYSINFO_'}{'Location'}
}

sub system_info_services {
    my ($self, $arg) = @_;

    if (defined($arg) && ($arg >= 1)) {
        return $self->{'_SYSINFO_'}{'Services'}
    } else {
        my %Services = (
            1  => 'Physical',
            2  => 'Datalink',
            4  => 'Network',
            8  => 'Transport',
            16 => 'Session',
            32 => 'Presentation',
            64 => 'Application'
        );
        my @Svcs;
        for (sort {$b <=> $a} (keys(%Services))) {
            push @Svcs, $Services{$_} if ($self->{'_SYSINFO_'}{'Services'} & int($_))
        }
        return \@Svcs
    }
}

sub system_info_osversion {
    my $self = shift;

    if ($self->{'_SYSINFO_'}{'Description'} =~ /Version ([^ ,\n\r]+)/) {
        return $1
    } else {
        return "Cannot determine OS Version"
    }
}

sub system_inventory {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{'_SESSION_'};

    my $inventory;
    foreach my $key (keys(%{$self})) {
        # everything but '_xxx_'
        $key =~ /^\_.+\_$/ and next;
        $inventory->{$key} = $self->{$key}
    }

    my %ret;
    for my $oid (2..$#INVENTORYKEYS + 2) {
        $ret{$INVENTORYKEYS[$oid-2]} = &_snmpgetnext($session, '1.3.6.1.2.1.47.1.1.1.1.' . $oid);
        if (!defined($ret{$INVENTORYKEYS[$oid-2]})) {
            $LASTERROR = "Cannot get inventory `$INVENTORYKEYS[$oid-2]' info";
            return(undef)
        }
    }

    my @Inventory;
    for my $unit (0..$#{$ret{$INVENTORYKEYS[5]}}) {
        my %InventoryHash;
        $InventoryHash{$INVENTORYKEYS[0]}  = $ret{$INVENTORYKEYS[0]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[1]}  = $ret{$INVENTORYKEYS[1]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[2]}  = $ret{$INVENTORYKEYS[2]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[3]}  = $ret{$INVENTORYKEYS[3]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[4]}  = $ret{$INVENTORYKEYS[4]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[5]}  = $ret{$INVENTORYKEYS[5]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[6]}  = $ret{$INVENTORYKEYS[6]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[7]}  = $ret{$INVENTORYKEYS[7]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[8]}  = $ret{$INVENTORYKEYS[8]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[9]}  = $ret{$INVENTORYKEYS[9]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[10]} = $ret{$INVENTORYKEYS[10]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[11]} = $ret{$INVENTORYKEYS[11]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[12]} = $ret{$INVENTORYKEYS[12]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[13]} = $ret{$INVENTORYKEYS[13]}->[$unit];
        $InventoryHash{$INVENTORYKEYS[14]} = $ret{$INVENTORYKEYS[14]}->[$unit];
        push @Inventory, \%InventoryHash
    }
    return \@Inventory
}

########################################################
# Subroutines
########################################################

sub password_decrypt {

    my $self = shift;
    my $class = ref($self) || $self;

    my $passwd;

    if ($self ne __PACKAGE__) {
        $passwd = $self
    } else {
        ($passwd) = @_
    }

    if (($passwd =~ /^[\da-f]+$/i) && (length($passwd) > 2)) {
        if (!(length($passwd) & 1)) {
            my $dec = "";
            my ($s, $e) = ($passwd =~ /^(..)(.+)/o);

            for (my $i = 0; $i < length($e); $i+=2) {
                # If we move past the end of the XOR key, reset
                if ($s > $#xlat) { $s = 0 }
                $dec .= sprintf "%c",hex(substr($e,$i,2))^$xlat[$s++]
            }
            return $dec
        }
    }
    $LASTERROR = "Invalid password `$passwd'";
    return(0)
}

sub password_encrypt {

    my $self = shift;
    my $class = ref($self) || $self;

    my ($cleartxt, $index);

    if ($self ne __PACKAGE__) {
        $cleartxt = $self;
        ($index) = @_
    } else {
        ($cleartxt, $index) = @_
    }

    my $start = 0;
    my $end = $#xlat;

    if (defined($index)) {
        if ($index =~ /^\d+$/) {
            if (($index < 0) || ($index > $#xlat)) {
                $LASTERROR = "Index out of range 0-$#xlat: $index";
                return(0)
            } else {
                $start = $index;
                $end   = $index
            }
        } elsif ($index eq "") {
            # Do them all - currently set for that.
        } else {
            my $random = int(rand($#xlat + 1));
            $start = $random;
            $end   = $random
        }
    }

    my @passwds;
    for (my $j = $start; $j <= $end; $j++) {
        my $encrypt = sprintf "%02i", $j;
        my $s       = $j;

        for (my $i = 0; $i < length($cleartxt); $i++) {
            # If we move past the end of the XOR key, reset
            if ($s > $#xlat) { $s = 0 }
            $encrypt .= sprintf "%02X", ord(substr($cleartxt,$i,1))^$xlat[$s++]
        }
        push @passwds, $encrypt
    }
    return \@passwds
}

sub close {
    my $self = shift;
    $self->{_SESSION_}->close();
}

sub error {
    return($LASTERROR)
}

########################################################
# End Public Module
########################################################

########################################################
# Start Private subs
########################################################

# Return:
# -1 = error
#  0 = DONE
#  1 = continue
sub _config_copy {
    my ($params, $session, $instance) = @_;

    my $response;
    my %caterr = (
        1  => "In Progress",
        2  => "Success",
        3  => "No Response",
        4  => "Too Many Retries",
        5  => "No Buffers",
        6  => "No Processes",
        7  => "Bad Checksum",
        8  => "Bad Length",
        9  => "Bad Flash",
        10 => "Server Error",
        11 => "User Cancelled",
        12 => "Wrong Code",
        13 => "File Not Found",
        14 => "Invalid TFTP Host",
        15 => "Invalid TFTP Module",
        16 => "Access Violation",
        17 => "Unknown Status",
        18 => "Invalid Storage Device",
        19 => "Insufficient Space On Storage Device",
        20 => "Insufficient Dram Size",
        21 => "Incompatible Image"
    );

    if ($params->{'catos'}) {
        $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.1.0', OCTET_STRING, $params->{'tftpserver'});
        $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.2.0', OCTET_STRING, $params->{'file'});
        $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.3.0', INTEGER, 1);
        if ($params->{'op'} eq 'put') {
            $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.4.0', INTEGER, 2)
        } else {
            $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.4.0', INTEGER, 3)
        }

        # loop and check response - error if timeout
        $response = $session->get_request('1.3.6.1.4.1.9.5.1.5.5.0');
        my $loop = 0;
        while ($response->{'1.3.6.1.4.1.9.5.1.5.5.0'} == 1) {
            $response = $session->get_request('1.3.6.1.4.1.9.5.1.5.5.0');
            if ($loop++ == $params->{'timeout'}) {
                $LASTERROR = "CatOS TFTP `$params->{'op'}' FAILED - timeout during completion verification";
                return -1
            }
            sleep 1
        }

        if ($response->{'1.3.6.1.4.1.9.5.1.5.5.0'} == 2) {
            return 0
        } else {
            $LASTERROR = "CatOS TFTP `$params->{'op'}' FAILED - " . $caterr{$response->{'1.3.6.1.4.1.9.5.1.5.5.0'}};
            return -1
        }

    # IOS
    } else {
          # ccCopyEntryRowStatus (5 = createAndWait, 6 = destroy)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 5);

          # ccCopyProtocol (1 = TFTP)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.2.' . $instance, INTEGER, 1);

        if (!defined($response)) {
            $LASTERROR = "IOS TFTP `$params->{'op'}' NOT SUPPORTED - trying old way";
            if ($params->{'family'} == $AF_INET6) {
                $LASTERROR = "IOS TFTP `$params->{'op'}' old way does not support IPv6";
                return -1
            }
            if ($params->{'op'} eq 'put') {
                $response = $session->set_request('1.3.6.1.4.1.9.2.1.50.' . $params->{'tftpserver'}, OCTET_STRING, $params->{'file'})
            } else {
                $response = $session->set_request('1.3.6.1.4.1.9.2.1.55.' . $params->{'tftpserver'}, OCTET_STRING, $params->{'file'})
            }
            if (defined($response)) {
                return 0
            } else {
                $LASTERROR = "IOS TFTP `$params->{'op'}' FAILED (new and old)";
                return -1
            }
        }
          # ccCopySourceFileType [.3] (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
          # ccCopyDestFileType [.4] (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
        if ($params->{'op'} eq 'put') {
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.3.' . $instance, INTEGER, 1);
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.4.' . $instance, INTEGER, $params->{'dest'})
        } else {
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.3.' . $instance, INTEGER, $params->{'source'});
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.4.' . $instance, INTEGER, 1)
        }
          # New way
          # ccCopyServerAddressType (1 = IPv4, 2 = IPv6)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.15.' . $instance, INTEGER, ($params->{'family'} == AF_INET) ? 1 : 2);

        if (defined($response)) {
              # ccCopyServerAddressRev1
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.16.' . $instance, OCTET_STRING, $params->{'tftpserver'})
        } else {
              # Deprecated
              # ccCopyServerAddress
            if ($params->{'family'} == $AF_INET6) {
                $LASTERROR = "ccCopyServerAddressRev1 not supported (requried for IPv6)";
                return -1
            }
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.5.' . $instance, IPADDRESS, $params->{'tftpserver'})
        }
          # ccCopyFileName
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.6.' . $instance, OCTET_STRING, $params->{'file'})
    }
    return 1
}

sub _get_range {
    my ($opt) = @_;

    # If argument, it must be a number range in the form:
    #  1,9-11,7,3-5,15
    if ($opt !~ /^\d+([\,\-]\d+)*$/) {
        $LASTERROR = "Invalid range format `$opt'";
        return(undef)
    }

    my (@option, @temp, @ends);

    # Split the string at the commas first to get:  1 9-11 7 3-5 15
    @option = split(/,/, $opt);

    # Loop through remaining values for dashes which mean all numbers inclusive.
    # Thus, need to expand ranges and put values in array.
    for $opt (@option) {

        # If value has a dash '-', split and add 'missing' numbers.
        if ($opt =~ /-/) {

            # Ends are start and stop number of range.  For example, $opt = 9-11:
            # $ends[0] = 9
            # $ends[1] = 11
            @ends = split(/-/, $opt);

            for ($ends[0]..$ends[1]) {
                push @temp, $_
            }

        # No dash '-', move on
        } else {
            push @temp, $opt
        }
    }
    # return the sorted values of the temp array
    @temp = sort { $a <=> $b } (@temp);
    return \@temp
}

sub _snmpgetnext {
    my ($session, $oid) = @_;

    my (@oids, @vals);
    my $base = $oid;
    my $result = 0;

    while (defined($result = $session->get_next_request( -varbindlist => [$oid] ))) {
        my ($o, $v) = each(%{$result});
        if (oid_base_match($base, $o)) {
            push @vals, $v;
            push @oids, $o;
            $oid = $o
        } else {
            last
        }
    }
    if ((@oids == 0) && (@vals == 0)) {
        if (defined($result = $session->get_request($oid))) {
            push @vals, $result->{$oid};
            push @oids, $oid
        } else {
            return(undef)
        }
    }
    return (\@oids, \@vals)
}

########################################################
# DNS hostname resolution
# return:
#   $host->{name}   = host - as passed in
#   $host->{host}   = host - as passed in without :port
#   $host->{port}   = OPTIONAL - if :port, then value of port
#   $host->{addr}   = resolved numeric address
#   $host->{family} = AF_INET/6
############################
sub _resolv {
    my ($name, $family) = @_;

    my %h;
    $h{name} = $name;

    # Default to IPv4 for backward compatiblity
    # THIS MAY CHANGE IN THE FUTURE!!!
    if (!defined($family)) {
        $family = AF_INET
    }

# START - host:port
    my $cnt = 0;

    # Count ":"
    $cnt++ while ($name =~ m/:/g);

    # 0 = hostname or IPv4 address
    if ($cnt == 0) {
        $h{host} = $name
    # 1 = IPv4 address with port
    } elsif ($cnt == 1) {
        ($h{host}, $h{port}) = split /:/, $name
    # >=2 = IPv6 address
    } elsif ($cnt >= 2) {
        #IPv6 with port - [2001::1]:port
        if ($name =~ /^\[.*\]:\d{1,5}$/) {
            ($h{host}, $h{port}) = split /:([^:]+)$/, $name # split after last :
        # IPv6 without port
        } else {
            $h{host} = $name
        }
    }

    # Clean up host
    $h{host} =~ s/\[//g;
    $h{host} =~ s/\]//g;
    # Clean up port
    if (defined($h{port}) && (($h{port} !~ /^\d{1,5}$/) || ($h{port} < 1) || ($h{port} > 65535))) {
        $LASTERROR = "Invalid port `$h{port}' in `$name'";
        return undef
    }
# END - host:port

    # address check
    # new way
    if ($Socket::VERSION >= 1.94) {
        my %hints = (
            family   => $AF_UNSPEC,
            protocol => IPPROTO_TCP,
            flags => $AI_NUMERICHOST
        );

        # numeric address, return
        my ($err, @getaddr) = Socket::getaddrinfo($h{host}, undef, \%hints);
        if (defined($getaddr[0])) {
            $h{addr}   = $h{host};
            $h{family} = $getaddr[0]->{family};
            return \%h
        }
    # old way
    } else {
        # numeric address, return
        my $ret = gethostbyname($h{host});
        if (defined($ret) && (inet_ntoa($ret) eq $h{host})) {
            $h{addr}   = $h{host};
            $h{family} = AF_INET;
            return \%h
        }
    }

    # resolve
    # new way
    if ($Socket::VERSION >= 1.94) {
        my %hints = (
            family   => $family,
            protocol => IPPROTO_TCP
        );

        my ($err, @getaddr) = Socket::getaddrinfo($h{host}, undef, \%hints);
        if (defined($getaddr[0])) {
            my ($err, $address) = Socket::getnameinfo($getaddr[0]->{addr}, $NI_NUMERICHOST);
            if (defined($address)) {
                $h{addr} = $address;
                $h{addr} =~ s/\%(.)*$//; # remove %ifID if IPv6
                $h{family} = $getaddr[0]->{family};
                return \%h
            } else {
                $LASTERROR = "getnameinfo($getaddr[0]->{addr}) failed - $err";
                return undef
            }
        } else {
            $LASTERROR = sprintf "getaddrinfo($h{host},,%s) failed - $err", ($family == AF_INET) ? "AF_INET" : "AF_INET6";
            return undef
        }
    # old way
    } else {
        if ($family == $AF_INET6) {
            $LASTERROR = "Socket >= 1.94 required for IPv6 - found Socket $Socket::VERSION";
            return undef
        }

        my @gethost = gethostbyname($h{host});
        if (defined($gethost[4])) {
            $h{addr} = inet_ntoa($gethost[4]);
            $h{family} = AF_INET;
            return \%h
        } else {
            $LASTERROR = "gethostbyname($h{host}) failed - $^E";
            return undef
        }
    }
}

########################################################
# End Private subs
########################################################

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

Cisco::Management - Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::Management;

=head1 DESCRIPTION

This module is deprecated - please use L<Cisco::SNMP>.

B<Cisco::Management> is a class implementing several management functions
for Cisco devices - mostly via SNMP.  B<Cisco::Management> uses the
B<Net::SNMP> module to do the SNMP calls.

=head1 CAVEATS

This module is deprecated - please use L<Cisco::SNMP>.

As of version 0.06, B<Cisco::Management> supports IPv6 on systems with IPv6
configured but requires B<Socket> version 1.94 or greater.  This may cause
issues on Perl versions less than 5.14, where the default B<Socket> module
is of a lesser version.  The requirement stems from the use of the
C<getaddrinfo()> and C<getnameinfo()> functions not available on older
versions of B<Socket>.

=head1 METHODS

=head2 new() - create a new Cisco::Management object

  my $cm = Cisco::Management->new([OPTIONS]);

Create a new B<Cisco::Management> object with OPTIONS as optional parameters.
Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -community SNMP read/write community string       private
  -family    Address family IPv4/IPv6               IPv4
               Valid values for IPv4:
                 4, v4, ip4, ipv4, AF_INET (constant)
               Valid values for IPv6:
                 6, v6, ip6, ipv6, AF_INET6 (constant)
  -hostname  Remote device to connect to            localhost
  -port      Port to connect to                     161
  -timeout   Timeout to wait for request in seconds 10
  -version   SNMP version to use                    1
  [Additional options available from Net::SNMP module]

B<Family> provides hint for resolving names provided for B<hostname>
to addresses.

=head2 session() - return Net::SNMP session object

  $session = $cm->session;

Return the B<Net::SNMP> session object created by the B<Cisco::Management>
new() method.  This is useful to call B<Net::SNMP> methods directly without
having to create a new B<Net::SNMP> object.  For example:

  my $cm = Cisco::Management->new(
      -host      => 'router1',
      -community => 'snmpRW'
  );
  my $session = $cm->session();
  # get_request() is a Net::SNMP method
  $session->get_request('1.3.6.1.2.1.1.4.0');

In this case, the C<get_request> call is a method provided by the
B<Net::SNMP> module that can be accessed directly via the C<$session>
object returned by the C<$cm-E<gt>session()> method.

=head2 close() - close session

  $cm->close;

Close the Cisco::Management session.

=head2 error() - print last error

  printf "Error: %s\n", Cisco::Management->error;

Return last error.

=head2 Configuration Management Options

The following methods are for configuration file management.  These
methods implement the C<CISCO-CONFIG-COPY-MIB> for configuration file
management.  If these operations fail, the older method in
C<OLD-CISCO-SYS-MIB> is tried.  All Catalyst OS operations are
performed against the C<CISCO-STACK-MIB>.

=head2 config_copy() - configuration file management

  my $cc = $cm->config_copy([OPTIONS]);

Manage configuration files.  Options allow for TFTP upload or download
of running-config or startup-config and a copy running-config to
startup-config or vice versa.  Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -catos     Catalyst OS boolean flag.  Enable if   0
             device runs Catalyst OS.
  -dest      'startup-config', 'running-config'     'startup-config'
             or filename for TFTP server
  -family    Address family IPv4/IPv6               [Inherit from new()]
               Valid values for IPv4:
                 4, v4, ip4, ipv4, AF_INET (constant)
               Valid values for IPv6:
                 6, v6, ip6, ipv6, AF_INET6 (constant)
  -source    'startup-config', 'running-config'     'running-config'
             or filename on TFTP server
  -tftp      TFTP server address                    localhost
  -timeout   Seconds until timeout for completion   10
             check

The default behavior with no options is C<copy running-config
startup-config>.

B<NOTE:>  Use care when performing TFTP upload to startup-config.  This
B<MUST> be a B<FULL> configuration file as the config file is B<NOT>
merged, but instead B<OVERWRITES> the startup-config.

A hostname value for B<tftp> will be resolved to IPv4/v6 based on B<family>.
B<Family> is inherited from the value set in new() but can be overriden.
Providing a numeric address will also self-determine the IPv4/v6 address.

Allows the following methods to be called.

=head3 config_copy_starttime() - return config copy start time

  $cc->config_copy_starttime();

Return the start time of the configuration copy operation relative to
system uptime.

=head3 config_copy_endtime() - return config copy end time

  $cc->config_copy_endtime();

Return the end time of the configuration copy operation relative to
system uptime.

=head2 CPU Info

The following methods are for CPU utilization.  These methods
implement the C<CISCO-PROCESS-MIB> and C<OLD-CISCO-SYS-MIB>.

=head2 cpu_info() - return CPU utilization info

  my $cpuinfo = $cm->cpu_info();

Populate a data structure with CPU information.  If successful,
returns pointer to an array containing CPU information.

  $cpuinfo->[0]->{'Name', '5sec', '1min', ...}
  $cpuinfo->[1]->{'Name', '5sec', '1min', ...}
  ...
  $cpuinfo->[n]->{'Name', '5sec', '1min', ...}

=head2 Interface Options

The following methods are for interface management.  These methods
implement the C<IF-MIB>.

=head2 interface_getbyindex() - get interface name by ifIndex

  my $line = $cm->interface_getbyindex([OPTIONS]);

Resolve an ifIndex to the full interface name.  Called with one
argument, interpreted as the interface ifIndex to resolve.

  Option     Description                            Default
  ------     -----------                            -------
  -index     The ifIndex to resolve                 -REQUIRED-

Returns the full interface name string.

=head2 interface_getbyname() - get interface name/ifIndex by string

  my $name = $cm->interface_getbyname([OPTIONS]);

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
  Duplex *
  PhysAddress
  AdminStatus
  OperStatus
  LastChange

B<NOTE:>  Duplex is found in the C<EtherLike-MIB> and thus will not
be populated for non-Ethernet interface types.

If successful, returns a pointer to a hash containing interface
information.

  $ifs->{1}->{'Index', 'Description', ...}
  $ifs->{2}->{'Index', 'Description', ...}
  ...
  $ifs->{n}->{'Index', 'Description', ...}

=head2 interface_ip() - return IP info for interfaces

  my $ips = $cm->interface_ip([1]);

Populate a data structure with the IP information per interface.
If successful, returns a pointer to a hash containing interface IP
information.  For /xx instead of dotted-octet format for mask, use
the optional boolean argument.

  $ips->{1}->[0]->{'IPAddress', 'IPMask'}
             [1]->{'IPAddress', 'IPMask'}
             ...
  ...
  $ips->{n}->[0]->{'IPAddress', 'IPMask'}

First hash value is the interface ifIndex, next array is the list of
current IP information per the interface ifIndex.

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
  Octets       (count of octets in/out)
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

  my $line = $cm->interface_updown([OPTIONS]);

Admin up or down the interface.  Called with no arguments, admin up
all interfaces.  Called with one argument, interpreted as the
interface(s) to admin up.

  Option     Description                            Default
  ------     -----------                            -------
  -interface ifIndex or range of ifIndex (, and -)  (all)
  -operation 'up' or 'down'                         'up'

To specify individual interfaces, provide their number:

  my $line = $cm->interface_updown(2);

Admin up ifIndex 2.  To specify a range of interfaces, provide a
range:

  my $line = $cm->interface_updown(
                                   -operation => 'down',
                                   -interface => '2-4,6,9-11'
                                  );

Admin down ifIndex 2 3 4 6 9 10 11.

If successful, returns a pointer to an array containing the interfaces
admin up/down.

=head2 Line Options

The following methods are for line management.  Lines on Cisco devices
refer to console, auxillary and terminal lines for user interaction.
These methods implement the C<OLD-CISCO-TS-MIB> which is not available
on some newer forms of IOS.

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

  my $line = $cm->line_info();

Populate a data structure with line information.  If successful,
returns a pointer to a hash containing line information.

  $line->{0}->{'Number', 'TimeActive', ...}
  $line->{1}->{'Number', 'TimeActive', ...}
  ...
  $line->{n}->{'Number', 'TimeActive', ...}

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

=head2 Memory Info

The following methods are for memory utilization.  These methods
implement the C<CISCO-MEMORY-POOL-MIB>.

=head2 memory_info() - return memory utilization info

  my $meminfo = $cm->memory_info();

Populate a data structure with memory information.  If successful,
returns a pointer to an array containing memory information.

  $meminfo->[0]->{'Name', 'Used', 'Free', ...}
  $meminfo->[1]->{'Name', 'Used', 'Free', ...}
  ...
  $meminfo->[n]->{'Name', 'Used', 'Free', ...}

=head2 Proxy Ping

The following methods are for proxy ping.  These methods implement the
C<CISCO-PING-MIB>.

=head2 proxy_ping() - execute proxy ping

  my $ping = $cm->proxy_ping([OPTIONS]);

Send proxy ping from the object defined in C<$cm> to the provided
destination.  Called with no options, sends the proxy ping to the
localhost.  Called with one argument, interpreted as the destination
to proxy ping.  Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -count     Number of pings to send                1
  -family    Address family IPv4/IPv6               [Inherit from new()]
               Valid values for IPv4:
                 4, v4, ip4, ipv4, AF_INET (constant)
               Valid values for IPv6:
                 6, v6, ip6, ipv6, AF_INET6 (constant)
  -host      Destination to send proxy ping to      (localhost)
  -size      Size of the ping packets in bytes      64
  -vrf       VRF name to source pings from          [none]
  -wait      Time to wait for replies in seconds    1

A hostname value for B<host> will be resolved to IPv4/v6 based on B<family>.
B<Family> is inherited from the value set in new() but can be overriden.
Providing a numeric address will also self-determine the IPv4/v6 address.

Allows the following methods to be called.

=head3 proxy_ping_sent() - return number of pings sent

  $ping->proxy_ping_sent();

Return the number of pings sent in the current proxy ping execution.

=head3 proxy_ping_received() - return number of pings received

  $ping->proxy_ping_received();

Return the number of pings received in the current proxy ping execution.

=head3 proxy_ping_minimum() - return minimum round trip time

  $ping->proxy_ping_minimum();

Return the minimum round trip time in milliseconds of pings sent and
received in the current proxy ping execution.

=head3 proxy_ping_average() - return average round trip time

  $ping->proxy_ping_average();

Return the average round trip time in milliseconds of pings sent and
received in the current proxy ping execution.

=head3 proxy_ping_maximum() - return maximum round trip time

  $ping->proxy_ping_maximum();

Return the maximum round trip time in milliseconds of pings sent and
received in the current proxy ping execution.

=head2 System Info

The following methods implement the System MIB defined in C<SNMPv2-MIB>
and the C<ENTITY-MIB>.

=head2 system_info() - populate system info data structure.

  my $sysinfo = $cm->system_info();

Retrieve the system MIB information from the object defined in C<$cm>.

Allows the following methods to be called.

=head3 system_info_description() - return system description

  $sysinfo->system_info_description();

Return the system description from the system info data structure.

=head3 system_info_objectID() - return system object ID

  $sysinfo->system_info_objectID();

Return the system object ID from the system info data structure.

=head3 system_info_uptime() - return system uptime

  $sysinfo->system_info_uptime();

Return the system uptime from the system info data structure.

=head3 system_info_contact() - return system contact

  $sysinfo->system_info_contact();

Return the system contact from the system info data structure.

=head3 system_info_name() - return system name

  $sysinfo->system_info_name();

Return the system name from the system info data structure.

=head3 system_info_location() - return system location

  $sysinfo->system_info_location();

Return the system location from the system info data structure.

=head3 system_info_services() - return system services

  $sysinfo->system_info_services([1]);

Return a pointer to an array containing the names of the system
services from the system info data structure.  For the raw number,
use the optional boolean argument.

=head3 system_info_osversion() - return system OS version

  $sysinfo->system_info_osversion();

Return the system OS version as parsed from the sysDescr OID.

=head2 system_inventory() - return system inventory info

  my $inventory = $cm->system_inventory();

Populate a data structure with inventory information.  If successful,
returns a pointer to an array containing inventory information.

  $inventory->[0]->{'Descr', 'VendorType', ...}
  $inventory->[1]->{'Descr', 'VendorType', ...}
  ...
  $inventory->[n]->{'Descr', 'VendorType', ...}

=head1 SUBROUTINES

Password subroutines are for decrypting and encrypting Cisco type 7
passwords.  The algorithm is freely available on the Internet on
several sites; thus, I can/will B<NOT> take credit or B<ANY> liability
for its use.

=head2 password_decrypt() - decrypt a Cisco type 7 password

  my $passwd = Cisco::Management->password_decrypt('00071A150754');

Where C<00071A150754> is the encrypted Cisco password in this example.

=head2 password_encrypt() - encrypt a Cisco type 7 password

  my $passwd = Cisco::Management->password_encrypt('cleartext'[,# | *]);
  print "$_\n" for (@{$passwd});

Where C<cleartext> is the clear text string to encrypt.  The second
optional argument is a number in the range of 0 - 52 inclusive or
random text.

Returns a pointer to an array constructed based on the second argument
to C<password_encrypt>.

  Option  Description            Action
  ------  -----------            -------
          No argument provided   Return all 53 possible encryptions.
  #       Number 0-52 inclusive  Return password encrypted with # index.
  (other) Random text            Return a random password.

B<NOTE:>  Cisco routers by default only seem to use the first 16 indexes
(0 - 15) to encrypt passwords.  You notice this by looking at the first
two characters of any type 7 encrypted password in a Cisco router
configuration.  However, testing on IOS 12.x and later shows that manually
entering a password encrypted with a higher index (generated from this
script) to a Cisco configuration will not only be allowed, but will
function normally for authentication.  This may be a form of "security
through obscurity" given that some older Cisco password decrypters don't
use the entire translation index and limit 'valid' passwords to those
starting with the fist 16 indexes (0 - 15).  Using passwords with an
encryption index of 16 - 52 inclusive I<may> render older Cisco password
decrypters useless.

Additionally, the Cisco router command prompt seems to be limited to 254
characters, making the largest password 250 characters (254 - 4
characters for the C<pas > (followed by space) command to enter the
password).

=head1 EXPORT

None by default.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
C<bin> install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 SEE ALSO

L<Cisco::SNMP>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut

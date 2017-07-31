package Cisco::SNMP::Config;

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

use Sys::Hostname;
use Socket qw(AF_INET);

my $AF_INET6 = eval { Socket::AF_INET6() };

my %PROTO = (
    tftp => 1,
    ftp  => 2,
    rcp  => 3,
    scp  => 4,
    sftp => 5
);

##################################################
# Start Public Module
##################################################

sub config_copy {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $session = $self->{_SESSION_};

    my %params = (
        op         => 'wr',
        catos      => 0,
        timeout    => 10,
        source     => 4,
        dest       => 3,
        protocol   => 'tftp',
        username   => 'cisco',
        password   => 'cisco'
    );

    my %args;
    if (@_ == 1) {
        $Cisco::SNMP::LASTERROR = "Insufficient number of args";
        return undef
    } else {
        %args = @_;
        for (keys(%args)) {
            if ((/^-?(?:tftp)?server$/i) || (/^-?tftp$/)) {
                $params{server} = $args{$_}
            } elsif (/^-?catos$/i) {
                if ($args{$_} == 1) {
                    $params{catos} = 1
                }
            } elsif (/^-?user(?:name)?$/i) {
                $params{username} = $args{$_}
            } elsif (/^-?pass(?:word)?$/i) {
                $params{password} = $args{$_}
            } elsif (/^-?timeout$/i) {
                $params{timeout} = $args{$_}
            } elsif (/^-?proto(?:col)?$/i) {
                if (exists($PROTO{ lc ($args{$_})})) {
                    $params{protocol} = lc ($args{$_})
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid protocol `$args{$_}'";
                    return undef
                }
            } elsif (/^-?family$/i) {
                 if ($args{$_} =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
                    if ($args{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
                        $params{family} = AF_INET
                    } else {
                        $params{family} = $AF_INET6
                    }
                } else {
                    $Cisco::SNMP::LASTERROR = "Invalid family `$args{$_}'";
                    return undef
                }
            } elsif (/^-?source$/i) {
                if ($args{$_} =~ /^run(?:ning)?(?:-config)?$/i) {
                    $params{source} = 4
                } elsif ($args{$_} =~ /^start(?:up)?(?:-config)?$/i) {
                    $params{source} = 3
                } else {
                    $params{source} = 1;
                    $params{op}     = 'put';
                    $params{file}   = $args{$_}
                }
            } elsif (/^-?dest(?:ination)?$/i) {
                if ($args{$_} =~ /^run(?:ning)?(?:-config)?$/i) {
                    $params{dest} = 4
                } elsif ($args{$_} =~ /^start(?:up)?(?:-config)?$/i) {
                    $params{dest} = 3
                } else {
                    $params{dest} = 1;
                    $params{op}   = 'get';
                    $params{file} = $args{$_}
                }
            }
        }
    }
    my $cc;
    $cc->{_params_} = \%params;

    if ($params{source} == $params{dest}) {
        $Cisco::SNMP::LASTERROR = "Source and destination cannot be same";
        return undef
    }

    # server must be defined if put/get
    if (($params{op} ne 'wr') && !defined $params{server}) {
        $params{server} = hostname
    }

    # inherit from new()
    if (!defined $params{family}) {
        $params{family} = $self->{family}
    }

    if ($params{catos} && $params{protocol} != 'tftp') {
        $Cisco::SNMP::LASTERROR = "CatOS only supports tftp";
        return undef
    }

    # resolve server our way
    if (defined $params{server}) {
        if (defined(my $ret = Cisco::SNMP::_resolv($params{server}, $params{family}))) {
            $params{server} = $ret->{addr};
            $params{family}     = $ret->{family}
        } else {
            return undef
        }
        if ($params{catos} && ($params{family} == $AF_INET6)) {
            $Cisco::SNMP::LASTERROR = "CatOS does not support IPv6";
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
    if ($params{op} eq 'wr') {
        if ($params{catos}) {
            $Cisco::SNMP::LASTERROR = "CatOS does not support `copy run start'";
            return undef
        }
        # ccCopyEntryRowStatus (5 = createAndWait, 6 = destroy)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);

        if (!defined $response) {
            # copy run start NOT SUPPORTED - trying old way
            $response = $session->set_request('1.3.6.1.4.1.9.2.1.54.0', INTEGER, 1);
            if (defined $response) {
                return bless $cc, $class
            } else {
                $Cisco::SNMP::LASTERROR = "`copy run start' FAILED (new and old)";
                return undef
            }
        }

          # ccCopySourceFileType (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.3.' . $instance, INTEGER, $params{source});
          # ccCopyDestFileType (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.4.' . $instance, INTEGER, $params{dest})

    # TFTP PUT/GET (to/from device)
    } else {
        $response = _config_copy(\%params, $session, $instance);
        if ($response == 0) {
            return bless $cc, $class
        } elsif ($response == -1) {
            return undef
        }
        # $response == 1, continue ...
    }

    # ccCopyEntryRowStatus (4 = createAndGo, 6 = destroy)
    $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 1);

    # Check status, wait done
    $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance);
    if (!defined $response) {
        $Cisco::SNMP::LASTERROR = "$params{protocol} NOT SUPPORTED (after setup)";
        return undef
    }

    # loop and check response - error if timeout
    my $loop = 0;
    while ($response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance} <= 2) {
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance);
        if (!defined $response) {
            $Cisco::SNMP::LASTERROR = "IOS $params{protocol} `$params{op}' FAILED - cannot verify completion";
            return undef
        }
        if ($loop++ == $params{timeout}) {
            $Cisco::SNMP::LASTERROR = "IOS $params{protocol} `$params{op}' FAILED - timeout during completion verification";
            return undef
        }
        sleep 1
    }

    # Success
    if ($response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance} == 3) {
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.11.' . $instance);
        $cc->{StartTime} = $response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.11.' . $instance};
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.12.' . $instance);
        $cc->{EndTime}   = $response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.12.' . $instance};
        $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);
        return bless $cc, $class
    # Error
    } elsif ($response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.10.' . $instance} == 4) {
        $response = $session->get_request('1.3.6.1.4.1.9.9.96.1.1.1.1.13.' . $instance);
        $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);
        $Cisco::SNMP::LASTERROR = "IOS $params{protocol} `$params{op}' FAILED - " . $ioserr{$response->{'1.3.6.1.4.1.9.9.96.1.1.1.1.13.' . $instance}};
        return undef
    } else {
        $Cisco::SNMP::LASTERROR = "Cannot determine success or failure";
        return undef
    }
}

sub ccStartTime {
    my $self = shift;
    return $self->{StartTime}
}

sub ccEndTime {
    my $self = shift;
    return $self->{EndTime}
}

##################################################
# End Public Module
##################################################

##################################################
# Start Private subs
##################################################

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

    if ($params->{catos}) {
        $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.1.0', OCTET_STRING, $params->{server});
        $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.2.0', OCTET_STRING, $params->{file});
        $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.3.0', INTEGER, 1);
        if ($params->{op} eq 'put') {
            $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.4.0', INTEGER, 2)
        } else {
            $response = $session->set_request('1.3.6.1.4.1.9.5.1.5.4.0', INTEGER, 3)
        }

        # loop and check response - error if timeout
        $response = $session->get_request('1.3.6.1.4.1.9.5.1.5.5.0');
        my $loop = 0;
        while ($response->{'1.3.6.1.4.1.9.5.1.5.5.0'} == 1) {
            $response = $session->get_request('1.3.6.1.4.1.9.5.1.5.5.0');
            if ($loop++ == $params->{timeout}) {
                $Cisco::SNMP::LASTERROR = "CatOS TFTP `$params->{op}' FAILED - timeout during completion verification";
                return -1
            }
            sleep 1
        }

        if ($response->{'1.3.6.1.4.1.9.5.1.5.5.0'} == 2) {
            return 0
        } else {
            $Cisco::SNMP::LASTERROR = "CatOS TFTP `$params->{op}' FAILED - " . $caterr{$response->{'1.3.6.1.4.1.9.5.1.5.5.0'}};
            return -1
        }

    # IOS
    } else {
          # ccCopyEntryRowStatus (5 = createAndWait, 6 = destroy)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 6);
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $instance, INTEGER, 5);

          # ccCopyProtocol
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.2.' . $instance, INTEGER, $PROTO{$params->{protocol}});

        if (!defined $response) {
            $Cisco::SNMP::LASTERROR = "IOS TFTP `$params->{op}' NOT SUPPORTED - trying old way";
            if ($params->{protocol} ne 'tftp') {
                $Cisco::SNMP::LASTERROR = "Old way does not support `$params->{protocol}'";
                return -1
            }
            if ($params->{family} == $AF_INET6) {
                $Cisco::SNMP::LASTERROR = "IOS TFTP `$params->{op}' old way does not support IPv6";
                return -1
            }
            if ($params->{op} eq 'put') {
                $response = $session->set_request('1.3.6.1.4.1.9.2.1.50.' . $params->{server}, OCTET_STRING, $params->{file})
            } else {
                $response = $session->set_request('1.3.6.1.4.1.9.2.1.55.' . $params->{server}, OCTET_STRING, $params->{file})
            }
            if (defined $response) {
                return 0
            } else {
                $Cisco::SNMP::LASTERROR = "IOS TFTP `$params->{op}' FAILED (new and old)";
                return -1
            }
        }

        if ($params->{protocol} ne 'tftp') {
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.7.' . $instance, OCTET_STRING, $params->{username});
            if ($params->{protocol} ne 'rcp') {
                $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.8.' . $instance, OCTET_STRING, $params->{password});
            }
        }

          # ccCopySourceFileType [.3] (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
          # ccCopyDestFileType [.4] (1 = networkFile, 3 = startupConfig, 4 = runningConfig)
        if ($params->{op} eq 'put') {
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.3.' . $instance, INTEGER, 1);
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.4.' . $instance, INTEGER, $params->{dest})
        } else {
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.3.' . $instance, INTEGER, $params->{source});
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.4.' . $instance, INTEGER, 1)
        }
          # New way
          # ccCopyServerAddressType (1 = IPv4, 2 = IPv6)
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.15.' . $instance, INTEGER, ($params->{family} == AF_INET) ? 1 : 2);

        if (defined $response) {
              # ccCopyServerAddressRev1
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.16.' . $instance, OCTET_STRING, $params->{server})
        } else {
              # Deprecated
              # ccCopyServerAddress
            if ($params->{family} == $AF_INET6) {
                $Cisco::SNMP::LASTERROR = "ccCopyServerAddressRev1 not supported (requried for IPv6)";
                return -1
            }
            $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.5.' . $instance, IPADDRESS, $params->{server})
        }
          # ccCopyFileName
        $response = $session->set_request('1.3.6.1.4.1.9.9.96.1.1.1.1.6.' . $instance, OCTET_STRING, $params->{file})
    }
    return 1
}

##################################################
# End Private subs
##################################################

1;

__END__

##################################################
# Start POD
##################################################

=head1 NAME

Cisco::SNMP::Config - Configuration Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Config;

=head1 DESCRIPTION

The following methods are for configuration file management.  These
methods implement the C<CISCO-CONFIG-COPY-MIB> for configuration file
management.  If these operations fail, the older method in
C<OLD-CISCO-SYS-MIB> is tried.  All Catalyst OS operations are
performed against the C<CISCO-STACK-MIB>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP::Config object

  my $cm = Cisco::SNMP::Config->new([OPTIONS]);

Create a new B<Cisco::SNMP::Config> object with OPTIONS as optional parameters.
See B<Cisco::SNMP> for options.

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
  -password  Password for 'ftp', 'scp', 'sftp'      'cisco'
  -protocol  'ftp', 'rcp', 'scp', 'sftp', 'tftp'    'tftp'
  -source    'startup-config', 'running-config'     'running-config'
             or filename on TFTP server
  -server    Copy server address                    localhost
  -timeout   Seconds until timeout for completion   10
             check
  -username  Username for 'ftp', 'rcp', 'scp',      'cisco'
             'sftp'

The default behavior with no options is C<copy running-config
startup-config>.

B<NOTE:>  Use care when performing TFTP upload to startup-config.  This
B<MUST> be a B<FULL> configuration file as the config file is B<NOT>
merged, but instead B<OVERWRITES> the startup-config.

A hostname value for B<tftp> will be resolved to IPv4/v6 based on B<family>.
B<Family> is inherited from the value set in new() but can be overriden.
Providing a numeric address will also self-determine the IPv4/v6 address.

Allows the following accessors to be called.

=head3 ccStartTime() - return config copy start time

  $cc->ccStartTime();

Return the start time of the configuration copy operation relative to
system uptime.

=head3 ccEndTime() - return config copy end time

  $cc->ccEndTime();

Return the end time of the configuration copy operation relative to
system uptime.

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

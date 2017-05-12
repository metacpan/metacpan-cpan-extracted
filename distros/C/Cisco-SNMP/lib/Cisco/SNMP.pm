package Cisco::SNMP;

##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use strict;
use warnings;

use version;
our $VERSION = '1.02';

use Net::SNMP qw(:asn1 :snmp);

use Sys::Hostname;
use Socket qw(inet_ntoa AF_INET IPPROTO_TCP);

my $AF_INET6 = eval { Socket::AF_INET6() };
my $AF_UNSPEC = eval { Socket::AF_UNSPEC() };
my $AI_NUMERICHOST = eval { Socket::AI_NUMERICHOST() };
my $NI_NUMERICHOST = eval { Socket::NI_NUMERICHOST() };

our $LASTERROR;

##################################################
# Start Public Module
##################################################

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    my $family;
    my %params = (
        version => 1,
        port    => SNMP_PORT,
        timeout => 5
    );

    my %args;
    if (@_ == 1) {
        ($params{hostname}) = @_
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?family$/i) {
                 if ($args{$_} =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
                    if ($args{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
                        $params{domain} = 'udp';
                        $family = AF_INET
                    } else {
                        $params{domain} = 'udp6';
                        $family = $AF_INET6
                    }
                } else {
                    $LASTERROR = "Invalid family `$args{$_}'";
                    return undef
                }
            # pass through
            } else {
                $params{$_} = $args{$_}
            }
        }
    }

    # set default community string if not provided and SNMP version 1 or 2
    if (($params{version} =~ /[1,2]/) && !defined $params{community}) {
        $params{community} = 'private'
    }

    # hostname must be defined
    if (!defined $params{hostname}) {
        $params{hostname} = hostname
    }

    # resolve hostname our way
    if (defined(my $ret = _resolv($params{hostname}, $family))) {
        $params{hostname} = $ret->{addr};
        $family = $ret->{family};
        if ($family == AF_INET) {
            $params{domain} = 'udp'
        } else {
            $params{domain} = 'udp6'
        }
    } else {
        return undef
    }

    my ($session, $error) = Net::SNMP->session(%params);

    if (!defined $session) {
        $LASTERROR = "Error creating Net::SNMP object: $error";
        return undef
    }

    return bless {
                  %params,       # merge user parameters
                  'family' => $family,
                  '_SESSION_' => $session
                 }, $class
}

### WARNINGS - use of Cisco::SNMP directly
# our $LOADED = 0;
# sub import {
    # shift;
    # if ((@_ == 0) && ($LOADED == 0) && ((caller(1))[3] eq 'main::BEGIN')) {
        # my $warn = sprintf
            # "\n" .
            # "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" .
            # "'use Cisco::SNMP;' directly is deprecated.\n" .
            # "Instead, use the relevent sub module:\n" .
            # "'use Cisco::SNMP::<module>;'\n" .
            # "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
        # warnings::warnif($warn)
    # }
    # $LOADED++;
    # my @l = @_ ? @_ : qw(Config ARP Config CPU Entity Image Interface IP Line Memory Password ProxyPing Sensor System);
    # eval join("", map { "require Cisco::SNMP::" . (/(\w+)/)[0] . ";\n" } @l) or die "Error - $@";
# }

sub session {
    my $self = shift;
    return $self->{_SESSION_}
}

sub close {
    my $self = shift;
    $self->{_SESSION_}->close()
}

sub error {
    my $self = shift;
    
    my $e = $LASTERROR;
    undef $LASTERROR;
    return $e
}

no strict 'refs';
sub _mk_accessors_array_1 {
    my ($TYPE, $NAME) = @_;
    *{$TYPE . $NAME} = sub {
        my $self  = shift;
        my ($idx) = @_;

        if (!defined $idx) {
            $idx = 0
        } elsif ($idx !~ /^\d+$/) {
            $Cisco::SNMP::LASTERROR = "Invalid $TYPE index `$idx'";
            return undef
        }
        return $self->[$idx]->{$NAME}
    }
}

sub _mk_accessors_hash_1 {
    my ($TYPE, $NAME) = @_;
    *{$TYPE . $NAME} = sub {
        my $self  = shift;
        my ($idx) = @_;

        if (!defined $idx) {
            $idx = 0
        } elsif ($idx !~ /^\d+$/) {
            $Cisco::SNMP::LASTERROR = "Invalid $TYPE index `$idx'";
            return undef
        }
        return $self->{$idx}->{$NAME}
    }
}

sub _mk_accessors_hash_2 {
    my ($TYPE1, $TYPE2, $NAME) = @_;
    *{$TYPE2 . $NAME} = sub {
        my $self = shift;
        my ($idx1, $idx2) = @_;

        if (!defined $idx2) {
            $idx1 = $idx1 || 0;
            $idx2 = 0
        } elsif ($idx1 !~ /^\d+$/) {
            $Cisco::SNMP::LASTERROR = "Invalid $TYPE1 index `$idx1'";
            return undef
        } elsif ($idx2 !~ /^\d+$/) {
            $Cisco::SNMP::LASTERROR = "Invalid $TYPE2 index `$idx2'";
            return undef
        }
        return $self->{$idx1}->[$idx2]->{$NAME}
    }
}

use strict 'refs';

##################################################
# End Public Module
##################################################

##################################################
# Start Private subs
##################################################

sub _get_range {
    my ($opt) = @_;

    # If argument, it must be a number range in the form:
    #  1,9-11,7,3-5,15
    if ($opt !~ /^\d+([\,\-]\d+)*$/) {
        $LASTERROR = "Invalid range format `$opt'";
        return undef
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

sub _snmpwalk {
    my ($session, $oid) = @_;

    my (@oids, @vals);
    my $base = $oid;
    my $result = 0;

    while (defined($result = $session->get_next_request(varbindlist => [$oid]))) {
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
            return undef
        }
    }
    return (\@oids, \@vals)
}

##################################################
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
    if (!defined $family) {
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
    if (defined $h{port} && (($h{port} !~ /^\d{1,5}$/) || ($h{port} < 1) || ($h{port} > 65535))) {
        $LASTERROR = "Invalid port `$h{port}' in `$name'";
        return undef
    }
# END - host:port

    # address check
    # new way
    if (version->parse($Socket::VERSION) >= version->parse(1.94)) {
        my %hints = (
            family   => $AF_UNSPEC,
            protocol => IPPROTO_TCP,
            flags => $AI_NUMERICHOST
        );

        # numeric address, return
        my ($err, @getaddr) = Socket::getaddrinfo($h{host}, undef, \%hints);
        if (defined $getaddr[0]) {
            $h{addr}   = $h{host};
            $h{family} = $getaddr[0]->{family};
            return \%h
        }
    # old way
    } else {
        # numeric address, return
        my $ret = gethostbyname($h{host});
        if (defined $ret && (inet_ntoa($ret) eq $h{host})) {
            $h{addr}   = $h{host};
            $h{family} = AF_INET;
            return \%h
        }
    }

    # resolve
    # new way
    if (version->parse($Socket::VERSION) >= version->parse(1.94)) {
        my %hints = (
            family   => $family,
            protocol => IPPROTO_TCP
        );

        my ($err, @getaddr) = Socket::getaddrinfo($h{host}, undef, \%hints);
        if (defined $getaddr[0]) {
            my ($err, $address) = Socket::getnameinfo($getaddr[0]->{addr}, $NI_NUMERICHOST);
            if (defined $address) {
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
        if (defined $gethost[4]) {
            $h{addr} = inet_ntoa($gethost[4]);
            $h{family} = AF_INET;
            return \%h
        } else {
            $LASTERROR = "gethostbyname($h{host}) failed - $^E";
            return undef
        }
    }
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

Cisco::SNMP - Interface for Cisco Management

=head1 SYNOPSIS

  use Cisco::SNMP::Memory;

  my $cm = Cisco::SNMP::Memory->new(
      hostname  => '1.1.1.1',
      community => 'public'
  );

  my $mem = $cm->memory_info();
  print  "Memory Pool Name    |   Total(K)    |    Used(K)    |Percent(%)\n";
  for (0..$#{$mem}) {
      printf "%-20s|%15.2f|%15.2f|%7.2f\n", 
          $mem->memName($_), 
          $mem->memTotal($_) / 1000,
          $mem->memUsed($_) / 1000,
          $mem->memUsed($_) / $mem->memTotal($_) * 100
  }

=head1 DESCRIPTION

B<Cisco::SNMP> is a class implementing several management functions
for Cisco devices - mostly via SNMP.  B<Cisco::SNMP> uses the
B<Net::SNMP> module to do the SNMP calls.

B<Cisco::SNMP> is the successor to the now deprecated B<Cisco::Management>.

B<Cisco::SNMP> supports IPv6 on systems with IPv6 configured but 
requires B<Socket> version 1.94 or greater.  This may cause issues on 
Perl versions less than 5.14, where the default B<Socket> module
is of a lesser version.  The requirement stems from the use of the
C<getaddrinfo()> and C<getnameinfo()> functions not available on older
versions of B<Socket>.

=head1 METHODS

=head2 new() - create a new Cisco::SNMP object

  my $cm = Cisco::SNMP::_MODULE_->new([OPTIONS]);

Create a new B<Cisco::SNMP::_MODULE_> object - where B<_MODULE_> is a sub-module 
in the B<Cisco::SNMP> suite (see B<SEE ALSO>) - with OPTIONS as optional parameters.
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

Return the B<Net::SNMP> session object created by the B<Cisco::SNMP>
new() method.  This is useful to call B<Net::SNMP> methods directly without
having to create a new B<Net::SNMP> object.  For example:

  my $cm = Cisco::SNMP::Memory->new(
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

Close the session.

=head2 error() - print last error

  printf "Error: %s\n", $cm->error();

Return last error.

=head1 EXPORT

None.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
C<bin> install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 SEE ALSO

L<Cisco::SNMP::Config>, L<Cisco::SNMP::CPU>, 
L<Cisco::SNMP::Entity>, L<Cisco::SNMP::Interface>, 
L<Cisco::SNMP::Line>, L<Cisco::SNMP::Memory>, 
L<Cisco::SNMP::Password>, L<Cisco::SNMP::ProxyPing>, 
L<Cisco::SNMP::System>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut

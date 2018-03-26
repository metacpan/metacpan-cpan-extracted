package App::Netsync::Network; #XXX This package should be object-oriented.

=head1 NAME

App::Netsync::Network - methods for manipulating network structures

=head1 DESCRIPTION

This module is responsible for for manipulating an internal view of a network.

=head1 SYNOPSIS

 use App::Netsync 'devices_interfaces';
 use App::Netsync::Network;
 use feature 'say';

 my %node;
 $node{'ip'}       = '10.0.0.1';
 $node{'hostname'} = 'host1';
 $node{'session'}  = App::Netsync::SNMP::Session $node{'ip'};
 $node{'info'}     = App::Netsync::SNMP::Info $session;

 my $serial2if2ifName = device_interfaces ($node{'info'}->vendor,$node{'session'});

 node_initialize (\%node,$serial2if2ifName);
 say node_string \%node;
 node_dump \%node;

 # or

 device_initialize (\%node,$_,$serial2if2ifName->{$_}) foreach keys $serial2if2ifName;
 foreach my $serial (keys %{$node{'devices'}}) {
    my $device = $node{'devices'}{$serial};
    say device_string $device;
    device_dump $device;
 }

 # or

 foreach my $serial (keys %serial2if2ifName) {
    $node->{'devices'}{$serial} = \%device;
    my $device = $node{'devices'}{$serial};
    $device->{'node'} = $node;

    my $if2ifName = $serial2if2ifName{$serial};
    interface_initialize ($device,$if2ifName->{$_},$_) foreach keys %$if2ifName;
 }

 foreach my $serial (keys %{$node{'devices'}}) {
    my $device = $node{'devices'}{$serial};
    foreach my $ifName (keys %{$device->{'interfaces'}}) {
       my interface = device->{'interfaces'}{$ifName};
       say interface_string $interface;
       interface_dump $interface;
    }
 }


 my %nodes;
 $nodes{'10.0.0.1'} = \%node;
 $nodes{'10.0.0.2'}{'ip'} = '10.0.0.2';
 $nodes{'10.0.0.3'}{'ip'} = '10.0.0.3';
 $nodes{'10.0.0.4'}{'ip'} = '10.0.0.4';
 $nodes{'10.0.0.5'}{'ip'} = '10.0.0.5';

 my $n = node_find (\%nodes,'10.0.0.5');
 $n->{'ip'} == '10.0.0.5';

 $n->{'devices'}{'1A2B3C4D5E6F'}{'serial'} = '1A2B3C4D5E6F';

 my $d = device_find (\%nodes,'1A2B3C4D5E6F');
 $d->{'serial'} == '1A2B3C4D5E6F';

 $d->{'interfaces'}{'ethernet1/1/1'}{'ifName'} = ethernet1/1/1;

 my $i = interface_find ($n->{'devices'},'ethernet1/1/1');
 $i->{'ifName'} = 'ethernet1/1/1';

=cut


use 5.006;
use strict;
use warnings FATAL => 'all';
use feature 'say';
use autodie; #XXX Is autodie adequate?

use File::Basename;
use version;

our ($SCRIPT,$VERSION);
our %config;

BEGIN {
    ($SCRIPT)  = fileparse ($0,"\.[^.]*");
    ($VERSION) = version->declare('v4.0.0');

    require Exporter;
    our @ISA = ('Exporter');
    our @EXPORT = (
        'node_initialize','device_initialize','interface_initialize',
        'node_string'    ,'device_string'    ,'interface_string',
        'node_dump'      ,'device_dump'      ,'interface_dump',
        'node_find'      ,'device_find'      ,'interface_find',
    );

    $config{'Indent'}  = 4;
    $config{'Quiet'}   = 0;
    $config{'Verbose'} = 0;
}


=head1 METHODS

=head2 node_initialize

initialize a new network node

B<Arguments>

I<( $node , \%serial2if2ifName )>

=over 3

=item node

the node to initialize

C<$node>

 {
   'devices'  => {
                   $serial => $device,
                 },
   'hostname' => SCALAR,
   'info'     => SNMP::Info,
   'ip'       => SCALAR,
   'session'  => SNMP::Session,
 }

=item serial2if2ifName

a mapping of interfaces to devices (see App::Netsync::device_interfaces)

=back

=cut

sub node_initialize {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 2;
    my ($node,$serial2if2ifName) = @_;

    foreach my $serial (keys %$serial2if2ifName) {
        device_initialize ($node,$serial,$serial2if2ifName->{$serial});
    }
    return $node;
}


=head2 device_initialize

initialize a new network device

C<$device>

 {
   'interfaces' => {
                     $ifName => $interface,
                   },
   'node'       => $node,
   'identified' => SCALAR,
   'serial'     => $serial,
 }

B<Arguments>

I<( $node , $serial , \%if2ifName )>

=over 3

=item node

the node to add a new device to

=item serial

the serial number (unique identifier) of the new device  (see node_initialize)

=item if2ifName

a mapping of SNMP interface IIDs to interface names (see device_interfaces)

=back

=cut

sub device_initialize {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 3;
    my ($node,$serial,$if2ifName) = @_;
    $if2ifName //= {};

    $serial = uc $serial;
    $node->{'devices'}{$serial}{'serial'} = $serial;
    my $device = $node->{'devices'}{$serial};
    $device->{'node'} = $node;
    foreach my $if (keys %$if2ifName) {
        interface_initialize ($device,$if2ifName->{$if},$if);
    }
    $device->{'identified'} = 0;
    return $device;
}


=head2 interface_initialize

initialize a new network interface

C<$interface>

 {
   'device'     => $device,
   'ifName'     => $ifName,
   'IID'        => SCALAR,
   'info'       => {
                     $field => SCALAR,
                   },
   'identified' => SCALAR,
 }

B<Arguments>

I<( $device , $ifName , $IID [, \%fields ] )>

=over 3

=item device

the device to add a new interface to

=item ifName

the name of the new interface

=item IID

the IID of the new interface

=item fields

interface-specific key-value pairs

=back

=cut

sub interface_initialize {
    warn 'too few arguments'  if @_ < 3;
    warn 'too many arguments' if @_ > 4;
    my ($device,$ifName,$IID,$fields) = @_;
    $fields //= {};

    $device->{'interfaces'}{$ifName}{'ifName'} = $ifName;
    my $interface = $device->{'interfaces'}{$ifName};
    $interface->{'device'}     = $device;
    $interface->{'IID'}        = $IID;
    $interface->{'info'}{$_}   = $fields->{$_} foreach keys %$fields;
    $interface->{'identified'} = (scalar keys %$fields > 0) ? 1 : 0;
    return $interface;
}




################################################################################




=head2 node_string

converts $node structure(s) to strings

B<Arguments>

I<( @nodes )>

=over 3

=item nodes

an array of nodes to stringify

=back

=cut

sub node_string {
    warn 'too few arguments' if @_ < 1;
    my (@nodes) = @_;

    my @node_strings;
    foreach my $node (@nodes) {
        my $node_string;
        if (defined $node->{'ip'} and defined $node->{'hostname'}) {
            $node_string = $node->{'ip'}.' ('.$node->{'hostname'}.')';
        }
        push (@node_strings,$node_string);
    }
    return $node_strings[0] if @nodes == 1;
    return @node_strings;
}


=head2 device_string

converts $device structures to strings

B<Arguments>

I<( @devices )>

=over 3

=item devices

an array of devices to stringify

=back

=cut

sub device_string {
    warn 'too few arguments' if @_ < 1;
    my (@devices) = @_;

    my @device_strings;
    foreach my $device (@devices) {
        my $device_string;
        if (defined $device->{'serial'} and defined $device->{'node'}) {
            $device_string = $device->{'serial'}.' at '.node_string $device->{'node'};
        }
        push (@device_strings,$device_string);
    }
    return $device_strings[0] if @devices == 1;
    return @device_strings;
}


=head2 interface_string

converts $interface structures to strings

B<Arguments>

I<( @interfaces )>

=over 3

=item interfaces

an array of devices to stringify

=back

=cut

sub interface_string {
    warn 'too few arguments' if @_ < 1;
    my (@interfaces) = @_;

    my @interface_strings;
    foreach my $interface (@interfaces) {
        my $interface_string;
        if ($interface->{'ifName'} // $interface->{'IID'} // $interface->{'device'} // 0) {
            $interface_string  = $interface->{'ifName'}.' ('.$interface->{'IID'}.')';
            $interface_string .= ' on '.device_string $interface->{'device'};
        }
        push (@interface_strings,$interface_string);
    }
    return $interface_strings[0] if @interfaces == 1;
    return @interface_strings;
}




################################################################################




=head2 node_dump

prints a node structure

B<Arguments>

I<( @nodes )>

=over 3

=item nodes

an array of nodes to print

=back

=cut

sub node_dump {
    warn 'too few arguments' if @_ < 1;
    my (@nodes) = @_;

    foreach my $node (@nodes) {
        say node_string $node;

        my $device_count = 0;
        if (defined $node->{'devices'}) {
            $device_count = scalar keys %{$node->{'devices'}};

            my ($identified_device_count,$interface_count,$identified_interface_count) = (0,0,0);
            foreach my $serial (keys %{$node->{'devices'}}) {
                my $device = $node->{'devices'}{$serial};
                ++$identified_device_count if $device->{'identified'};
                next unless defined $device->{'interfaces'};
                $interface_count += scalar keys %{$device->{'interfaces'}};
                foreach my $ifName (keys %{$device->{'interfaces'}}) {
                    my $interface = $device->{'interfaces'}{$ifName};
                    ++$identified_interface_count if $interface->{'identified'};
                }
            }
            print ((' 'x$config{'Indent'}).$device_count.' device');
            print 's' if $device_count > 1;
            print ' ('.$identified_device_count.' identified)' if $identified_device_count > 0;
            print "\n";
            print ((' 'x$config{'Indent'}).$interface_count.' interface');
            print 's' if $interface_count > 1;
            print ' ('.$identified_interface_count.' identified)' if $identified_interface_count > 0;
            print "\n";
        }

        if (defined $node->{'info'}) {
            my $info = $node->{'info'};
            if ($device_count == 1) {
                #say ((' 'x$config{'Indent'}).$info->class);
                say ((' 'x$config{'Indent'}).$info->vendor.' '.$info->model);
                say ((' 'x$config{'Indent'}).$info->serial);
            }
        }
    }
    say scalar (@nodes).' nodes' if @nodes > 1;
}


=head2 device_dump

prints a device structure

B<Arguments>

I<( @devices )>

=over 3

=item devices

an array of devices to print

=back

=cut

sub device_dump {
    warn 'too few arguments' if @_ < 1;
    my (@devices) = @_;

    foreach my $device (@devices) {
        say device_string $device;

        if (defined $device->{'identified'}) {
            say ((' 'x$config{'Indent'}).(($device->{'identified'}) ? 'identified' : 'unidentified'));
        }

        if (defined $device->{'interfaces'}) {
            my $interface_count = scalar keys %{$device->{'interfaces'}};
            my $identified_interface_count = 0;
            foreach my $ifName (keys %{$device->{'interfaces'}}) {
                my $interface = $device->{'interfaces'}{$ifName};
                ++$identified_interface_count if $interface->{'identified'};
            }
            print ((' 'x$config{'Indent'}).$interface_count.' interface');
            print 's' if $interface_count > 1;
            say ' ('.$identified_interface_count.' identified)';
        }
    }
    say scalar (@devices).' devices' if @devices > 1;
}


=head2 interface_dump

prints an interface structure

B<Arguments>

I<( @interfaces )>

=over 3

=item interfaces

an array of interfaces to print

=back

=cut

sub interface_dump {
    warn 'too few arguments' if @_ < 1;
    my (@interfaces) = @_;

    foreach my $interface (@interfaces) {
        say interface_string $interface;

        if (defined $interface->{'identified'}) {
            say ((' 'x$config{'Indent'}).(($interface->{'identified'}) ? 'identified' : 'unidentified'));
        }

        if (defined $interface->{'info'}) {
            foreach my $field (sort keys %{$interface->{'info'}}) {
                print ((' 'x$config{'Indent'}).$field.': ');
                say (($interface->{'info'}{$field} =~ /[\S]+/) ? $interface->{'info'}{$field} : '(empty)');
            }
        }
    }
    say scalar (@interfaces).' interfaces' if @interfaces > 1;
}




################################################################################




=head2 node_find

check for a node in a set of nodes

B<Arguments>

I<( \%nodes , $ip )>

=over 3

=item nodes

an array of nodes to search

=item ip

the IP address of the node

=back

=cut

sub node_find {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 2;
    my ($nodes,$ip) = @_;

    return $nodes->{$ip};
}


=head2 device_find

check for a device in a set of nodes

B<Arguments>

I<( \%nodes , $serial )>

=over 3

=item nodes

an array of nodes to search

=item serial

a unique device identifier

=back

=cut

sub device_find {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 2;
    my ($nodes,$serial) = @_;
    $serial = uc $serial;

    foreach my $ip (keys %$nodes) {
        my $node = $nodes->{$ip};
        if (defined $node->{'devices'}{$serial}) {
            my $device = $node->{'devices'}{$serial};
            $device->{'identified'} = 1;
            return $device;
        }
    }
    return undef;
}


=head2 interface_find

check for a interface in a set of devices

B<Arguments>

I<( $devices , $ifName )>

=over 3

=item devices

an array of devices to search

=item ifName

a unique interface identifier

=back

=cut

sub interface_find {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 2;
    my ($devices,$ifName) = @_;

    foreach my $serial (keys %$devices) {
        my $device = $devices->{$serial};
        if (defined $device->{'interfaces'}{$ifName}) {
            my $interface = $device->{'interfaces'}{$ifName};
            $interface->{'identified'} = 1;
            return $interface;
        }
    }
    return undef;
}


=head1 AUTHOR

David Tucker, C<< <dmtucker at ucsc.edu> >>

=head1 BUGS

B<I<This module should be changed to use object-orientation.
    Until then, all of the included functions are exported!>>

Please report any bugs or feature requests to C<bug-netsync at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Netsync>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc App::Netsync

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Netsync>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Netsync>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Netsync>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Netsync/>

=back

=head1 LICENSE

Copyright 2013 David Tucker.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut


1;

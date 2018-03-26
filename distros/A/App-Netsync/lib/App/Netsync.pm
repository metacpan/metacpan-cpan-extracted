package App::Netsync;

=head1 NAME

App::Netsync - network/database synchronization library

=head1 DESCRIPTION

This package can discover a network and synchronize it with a database.

=head1 SYNOPSIS

 use App::Netsync;

 App::Netsync::configure({
     'Table'          => 'assets',
     'DeviceField'    => 'SERIAL_NUMBER',
     'InterfaceField' => 'PORT',
     'InfoFields'     => ['BLDG','ROOM','JACK'],
 },{
     'domain'         => 'example.com',
 },{
     'Version'        => 2,
     'Community'      => 'example',
 },{
     'DBMS'           => 'pg',
     'Server'         => 'pg.example.com',
     'Port'           => 5432,
     'Database'       => 'example_db',
     'Username'       => 'user',
     'Password'       => 'pass',
 });

 my $nodes = App::Netsync::discover ('DNS','host[0-9]+');
 App::Netsync::identify ($nodes,'DB',1);
 App::Netsync::update ($nodes);

=cut


use 5.006;
use strict;
use warnings FATAL => 'all';

use autodie; #XXX Is autodie adequate?
use feature 'say';

use DBI;
use File::Basename;
use Net::DNS;
use Text::CSV;
use version;

use App::Netsync::Network;
use App::Netsync::Scribe 'note';
use App::Netsync::SNMP;

our ($SCRIPT,$VERSION);
our %config;

BEGIN {
    ($SCRIPT)  = fileparse ($0,"\.[^.]*");
    ($VERSION) = version->declare('v4.0.0');

    require Exporter;
    our @ISA = ('Exporter');
    our @EXPORT_OK = ('device_interfaces');
}

INIT { # These are described in the "Available Environment Setings" POD below.
    $config{'Indent'}  = 4;
    $config{'Quiet'}   = 0;
    $config{'Verbose'} = 0;

    $config{'Table'}          = undef;
    $config{'DeviceField'}    = undef;
    $config{'InterfaceField'} = undef;
    $config{'InfoFields'}     = undef;
    $config{'SyncOID'}        = 'ifAlias';

    $config{'DeviceOrder'} = 4;

    $config{'NodeLog'}     = '/var/log/'.$SCRIPT.'/nodes.log';
    $config{'ConflictLog'} = '/var/log/'.$SCRIPT.'/conflicts.log';
    $config{'UpdateLog'}   = '/var/log/'.$SCRIPT.'/updates.log';

    $config{'DNS'}  = undef;
    $config{'SNMP'} = undef;
    $config{'DB'}   = undef;
}


=head1 METHODS

=head2 configure

configure the operating environment

B<Arguments>

I<( \%Netsync [, \%DNS [, \%SNMP [, \%DB ] ] ] )>

=over 3

=item Netsync

key-value pairs of Netsync environment settings

B<Available Environment Settings>

I<Note: If a default is not specified, the setting is required.>

=over 4

=item ConflictLog

where to log conflicts

default: F</var/log/E<lt>script nameE<gt>/conflicts.log>

=item DeviceField

the table field to use as a unique ID for devices

=item DeviceOrder

the width of fields specifying node and device counts

default: 4

I<Example>

=over 5

=item DeviceOrder = 3 (i.e. nodes < 1000), 500 nodes

 > discovering (using DNS)... 500 nodes (50 skipped), 600 devices (50 stacks)

=item DeviceOrder = 9 (i.e. nodes < 1000000000), 500 nodes

 > discovering (using DNS)...       500 nodes (50 skipped), 600 devices (50 stacks)

=item DeviceOrder = 1 (i.e. nodes < 10), 20 nodes !

 > discovering (using DNS)... 111111111120 nodes (2 skipped), 24 devices (2 stacks)

=back

=item Indent

the number of spaces to use when output is indented

default: 4

=item InfoFields

which table fields to synchronize with device interfaces

=item InterfaceField

which table field to use as a unique ID for device interfaces

=item NodeLog

where to log all probed nodes

default: F</var/log/E<lt>script nameE<gt>/nodes.log>

=item Quiet

Print nothing.

default: 0

=item SyncOID

which OID to send synchronized information to when updating

default: ifAlias

=item Table

which database table to use

=item UpdateLog

where to log all modifications made to the network

default: F</var/log/E<lt>script nameE<gt>/updates.log>

=item Verbose

Print everything.

Note: Quiet mode overrides Verbose mode.

default: 0

=back

I<Netsync requires the following settings to use a DBMS:>

=over 4

=item DBMS

the database platform to use

=item Server

the server containing the database to use

=item Port

the port to contact the database server on

=item Database

the database to connect to

=item Username

the user to connect to the database as

=item Password

the authentication key to use to connect to the database

=back

I<Netsync requires the following settings to use SNMP:>

=over 4

=item MIBdir

the location of MIBs required by Netsync

default: F</usr/share/E<lt>script nameE<gt>/mib>

=back

=item DNS

See Net::DNS documentation for more acceptable settings.

=item SNMP

See SNMP::Session documentation for more acceptable settings.

=item DB

See DBI documentation for more acceptable settings.

=back

=cut

sub configure {
    warn 'too few arguments'  if @_ < 1;
    warn 'too many arguments' if @_ > 4;
    my ($Netsync,$DNS,$SNMP,$DB) = @_;

    $config{$_} = $Netsync->{$_} foreach keys %$Netsync;

    my $success = 1;
    if ((defined $DB->{'Server'}   or  defined $DB->{'Port'}      or
         defined $DB->{'DBMS'}     or  defined $DB->{'Database'}  or
         defined $DB->{'Username'} or  defined $DB->{'Password'}) and not
        (defined $DB->{'Server'}   and defined $DB->{'Port'}      and
         defined $DB->{'DBMS'}     and defined $DB->{'Database'}  and
         defined $DB->{'Username'} and defined $DB->{'Password'})) {
        warn 'DBMS configuration is inadequate.';
        $success = 0;
    }

    unless (App::Netsync::SNMP::configure($SNMP,[
        'IF-MIB','ENTITY-MIB',                                # standard
        'CISCO-STACK-MIB',                                    # Cisco
        'FOUNDRY-SN-AGENT-MIB','FOUNDRY-SN-SWITCH-GROUP-MIB', # Brocade
        'SEMI-MIB', # 'HP-SN-AGENT-MIB'                         # HP #XXX Is HP-SN-AGENT-MIB analgous to FOUNDRY-SN-AGENT-MIB?
    ])) {
        warn 'App::Netsync::SNMP misconfiguration';
        $success = 0;
    }
    $config{'DB'}  = $DB  if defined $DB;
    $config{'DNS'} = $DNS if defined $DNS;
    return $success;
}


=head2 device_interfaces

discover all the devices and corresponding interfaces of a potentially stacked node

B<Arguments>

I<( $vendor , $session )>

=over 3

=item vendor

a value returned from SNMP::Info::vendor

B<Supported Vendors>

=over 4

=item brocade/foundry

=item cisco

=item hp

=back

=item session

an SNMP::Session object

=back

B<Example>

=over 3

C<device_interfaces ($node-E<gt>{'info'}-E<gt>vendor,$node-E<gt>{'session'});>

 {
   '1A2B3C4D5E6F' => {
                       '1001' => 'ethernet1/1/1',
                       '1002' => 'ethernet1/1/2',
                       ...
                     },
   '2B3C4D5E6F7G' => {
                       '2001' => 'ethernet2/1/1',
                       '2002' => 'ethernet2/1/2',
                       ...
                     },
   ...
 }

=back

=cut

sub device_interfaces {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 2;
    my ($vendor,$session) = @_;

    my %serial2if2ifName; # This will hold interface IIDs and names for each serial.
    {
        my %if2ifName; # This will associate interface IIDs with ifNames or ifDescrs.
        {
            my ($types) = App::Netsync::SNMP::get1 ([['.1.3.6.1.2.1.2.2.1.3' => 'ifType']],$session); # IF-MIB
            my ($ifNames,$ifs) = App::Netsync::SNMP::get1 ([
                ['.1.3.6.1.2.1.2.2.1.2'    => 'ifDescr'], # IF-MIB
                ['.1.3.6.1.2.1.31.1.1.1.1' => 'ifName'],  # IF-MIB
            ],$session); # IF-MIB
            foreach my $i (keys @$ifs) { # Make sure interface names are defined.
                unless (defined $types->[$i] and defined $ifNames->[$i]) {
                    warn 'malformed IF-MIB results';
                    next;
                }
                $if2ifName{$ifs->[$i]} = $ifNames->[$i] if $types->[$i] =~ /^(?!1|24|53)[0-9]+$/; # Exclude virtual interfaces.
            }
        }

        my @serials;
        { # ENTITY-MIB
            my ($serials) = App::Netsync::SNMP::get1 ([['.1.3.6.1.2.1.47.1.1.1.1.11' => 'entPhysicalSerialNum']],$session);
            if (defined $serials) {
                my ($classes) = App::Netsync::SNMP::get1 ([['.1.3.6.1.2.1.47.1.1.1.1.5' => 'entPhysicalClass']],$session);
                foreach my $i (keys @$classes) {
                    push (@serials,$serials->[$i]) if $classes->[$i] =~ /3/ and $serials->[$i] !~ /[^[:ascii:]]/; # Include only chassis serials.
                }
            }
        }
        unless (@serials > 0) {
            my $serials;
            {
                my $cisco = sub { # CISCO-STACK-MIB
                    ($serials) = App::Netsync::SNMP::get1 ([
                        ['.1.3.6.1.4.1.9.5.1.3.1.1.3'  => 'moduleSerialNumber'],
                        ['.1.3.6.1.4.1.9.5.1.3.1.1.26' => 'moduleSerialNumberString'],
                    ],$session);
                };
                my $brocade = sub { # FOUNDRY-SN-AGENT-MIB?
                    ($serials) = App::Netsync::SNMP::get1 ([
                        ['.1.3.6.1.4.1.1991.1.1.1.4.1.1.2' => 'snChasUnitSerNum'],
                        ['.1.3.6.1.4.1.1991.1.1.1.1.2'     => 'snChasSerNum'], # stacks not supported
                    ],$session);
                };
                my $hp = sub { # SEMI-MIB #XXX HP-SN-AGENT-MIB
                    ($serials) = App::Netsync::SNMP::get1 ([
                        ['.1.3.6.1.4.1.11.2.36.1.1.2.9'        => 'hpHttpMgSerialNumber'],
                        #['.1.3.6.1.4.1.11.2.36.1.1.5.1.1.10'   => 'hpHttpMgDeviceSerialNumber'],
                        #['.1.3.6.1.4.1.11.2.3.7.11.12.1.1.1.2' => 'snChasSerNum'], #XXX HP-SN-AGENT-MIB stacks not supported?
                    ],$session);
                };
                my %vendors = (
                    'cisco'   => $cisco,
                    'brocade' => $brocade,
                    'foundry' => $brocade,
                    'hp'      => $hp,
                    'unsupported' => sub {
                        warn $vendor.' devices are not supported.';
                    },
                );
                ($vendors{$vendor} || $vendors{'unsupported'})->();
            }

            foreach my $serial (@$serials) {
                push (@serials,$serial) if $serial !~ /[^[:ascii:]]/; # ASCII only!
            }
        }
        if (@serials == 0) { return undef; } # No serials found.
        if (@serials == 1) { # Non-stacked node containing 1 device.
            $serial2if2ifName{$serials[0]} = \%if2ifName;
        }
        else {
            my %if2serial; # This will associate interface IIDs with the serial of the corresponding chassis.
            {
                my $cisco = sub { # CISCO-STACK-MIB
                    my ($port2if) = App::Netsync::SNMP::get1 ([['.1.3.6.1.4.1.9.5.1.4.1.1.11' => 'portIfIndex']],$session);
                    my @port2serial;
                    {
                        my ($port2module) = App::Netsync::SNMP::get1 ([['.1.3.6.1.4.1.9.5.1.4.1.1.1' => 'portModuleIndex']],$session);
                        my %module2serial; # A module is basically a chassis IID.
                        {
                            my ($serials,$modules) = App::Netsync::SNMP::get1 ([
                                ['.1.3.6.1.4.1.9.5.1.3.1.1.3'  => 'moduleSerialNumber'],
                                ['.1.3.6.1.4.1.9.5.1.3.1.1.26' => 'moduleSerialNumberString'],
                            ],$session);
                            @module2serial{@$modules} = @$serials;
                        }
                        push (@port2serial,$module2serial{$_}) foreach @$port2module;
                    }
                    @if2serial{@$port2if} = @port2serial;
                };
                my $brocade = sub { # FOUNDRY-SN-SWITCH-GROUP-MIB
                    my ($port2if) = App::Netsync::SNMP::get1 ([['.1.3.6.1.4.1.1991.1.1.3.3.1.1.38' => 'snSwPortIfIndex']],$session);
                    my @port2serial;
                    {
                        my ($port2umi) = App::Netsync::SNMP::get1 ([['.1.3.6.1.4.1.1991.1.1.3.3.1.1.39' => 'snSwPortDescr']],$session);
                        my %module2serial;
                        {
                            my ($serials,$modules) = App::Netsync::SNMP::get1 ([['.1.3.6.1.4.1.1991.1.1.1.4.1.1.2' => 'snChasUnitSerNum']],$session); #XXX FOUNDRY-SN-AGENT-MIB?
                            @module2serial{@$modules} = @$serials;
                        }
                        foreach (@$port2umi) {
                            push (@port2serial,$module2serial{$+{'unit'}}) if m{^(?<unit>[0-9]+)(/[0-9]+)+$};
                        }
                    }
                    @if2serial{@$port2if} = @port2serial;
                };
                my %stack_vendors = (
                    'cisco'   => $cisco,
                    'brocade' => $brocade,
                    'foundry' => $brocade,
                    'unsupported' => sub {
                        warn $vendor.' stacks are not supported.';
                    },
                );
                ($stack_vendors{$vendor} || $stack_vendors{'unsupported'})->();
            }

            foreach my $if (keys %if2serial) { # Filter out interfaces without an associated serial.
                $serial2if2ifName{$if2serial{$if}}{$if} = $if2ifName{$if} if defined $if2serial{$if};
            }
        }
    }
    return \%serial2if2ifName;
}




################################################################################




sub recognize { # A recognizable node has a serial that netsync can retrieve.
    my (@nodes) = @_;

    my $serial_count = 0;
    foreach my $node (@nodes) {

        # Establish a connection to the node.
        my ($session,$info) = App::Netsync::SNMP::Info $node->{'ip'};
        if (defined $info) {
            $node->{'session'} = $session;
            $node->{'info'}    = $info;
        }
        else { # Otherwise, consider it inactive.
            note ($config{'NodeLog'},node_string ($node).' inactive');
            say node_string ($node).' inactive' if $config{'Verbose'};
            next;
        }

        # Retrieve the serials of devices at the node.
        my $serial2if2ifName = device_interfaces ($node->{'info'}->vendor,$node->{'session'});
        if (defined $serial2if2ifName) {
            my @serials = keys %$serial2if2ifName;
            note ($config{'NodeLog'},node_string ($node).' '.join (' ',@serials));
            node_initialize ($node,$serial2if2ifName);
            $serial_count += @serials;
        }
        else { # Otherwise, consider the device unrecognized.
            note ($config{'NodeLog'},node_string ($node).' unrecognized');
            say node_string ($node).' unrecognized' if $config{'Verbose'};
            next;
        }

        # Show the user what's been found if necessary.
        node_dump $node if $config{'Verbose'};
    }
    return $serial_count;
}


=head2 discover

search the network for active nodes

B<Arguments>

I<[ ( $node_source [, $host_pattern ] ) ]>

=over 3

=item node_source

where to get nodes from (DNS, STDIN, or a filename)

default: DNS

=item host_pattern

a regular expression to match hostnames from the list of retrieved nodes

default: [^.]+

=back

=cut

sub discover {
    warn 'too many arguments' if @_ > 2;
    my ($node_source,$host_pattern) = @_;
    $node_source  //= 'DNS';
    $host_pattern //= '[^.]+';

    my $nodes = {};

    unless ($config{'Quiet'}) {
        print 'discovering';
        print ' (using '.(($node_source eq 'DNS') ? 'DNS' : 'STDIN').')';
        print '...';
        print (($config{'Verbose'}) ? "\n" : (' 'x$config{'DeviceOrder'}).'0');
    }

    my @zone;
    { # Retrieve relevant nodes.
        my %inputs = (
            'DNS' => sub {
                unless (defined $config{'DNS'}) {
                    warn 'DNS has not been configured.';
                    return undef;
                }
                if (defined $config{'DNS'}{'nameservers'}) {
                    $config{'DNS'}{'nameservers'} = (ref $config{'DNS'}{'nameservers'}) ?
                                                         $config{'DNS'}{'nameservers'} :
                                                        [$config{'DNS'}{'nameservers'}];
                }
                if (defined $config{'DNS'}{'searchlist'}) {
                    $config{'DNS'}{'searchlist'}  = (ref $config{'DNS'}{'searchlist'}) ?
                                                         $config{'DNS'}{'searchlist'} :
                                                        [$config{'DNS'}{'searchlist'}];
                }
                my $resolver = Net::DNS::Resolver->new(%{$config{'DNS'}});
                $resolver->print if $config{'Verbose'};
                push (@zone,$_->string) foreach $resolver->axfr;
            },
            'default' => sub { @zone = split("\n",$node_source); },
        );
        ($inputs{$node_source} || $inputs{'default'})->();
    }

    my ($skip_count,$device_count,$stack_count) = (0,0,0);
    foreach (@zone) {
        if (/^(?<host>$host_pattern)(\.(?:\S+\.)+\s+(?:\d+)\s+(?:\S+)\s+(?:A|AAAA))?\s+(?<ip>.+)$/) { #XXX Upgrade this to support a list of IP addresses (It currently supports dig output).
            $nodes->{$+{'ip'}}{'ip'} = $+{'ip'};
            my $node = $nodes->{$+{'ip'}};
            $node->{'hostname'} = $+{'host'};
            $node->{'RFC1035'}  = $_;

            # Gather information about the node.
            my $serial_count = recognize $node;
            if ($serial_count < 1) { # Otherwise, skip it.
                ++$skip_count;
                delete $nodes->{$+{'ip'}};
            }
            else {
                $device_count += $serial_count;
                ++$stack_count if $serial_count > 1;

                # Show the user how many nodes have been discovered if necessary.
                unless ($config{'Quiet'} or $config{'Verbose'}) {
                    print  "\b"x$config{'DeviceOrder'};
                    printf ('%'.$config{'DeviceOrder'}.'d',scalar keys %$nodes);
                }
            }
        }
    }

    # Show the user what's been found if necessary.
    unless ($config{'Quiet'}) {
        my $node_count = scalar keys %$nodes;
        print $node_count if $config{'Verbose'};
        print ' node';
        print 's' if $node_count != 1;
        print ' ('.$skip_count.' skipped)' if $skip_count > 0;
        print ', '.$device_count.' device';
        print 's' if $device_count != 1;
        if ($stack_count > 0) {
            print ' ('.$stack_count.' stack';
            print 's' if $stack_count != 1;
            print ')';
        }
        print "\n";
    }

    return $nodes;
}




################################################################################




sub synchronize { # Use information in the databse to update discovered nodes.
    warn 'too few arguments'  if @_ < 4;
    warn 'too many arguments' if @_ > 4;
    my ($nodes,$identified,$auto_match,$rows) = @_;

    my $conflict_count = 0;
    foreach my $row (@$rows) {
        my $serial = uc $row->{$config{'DeviceField'}};
        my $ifName = $row->{$config{'InterfaceField'}};

        # Identify the device indicated by the given database entry.
        my $node = $identified->{$serial};
        unless (defined $node) {
            my $device = device_find ($nodes,$serial);
            next unless defined $device; # Otherwise, skip to the next entry.
            $identified->{$serial} = $node = $device->{'node'};
        }

        # Identify the interface indicated by the given database entry.
        my $device = $node->{'devices'}{$serial};
        if ($auto_match and not defined $device->{'interfaces'}{$ifName}) {
            foreach (sort keys %{$device->{'interfaces'}}) {
                if (/[^0-9]$ifName$/) {
                    $ifName = $row->{$config{'InterfaceField'}} = $_;
                    last;
                }
            }
        }

        { # Detect conflicts.
            my $new_conflict_count = 0;
            if (defined $device->{'interfaces'}{$ifName}) {
                my $interface = $device->{'interfaces'}{$ifName};
                if ($interface->{'identified'}) { # The database has a duplicate interface (only the first is used).
                    ++$new_conflict_count;
                    note ($config{'ConflictLog'},interface_string ($interface).' duplicate');
                }
                else {
                    $interface->{'identified'} = 1;
                    foreach my $field (@{$config{'InfoFields'}}) { # Grab data to be pushed to the device.
                        $interface->{'info'}{$field} = $row->{$field};
                    }

                    # Show the user what's been found if necessary.
                    interface_dump $interface if $config{'Verbose'};
                }
            }
            else { # An interface in the database could not be found on the indicated device.
                ++$new_conflict_count;
                note ($config{'ConflictLog'},device_string ($device).' '.$ifName.' mismatch');
            }
            $conflict_count += $new_conflict_count;
        }
    }
    return $conflict_count;
}

=head2 identify

identify discovered nodes in a database

B<Arguments>

I<( \%nodes [, $data_source [, $auto_match ] ] )>

=over 3

=item nodes

the discovered nodes to identify

=item data_source

the location of the database (DB or a filename)

default: DB

=item auto_match

whether to enable interface automatching

default: 0

=back

=cut

sub identify {
    warn 'too few arguments'  if @_ < 1;
    warn 'too many arguments' if @_ > 3;
    my ($nodes,$data_source,$auto_match) = @_;
    $data_source //= 'DB';
    $auto_match  //= 0;

    unless ($config{'Quiet'}) {
        print 'identifying';
        print ' (using '.$data_source.')...';
        print (($config{'Verbose'}) ? "\n" : (' 'x$config{'DeviceOrder'}).'0');
    }

    my @data;
    { # Retrieve database.

        unless (defined $config{'DeviceField'}    and
                defined $config{'InterfaceField'} and
                defined $config{'InfoFields'}) {
            warn 'Database fields have not been configured.';
            return undef;
        }

        # Initialize output table headers.
        my $fields = $config{'DeviceField'}.','.$config{'InterfaceField'};
        $fields .= ','.join (',',sort @{$config{'InfoFields'}});

        my %inputs = (
            'DB' => sub {
                my %drivers = DBI->installed_drivers;
                say $_ foreach values %drivers; exit; #XXX debug
                unless (defined $config{'DB'}) {
                    warn 'A database has not been configured.';
                    return undef;
                }

                # Connect to the database.
                my $DSN  =       'dbi:'.$config{'DBMS'};
                   $DSN .=     ':host='.$config{'Server'};
                   $DSN .=     ';port='.$config{'Port'};
                   $DSN .= ';database='.$config{'Database'};
                my $db = DBI->connect($DSN,$config{'Username'},$config{'Password'},$config{'DB'});
                my $query = $db->prepare('SELECT '.$fields.' FROM '.$config{'Table'});
                $query->execute;
                @data = @{$query->fetchall_arrayref({})};
                $db->disconnect;
            },
            'default' => sub { # Read a CSV file specified with the database option (-d).
                open (my $db,'<',$data_source);

                my $parser = Text::CSV->new;
                chomp (my @fields = split (',',<$db>));
                $parser->column_names(@fields);

                # Filter out fields that are not needed,
                # and verify the presence of necessary fields.
                my $removed_field_count = 0;
                foreach my $i (keys @fields) {
                    $i -= $removed_field_count;
                    unless ($fields =~ /(^|,)$fields[$i](,|$)/) {
                        ++$removed_field_count;
                        splice (@fields,$i,1);
                    }
                }
                die 'incompatible database' unless @fields == scalar split (',',$fields);

                foreach my $row (@{$parser->getline_hr_all($db)}) {
                    my $entry = {};
                    $entry->{$_} = $row->{$_} foreach @fields;
                    push (@data,$entry);
                }

                close $db;
            },
        );
        ($inputs{$data_source} || $inputs{'default'})->();
    }

    my $conflict_count = 0;
    {
        my %identified; # $identified{$serial} == $node

        ROW : foreach my $row (@data) {
            my $valid = [
                $config{'DeviceField'},
                $config{'InterfaceField'},
            ];
            foreach my $field (@$valid) { # Verify necessary fields aren't empty.
                next ROW unless defined $row->{$field} and $row->{$field} =~ /\S+/; # Otherwise, skip to the next entry.
            }

            # Synchronize the entry with gathered info.
            $conflict_count += synchronize ($nodes,\%identified,$auto_match,[$row]);

            # Show the user how many nodes have been identified if necessary.
            unless ($config{'Quiet'} or $config{'Verbose'}) {
                print  "\b"x$config{'DeviceOrder'};
                printf ('%'.$config{'DeviceOrder'}.'d',scalar keys %identified);
            }
        }

        # Show the user what's been found if necessary.
        unless ($config{'Quiet'}) {
            print scalar keys %identified if $config{'Verbose'};
            print ' synchronized';
            print ' ('.$conflict_count.' conflicts)' if $conflict_count > 0;
            print "\n";
        }
    }

    # Search for network devices and interfaces that were not identified in the database.
    foreach my $ip (sort keys %$nodes) {
        my $node = $nodes->{$ip};
        foreach my $serial (sort keys %{$node->{'devices'}}) {
            my $device = $node->{'devices'}{$serial};
            unless ($device->{'identified'}) {
                note ($config{'ConflictLog'},device_string ($device).' unidentified');
                next;
            }
            foreach my $ifName (sort keys %{$device->{'interfaces'}}) {
                my $interface = $device->{'interfaces'}{$ifName};
                unless ($interface->{'identified'}) {
                    note ($config{'ConflictLog'},interface_string ($interface).' unidentified');
                    next;
                }
            }
        }
    }
}




################################################################################




=head2 update

push information to interfaces

B<Arguments>

I<( \%nodes )>

=over 3

=item nodes

the nodes to update

=back

B<Example>

C<update $nodes;>

                           Table
 ---------------------------------------------------------
 |  DeviceField  |  InterfaceField  |  InfoFields...     |
 ---------------------------------------------------------         =============
 |   (serial)    |     (ifName)     |(interface-specific)|   -->   || SyncOID ||
 |                          ...                          |         =============
 ---------------------------------------------------------              (device)

=cut

sub update {
    warn 'too few arguments'  if @_ < 1;
    warn 'too many arguments' if @_ > 1;
    my ($nodes) = @_;

    unless ($config{'Quiet'}) {
        print 'updating';
        print ' (using '.$config{'SyncOID'}.')...';
        print (($config{'Verbose'}) ? "\n" : (' 'x$config{'DeviceOrder'}).'0');
    }

    my ($successful_update_count,$failed_update_count) = (0,0);
    foreach my $ip (keys %$nodes) {
        my $node = $nodes->{$ip};
        foreach my $serial (keys %{$node->{'devices'}}) {
            my $device = $node->{'devices'}{$serial};
            next unless $device->{'identified'}; # Only update identified devices.

            foreach my $ifName (keys %{$device->{'interfaces'}}) {
                my $interface = $device->{'interfaces'}{$ifName};
                next unless $interface->{'identified'}; # Only update identified interfaces.

                # Format the info to be pushed.
                my $update = '';
                my $empty = 1;
                foreach my $field (sort keys %{$interface->{'info'}}) {
                    $update .= "," unless $update eq '';
                    $update .= $field.':'.$interface->{'info'}{$field};
                    $empty = 0 if defined $interface->{'info'}{$field} and $interface->{'info'}{$field} =~ /[\S]+/;
                }
                $update = '' if $empty;

                my $note = interface_string ($interface).' ('.$interface->{'IID'}.')';
                my $error = App::Netsync::SNMP::set ($config{'SyncOID'},$interface->{'IID'},$update,$node->{'session'});
                unless ($error) { # Log a successful update.
                    $update =~ s/\n/,/g;
                    $update =~ s/\s+//g;
                    $update =~ s/:,/:(empty),/g;
                    note ($config{'UpdateLog'},$note.' '.$update);
                    ++$successful_update_count;

                    unless ($config{'Quiet'}) {
                        if ($config{'Verbose'}) {
                            interface_dump $interface;
                        }
                        else {
                            print  "\b"x$config{'DeviceOrder'};
                            printf ('%'.$config{'DeviceOrder'}.'d',$successful_update_count);
                        }
                    }
                }
                else { # Log a failed update.
                    note ($config{'UpdateLog'},$note.' error: '.$error);
                    ++$failed_update_count;

                    if ($config{'Verbose'}) {
                        say interface_string ($interface).' failed';
                        say ((' 'x$config{'Indent'}).$error);
                    }
                }
            }
        }
    }

    # Show the user how many nodes have been updated if necessary.
    unless ($config{'Quiet'}) {
        print $successful_update_count if $config{'Verbose'};
        print ' successful';
        print ' ('.$failed_update_count.' failed)' if $failed_update_count > 0;
        print "\n";
    }
}


=head1 AUTHOR

David Tucker, C<< <dmtucker at ucsc.edu> >>

=head1 BUGS

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

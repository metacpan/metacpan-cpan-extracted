package BigIP::GTM::ParseConfig;

# CURRENTLY UNDER DEVELOMENT BY WENWU YAN
#----------------------------------------------------------------------------
# The contents of this file are subject to the iControl Public License
# Version 4.5 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.f5.com/.
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is iControl Code and related documentation
# distributed by F5.
#
# The Initial Developer of the Original Code is F5 Networks,
# Inc. Seattle, WA, USA. Portions created by F5 are Copyright (C) 1996-2020 F5 Networks,
# Inc. All Rights Reserved.  iControl (TM) is a registered trademark of F5 Networks, Inc.
#
# Alternatively, the contents of this file may be used under the terms
# of the GNU General Public License (the "GPL"), in which case the
# provisions of GPL are applicable instead of those above.  If you wish
# to allow use of your version of this file only under the terms of the
# GPL and not to allow others to use your version of this file under the
# License, indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by the GPL.
# If you do not delete the provisions above, a recipient may use your
# version of this file under either the License or the GPL.
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Initialize the module
#----------------------------------------------------------------------------
our $VERSION = '0.83';
my $AUTOLOAD;

use 5.012;
use Carp;
use warnings;
use Data::Dumper;

# Initialize the module
sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->{'ConfigFile'} = shift;

    return $self;
}

#----------------------------------------------------------------------------
# Return a list of objects for ltm
#----------------------------------------------------------------------------
sub regions     { return shift->_objectlist('gtm region'); }
sub wideips     { return shift->_objectlist('gtm wideip'); }
sub pools       { return shift->_objectlist('gtm pool'); }
sub servers     { return shift->_objectlist('gtm server'); }
sub monitors    { return shift->_objectlist('gtm monitor'); }
sub partitions  { return shift->_objectlist('partition'); }
sub routes      { return shift->_objectlist('net route'); }
sub selfs       { return shift->_objectlist('net self'); }
sub vlans       { return shift->_objectlist('net vlan'); }
sub trunks      { return shift->_objectlist('net trunk'); }
sub interfaces  { return shift->_objectlist('net interface'); }
sub mgmt_routes { return shift->_objectlist('sys management-route'); }
sub users       { return shift->_objectlist('auth user'); }

#----------------------------------------------------------------------------
# Return a list of objects for net
#----------------------------------------------------------------------------
sub region     { return shift->_object( 'gtm region',           shift ); }
sub wideip     { return shift->_object( 'gtm wideip',           shift ); }
sub pool       { return shift->_object( 'gtm pool',             shift ); }
sub server     { return shift->_object( 'gtm server',           shift ); }
sub monitor    { return shift->_object( 'gtm monitor',          shift ); }
sub partition  { return shift->_object( 'partition',            shift ); }
sub self       { return shift->_object( 'net self',             shift ); }
sub route      { return shift->_object( 'net route',            shift ); }
sub vlan       { return shift->_object( 'net vlan',             shift ); }
sub trunk      { return shift->_object( 'net trunk',            shift ); }
sub interface  { return shift->_object( 'net interface',        shift ); }
sub mgmt_route { return shift->_object( 'sys management-route', shift ); }
sub snmp       { return shift->_object( 'sys',                  'snmp' ); }
sub sshd       { return shift->_object( 'sys',                  'sshd' ); }
sub ntp        { return shift->_object( 'sys',                  'ntp' ); }
sub syslog     { return shift->_object( 'sys',                  'syslog' ); }
sub user       { return shift->_object( 'auth user',            shift ); }

#----------------------------------------------------------------------------
# Return a list of objects for others
#----------------------------------------------------------------------------
sub funcs {
    my $self = shift;

    $self->{'Parsed'} ||= $self->_parse();

    return keys %{ $self->{'Parsed'} } || 0;
}

# Return a list of pool members
sub members {
    my $self = shift;
    my $pool = shift;

    my $members;
    $self->{'Parsed'} ||= $self->_parse();

    return 0 unless $self->{'Parsed'}->{'gtm pool'}->{$pool}->{'members'};

    if ( ref $self->{'Parsed'}->{'gtm pool'}->{$pool}->{'members'} eq 'HASH' )
    {
        return
            map {s/\:/\//r}
            (
            keys %{ $self->{'Parsed'}->{'gtm pool'}->{$pool}->{'members'} } );
    }
    else {
        return $self->{'Parsed'}->{'gtm pool'}->{$pool}->{'members'};
    }
}

#----------------------------------------------------------------------------
# Return a list of wideips_all
#----------------------------------------------------------------------------
sub wideips_all {
    my $self = shift;
    $self->{'Parsed'} ||= $self->_parse();

    return 0 unless $self->{'Parsed'}->{'gtm wideip'};

    # Loop for wideips()
    foreach ( $self->wideips() ) {
        my $ret = $self->wideip($_);
        my $pools = $ret->{pools};

        foreach my $pool ( keys %{$pools} ) {
            my $detail = $self->pool($pool);
            my $members = $detail->{members} if defined $detail->{members};
            $ret->{"detail"}{$pool}{"pool_detail"} = $detail;

            foreach my $serverAndVs ( keys %{$members} ) {
                my ( $server, $vs ) = split( /\:/, $serverAndVs );
                my $detail         = $self->server($server);
                my $virtual_server  = $detail->{"virtual-servers"}{$vs} if $detail;
                $ret->{"detail"}{$pool}{"server_detail"} ||= [];
                my $mem = $detail if $detail;
                $mem->{"server"} = $server;
                $mem->{"vs"} = $vs;
                push @{$ret->{"detail"}{$pool}{"server_detail"}}, $mem;

                my $monitor = $virtual_server->{"monitor"};
                if ( $monitor && $monitor =~ /http|tcp|udp|bigip|gateway_icmp/ ) {
                    next;
                }
                elsif ( $monitor && $monitor =~ /\S+/ ) {
                    my $mon_detail = $self->monitor($monitor);
                    $ret->{"detail"}{$pool}{"monitor_detail"} = $mon_detail if $mon_detail; 
                }                
            }
        }
    }

    return $self->{"Parsed"}{"gtm wideip"};
}

#----------------------------------------------------------------------------
# Return a list of wideip_detail
#----------------------------------------------------------------------------
sub wideip_detail {
    my $self   = shift;
    my $wideip = shift;

    $self->{'Parsed'} ||= $self->_parse();

    return 0 unless $self->{'Parsed'}->{'gtm wideip'};

    # Loop for wideips()
    my $ret = $self->wideip($wideip);
    my $pools = $ret->{pools};

    foreach my $pool ( keys %{$pools} ) {
        my $detail = $self->pool($pool);
        my $members = $detail->{members} if defined $detail->{members};
        $ret->{"detail"}{$pool}{"pool_detail"} = $detail;

        foreach my $serverAndVs ( keys %{$members} ) {
            my ( $server, $vs ) = split( /\:/, $serverAndVs );
            my $detail         = $self->server($server);
            my $virtual_server  = $detail->{"virtual-servers"}{$vs} if $detail;
            $ret->{"detail"}{$pool}{"server_detail"} ||= [];
            my $mem = $detail if $detail;
            $mem->{"server"} = $server;
            $mem->{"vs"} = $vs;
            push @{$ret->{"detail"}{$pool}{"server_detail"}}, $mem;

            my $monitor = $virtual_server->{"monitor"};
            if ( $monitor && $monitor =~ /http|tcp|udp|bigip|gateway_icmp/ ) {
                next;
            }
            elsif ( $monitor && $monitor =~ /\S+/ ) {
                my $mon_detail = $self->monitor($monitor);
                $ret->{"detail"}{$pool}{"monitor_detail"} = $mon_detail if $mon_detail; 
            }                
        }
    }

    return $self->{Parsed}{"gtm wideip"}{$wideip};
}

# Modify an object
sub modify {
    my $self = shift;

    my ($arg);
    %{$arg} = @_;

    return 0 unless $arg->{'type'} && $arg->{'key'};

    my $obj = $arg->{'type'};
    my $key = $arg->{'key'};
    delete $arg->{'type'};
    delete $arg->{'key'};

    $self->{'Parsed'} ||= $self->_parse();

    return 0 unless $self->{'Parsed'}->{$obj}->{$key};

    foreach my $attr ( keys %{$arg} ) {
        next unless $self->{'Parsed'}->{$obj}->{$key}->{$attr};
        $self->{'Modify'}->{$obj}->{$key}->{$attr} = $arg->{$attr};
    }

    return 1;
}

# Write out a new configuration file
sub write {
    my $self = shift;
    my $file = shift || $self->{'ConfigFile'};

    die "No changes found; no write necessary" unless $self->{'Modify'};

    foreach my $obj (
        qw( self partition route user monitor auth profile node pool rule virtual )
        )
    {
        foreach my $key ( sort keys %{ $self->{'Parsed'}->{$obj} } ) {
            if ( $self->{'Modify'}->{$obj}->{$key} ) {
                $self->{'Output'} .= "$obj $key {\n";
                foreach my $attr ( $self->_order($obj) ) {
                    next unless $self->{'Parsed'}->{$obj}->{$key}->{$attr};
                    $self->{'Modify'}->{$obj}->{$key}->{$attr}
                        ||= $self->{'Parsed'}->{$obj}->{$key}->{$attr};
                    if (ref $self->{'Modify'}->{$obj}->{$key}->{$attr} eq
                        'ARRAY' )
                    {
                        if ( @{ $self->{'Modify'}->{$obj}->{$key}->{$attr} }
                            > 1 )
                        {
                            $self->{'Output'} .= "   $attr\n";
                            foreach my $val (
                                @{  $self->{'Modify'}->{$obj}->{$key}->{$attr}
                                }
                                )
                            {
                                $self->{'Output'} .= "      $val\n";
                                if ( $self->{'Parsed'}->{$obj}->{$key}
                                    ->{'_xtra'}->{$val} )
                                {
                                    $self->{'Output'}
                                        .= '         '
                                        . $self->{'Parsed'}->{$obj}->{$key}
                                        ->{'_xtra'}->{$val} . "\n";
                                }
                            }
                        }
                        else {
                            $self->{'Output'}
                                .= "   $attr "
                                . $self->{'Modify'}->{$obj}->{$key}
                                ->{$attr}[0] . "\n";
                        }
                    }
                    else {
                        $self->{'Output'}
                            .= "   $attr "
                            . $self->{'Modify'}->{$obj}->{$key}->{$attr}
                            . "\n";
                    }
                }
                $self->{'Output'} .= "}\n";
            }
            else {
                $self->{'Output'} .= $self->{'Raw'}->{$obj}->{$key};
            }
        }
    }

    open FILE, ">$file" || return 0;
    print FILE $self->{'Output'};
    close FILE;

    return 1;
}

# Return an object hash
sub _object {
    my $self = shift;
    my $obj  = shift;
    my $var  = shift;

    $self->{'Parsed'} ||= $self->_parse();
    return undef unless defined $var;
    return $self->{'Parsed'}->{$obj}->{$var} || undef;
}

# Return a list of objects
sub _objectlist {
    my $self = shift;
    my $obj  = shift;

    $self->{'Parsed'} ||= $self->_parse();

    if ( $self->{'Parsed'}->{$obj} ) {
        return keys %{ $self->{'Parsed'}->{$obj} };
    }
    else {
        return 0;
    }
}

# Define object attribute ordering
sub _order {
    my $self = shift;

    for (shift) {
        /auth/ && return qw( bind login search servers service ssl user );
        /gtm monitor/
            && return
            qw( default base debug filter mandatoryattrs password security username interval timeout manual dest recv send );
        /gtm node/  && return qw( monitor screen );
        /gtm pool/  && return qw( lb nat monitor members );
        /partition/ && return qw( description );
        /net self/  && return qw( netmask unit floating vlan allow );
        /auth user/
            && return qw( password description id group home shell role );
        /gtm server/
            && return
            qw( translate snat pool destination ip rules profiles persist );

        return 0;
    }
}

# Parse the configuration file
sub _parse {
    my $self = shift;
    my $file = shift || $self->{'ConfigFile'};

    die "File not found: $self->{'ConfigFile'}\n"
        unless -e $self->{'ConfigFile'};

    open FILE, $file || return 0;
    my @file = <FILE>;
    close FILE;

    my ( $parsed, $obj, $key, $attr1, $attr2, $attr3 );

    until ( !$file[0] ) {
        my $ln = shift @file;

        #policy hit situation with gtm attribute
        if ( $ln =~ /^(auth user|patition|cli)\s(.*)\s\{(\s\})?$/ ) {
            next if $3;
            $obj = $1;
            $key = $2;
        }

        #gtm attribute
        elsif ( $ln
            =~ /^(gtm wideip|gtm pool|gtm server|gtm region)\s(.*)\s\{(\s\})?$/
            )
        {
            next if $3;
            $obj = $1;
            $key = $2;
        }

        #net attribute
        elsif ( $ln
            =~ /^(net self|net route|net interface|net vlan|net trunk)\s(.*)\s\{(\s\})?$/
            )
        {
            next if $3;
            $obj = $1;
            $key = $2;
        }

        #sys attribute
        elsif ( $ln =~ /^(sys management-route)\s(.*)\s\{(\s\})?$/ ) {
            next if $3;
            $obj = $1;
            $key = $2;
        }

        #gtm monitor attribute
        elsif ( $ln
            =~ /^((gtm monitor)\s(http|tcp|udp|bigip|gateway_icmp))\s(\S+)\s\{(\s\})?$/
            )
        {
            next if $5;
            $obj = $2;
            $key = $4;
            $parsed->{$obj}{$key}{"monitor_method"} = $3 if ( $obj && $key );
        }

        #sys management attribute
        elsif ( $ln
            =~ /^(sys)\s(snmp|sshd|ntp|syslog|state-mirroring)\s\{(\s\})?$/ )
        {
            next if $3;
            $obj = $1;
            $key = $2;
        }
        elsif ( $ln =~ /^\}$/ ) {
            $obj = undef;
            $key = undef;
        }

        # mungle data structure
        if ( $obj && $key ) {
            $self->{'Raw'}->{$obj}{$key} .= $ln;

            #Indent=4 { not empty }
            if ( $ln =~ /^\s{4}(\S+|\".*\")\s\{$/ ) {
                $attr1 = $1;
                next;
            }

            #$intdent=8 { not empty }
            if ( $ln =~ /^\s{8}(\S+|\".*\")\s\{$/ ) {
                $attr2 = $1;
                next;
            }

            #$intdent=12 { not empty }
            if ( $ln =~ /^\s{12}(\S+|\".*\")\s\{$/ ) {
                $attr3 = $1;
                next;
            }

            #Indent=4 with }$
            if ( $ln =~ /^\s{4}\}$/ ) {
                $attr1 = undef;
                next;
            }

            #Indent=8 with }$
            if ( $ln =~ /^\s{8}\}$/ ) {
                $attr2 = undef;
                next;
            }

            #Indent=12 with }$
            if ( $ln =~ /^\s{12}\}$/ ) {
                $attr3 = undef;
                next;
            }

            #Indent=4 {}
            if ( $ln =~ /^\s{4}(\S+)\s\{\s\}$/ ) {
                $parsed->{$obj}{$key}{$1} = undef;
                next;
            }

            #Indent=4 { scalar }
            if ( $ln =~ /^\s{4}(\S+)\s\{(.*)\}$/ ) {
                $parsed->{$obj}{$key}{$1} ||= [];
                push @{ $parsed->{$obj}{$key}{$1} },
                    grep { not /^\s*$/ } split( /\s+/, $2 );
                next;
            }

            if ( defined $attr1 && $attr1 ) {

                #Indent=8 {}
                if ( $ln =~ /^\s{8}(\S+)\s\{\s\}$/ ) {
                    $parsed->{$obj}{$key}{$attr1}{$1} = undef;
                    next;
                }

                #Indent=8 { scalar }
                if ( $ln =~ /^\s{8}(\S+)\s\{(.*)\}$/ ) {
                    $parsed->{$obj}{$key}{$attr1}{$1} ||= [];
                    push @{ $parsed->{$obj}{$key}{$attr1}{$1} },
                        grep { not /^\s*$/ } split( /\s+/, $2 );
                    next;
                }

                #Indent=8 match { key => value }
                if ( $ln =~ /^\s{8}(\S+)\s(.*)$/ ) {
                    $parsed->{$obj}{$key}{$attr1}{$1} = $2;
                    next;
                }

                #Indent=8 match scalar
                if ( $ln =~ /^\s{8}(\S+)$/ ) {
                    if ( ref( $parsed->{$obj}{$key}{$attr1} ) eq 'HASH' ) {
                        $parsed->{$obj}{$key}{$attr1}{$1} = undef;
                    }
                    else {
                        $parsed->{$obj}{$key}{$attr1} ||= [];
                        push @{ $parsed->{$obj}{$key}{$attr1} }, $1;
                    }
                    next;
                }
            }

            if ( defined $attr2 && ( $attr1 && $attr2 ) ) {

                #Indent=12 match { not empty }
                if ( $ln =~ /^\s{12}(\S+)\s\{\s\}$/ ) {
                    $parsed->{$obj}{$key}{$attr1}{$attr2}{$1} = undef;
                    next;
                }

                #Indent=12 { scalar }
                if ( $ln =~ /^\s{12}(\S+)\s\{(.*)\}$/ ) {
                    $parsed->{$obj}{$key}{$attr1} ||= [];
                    push @{ $parsed->{$obj}{$key}{$attr1}{$attr2}{$1} },
                        grep { not /^\s*$/ } split( /\s+/, $2 );
                    next;
                }

                #Indent=12 match { key => value }
                if ( $ln =~ /^\s{12}(\S+)\s(.*)\s?$/ ) {
                    $parsed->{$obj}->{$key}{$attr1}{$attr2}{$1} = $2;
                    next;
                }

                #Indent=12 match scalar
                if ( $ln =~ /^\s{12}(.*)\s?$/ ) {
                    if (ref( $parsed->{$obj}{$key}{$attr1}{$attr2} ) eq
                        'HASH' )
                    {
                        $parsed->{$obj}{$key}{$attr1}{$attr2}{$1} = undef;
                    }
                    else {
                        $parsed->{$obj}{$key}{$attr1}{$attr2} ||= [];
                        push @{ $parsed->{$obj}{$key}{$attr1}{$attr2} }, $1;
                    }
                    next;
                }
            }

            if ( defined $attr3 && ( $attr1 && $attr2 && $attr3 ) ) {

                #Indent=16 match { not empty }
                if ( $ln =~ /^\s{16}(\S+)\s\{\s\}$/ ) {
                    $parsed->{$obj}{$key}{$attr1}{$attr2}{$attr3}{$1} = undef;
                    next;
                }

                #Indent=16 { scalar }
                if ( $ln =~ /^\s{16}(\S+)\s\{(.*)\}$/ ) {
                    $parsed->{$obj}{$key}{$attr1} ||= [];
                    push @{ $parsed->{$obj}{$key}{$attr1}{$attr2}{$attr3}{$1}
                    }, grep { not /^\s*$/ } split( /\s+/, $2 );
                    next;
                }

                #Indent=16 match { key => value }
                if ( $ln =~ /^\s{16}(\S+)\s(.*)\s?$/ ) {
                    $parsed->{$obj}->{$key}{$attr1}{$attr2}{$attr3}{$1} = $2;
                    next;
                }

                #Indent=12 match scalar
                if ( $ln =~ /^\s{16}(.*)\s?$/ ) {
                    if (ref( $parsed->{$obj}{$key}{$attr1}{$attr2}{$attr3} )
                        eq 'HASH' )
                    {
                        $parsed->{$obj}{$key}{$attr1}{$attr2}{$attr3}{$1}
                            = undef;
                    }
                    else {
                        $parsed->{$obj}{$key}{$attr1}{$attr2}{$attr3} ||= [];
                        push @{ $parsed->{$obj}{$key}{$attr1}{$attr2}{$attr3}
                        }, $1;
                    }
                    next;
                }
            }

            #Indent=4 match { key => value }
            if ( $ln =~ /^\s{4}(\S+)\s(.*)$/ ) {
                $parsed->{$obj}{$key}{$1} = $2;
                next;
            }
        }
    }

    # Fill in ill-formatted objects
    foreach my $obj ( keys %{ $self->{'Raw'} } ) {
        foreach my $key ( keys %{ $self->{'Raw'}->{$obj} } ) {
            $parsed->{$obj}{$key} ||= $self->{'Raw'}->{$obj}{$key};
        }
    }

    return $parsed;
}

1;

__END__
 
Hide 9 lines of Pod
=head1 NAME
 
BigIP::LTM::ParseConfig - The great new BigIP::LTM::ParseConfig!
 
=head1 VERSION
 
Version 0.83
 
=cut
 
Hide 218 lines of Pod
=head1 SYNOPSIS
  use BigIP::LTM::ParseConfig;
     
  # Module initialization
  my $bip = new BigIP::LTM::ParseConfig( '/config/bigip.conf' );
     
  # Iterate over pools
  foreach my $pool ( $bip->pools() ) {
      # Iterate over pool members
      foreach my $member ( $bip->members( $pool ) ) {
          # Change port from 80 to 443
          if ( $member /^(\d+\.\d+\.\d+\.\d+):80/ ) {
              push @members, "$1:443";
              my $change = 1;
          }
      }
      # Commit the change above (80->443)
      if ( $change ) {
          $bip->modify(
              type => 'pool',
              key  => $pool,
              members => [ @members ]
          );
      }
  }
     
  # Write out a new config file
  $bip->write( '/config/bigip.conf.new' );
   
=head1 DESCRIPTION
   
BigIP::LTM::ParseConfig provides a Perl interface to reading, writing, and
manipulating configuration files used on F5 (BigIP) LTM network devices.
   
This module is currently a work-in-progress.  Please e-mail with problems,
bug fixes, comments and complaints.
   
=head1 CONSTRUCTOR
   
=over 4
   
=item new ( FILE )
   
Create a new B<BigIP::LTM::ParseConfig> object.
   
C<FILE> refers to the bigip.conf configuration file, usually found at
/config/bigip.conf.
   
B<Example>
   
  $bip = BigIP::LTM::ParseConfig->new( '/config/bigip.conf' );
   
=back
   
=head1 METHODS
   
=over 4
   
=item monitors
 @monitos = $bip->monitors;
=item nodes
 @nodes = $bip->nodes;
=item partitions
 @partions = $bip->partitions;
=item pools
 @pools = $bip->pools;
=item profiles
 @profiles = $bip->profiles;
=item routes
 @routes = $bip->routes;
=item rules
 @rules = $bip->rules;
=item users
 @users = $bip->uers;
=item virtuals
 @virtuals = $bip->virtuals;
 
List the names of all found objects of the referring method.
   
B<Examples>
   
  @pools = $bip->pools();
   
  @virtuals = $bip->virtuals();
   
=item monitor ( MONITOR )
   
=item node ( NODE )
   
=item partition ( PARTITION )
   
=item pool ( POOL )
   
=item profile ( PROFILE )
   
=item route ( ROUTE )
   
=item rule ( RULE )
   
=item user ( USER )
   
=item virtual ( VIRTUAL )
   
Return a hash of the object specified.
   
B<Examples>
   
  %sschneid = $bip->user( 'sschneid' );
   
  $monitor = $bip->pool( 'Production_LDAP_pool')->{'monitor'};
   
=item members ( POOL )
   
List the members of a specified pool.
   
B<Example>
   
  @members = $bip->members( 'Production_LDAP_pool' );
   
Note that this is identical to using the I<pool> method:
   
  @members = @{$bip->pool( 'Production_LDAP_pool' )->{'members'}};
   
=item modify ( OPTIONS )
   
Modify the attributes of a specified object.  The following options are B<required>:
   
=over 4
   
=item type
   
The type of object being modified.  Allowed types are: monitor, node, partition,
pool, profile, route, user, virtual.
   
=item key
   
The key (name) of the object being modified.
   
=back
   
Following B<type> and B<key> should be a string or a reference to an array of
strings.  See the example below for more details.
   
B<Examples>
   
  $bip->modify(
      type => 'virtual',
      key  => 'Production_LDAP_vip',
      persist => 'cookie'
  );
     
  $bip->modify(
      type => 'pool',
      key  => 'Production_LDAP_pool',
      members => [ '192.168.0.1:636', '192.168.0.2:636' ]
  );
   
=item write ( FILE )
   
Write out a new configuration file.  C<FILE> refers to the bigip.conf configuration
file, usually found at /config/bigip.conf.
   
B<Example>
   
  $bip->write( '/config/bigip.conf.new' );
   
=head1 AUTHOR
 
WENWU YAN, C<< <careline at 126.com> >>
 
=head1 BUGS
 
Please report any bugs or feature requests to C<bug-bigip-ltm-parseconfig at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=BigIP-LTM-ParseConfig>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
 
=head1 SUPPORT
 
You can find documentation for this module with the perldoc command.
 
    perldoc BigIP::LTM::ParseConfig
 
You can also look for information at:
 
=over 4
 
=item * RT: CPAN's request tracker (report bugs here)
 
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=BigIP-LTM-ParseConfig>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/BigIP-LTM-ParseConfig>
 
=item * CPAN Ratings
 
L<https://cpanratings.perl.org/d/BigIP-LTM-ParseConfig>
 
=item * Search CPAN
 
L<https://metacpan.org/release/BigIP-LTM-ParseConfig>
 
=back
 
 
=head1 ACKNOWLEDGEMENTS
 
 
=head1 LICENSE AND COPYRIGHT
 
This software is Copyright (c) 2019 by WENWU YAN.
 
This is free software, licensed under:
 
  The Artistic License 2.0 (GPL Compatible)
   
=cut


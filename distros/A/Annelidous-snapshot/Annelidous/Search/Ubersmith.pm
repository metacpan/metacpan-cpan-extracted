#!/usr/bin/perl
#
# Annelidous - the flexibile cloud management framework
# Copyright (C) 2009  Eric Windisch <eric@grokthis.net>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package Annelidous::Search::Ubersmith;

# Inheritance (shorthand for using @INC/require)
use base ("Annelidous::Search");

use Annelidous::Cluster::GrokThis;
use Data::Dumper;

sub new {
	my $class=shift;
	my $self={
	    -dbh=>undef,
	    @_
	};
	bless $self, $class;

	if (defined $self->{-dbh}) {
		$self->{dbh}=$self->{-dbh};
	}

	return $self;
}

#
# CPU lookup table.
# TODO: lookup_cpu is static, must be made dynamic...
#
sub lookup_cpu {
    my $self=shift;
    my $plan=shift;
    #$self->memhash{$plan};
    my $cpuhash={
        vi05=>1,
        vi06=>1,
        vi10=>1,
        vi11=>1,
        vi20=>1,
        vi40=>1,
        gvs=>2,
        gvm=>2,
        gvl=>2,
        gvx=>2
    };
    return $cpuhash->{$plan};
}


#
# Memory lookup table.
# TODO: lookup_mem is static, must be made dynamic...
#
sub lookup_mem {
    my $self=shift;
    my $plan=shift;
    #$self->memhash{$plan};
    my $memhash={
        vi05=>64,
        vi06=>64,
        vi10=>128,
        vi11=>128,
        vi20=>256,
        vi40=>512,
        gvs=>96,
        gvm=>128,
        gvl=>256,
        gvx=>512
    };
    return $memhash->{$plan};
}

#
# The base find method on which the others are built.
#
sub _find {
    my $self=shift;
    my $where=shift;
    my @args=@_;
    my @cl=$self->db_fetch("select distinct first as first_name,last as last_name,username,code as plan,email, desserv as description,PACKAGES.packid as id,PACKAGES.servername as host,CLIENT.clientid as client_id from PACKAGES join CLIENT on PACKAGES.clientid=CLIENT.clientid join plans on plans.plan_id=PACKAGES.plan_id ".$where, @args);

    # strcmp to detect an ipv4 address which is specified in ipv6 notation with "0000::" prefix
    my $sth=$self->{dbh}->prepare("select INET_NTOA(conv(addr,16,10)) as ip from ip_assignments where ip_assignments.service_id=? and strcmp('0000',substr(addr,1,4))=0");

    # IPv6 addresses
    # We have a simple, but long, conversion from an IPv6 address without separators, to one with separators.
    my $sth6=$self->{dbh}->prepare("select concat(substr(addr,1,4),':',substr(addr,5,4),':',substr(addr,9,4),':',substr(addr,13,4),':',substr(addr,17,4),':',substr(addr,21,4),':',substr(addr,25,4),':',substr(addr,29,4),substr(addr,33,4)) as ip6 from ip_assignments where ip_assignments.service_id=? and strcmp('0000',substr(addr,1,4))");

    foreach my $client (@cl) {
		$client->{'cpu_count'}=$self->lookup_cpu($client->{'plan'});
		$client->{'memory'}=$self->lookup_mem($client->{'plan'});
        
        $sth->execute($client->{'id'});
        my @ip4;
        while (my $addrinfo=$sth->fetchrow_hashref) {
            push @ip4, $addrinfo->{'ip'};
        }

        $sth6->execute($client->{'id'});
        my @ip6;
        while (my $addrinfo=$sth6->fetchrow_hashref) {
            push @ip6, $addrinfo->{'ip6'};
        }

        $client->{'ip6'}=join ' ', @ip6;
        $client->{'ip4'}=join ' ', @ip4;
        $client->{'ip'}=join ' ', ($client->{'ip4'}, $client->{'ip6'});

        my $ip6router;
        if ($client->{'ip6'}) {
			$client->{'ip6'} =~ /(.*).(\/\w+)/;
			$client->{'ip6router'}=$1."1".$2;

			my $ip6in4=$ip4[0];
			$ip6in4 =~ s/\./:/g;
			$client->{'ip6'} =~ /^(\w+:\w+:\w+:\w+:)/;
			$client->{'ip6in4'} = $1.$ip6in4;
		}

        # replace any C/v/Vs with c'
        $client->{username} =~ s/^(c|v)?/c/i;

		# TODO: FIXME: Bitness check from uber
		$client->{bitness} = 64;
		#$client->{bitness} = 32;
    }

    $sth->finish();
    $sth6->finish();
    return @cl;
}

#
# Fetches all clients
#
sub find {
    my $self=shift;
	my $where=shift;
	if (defined ($where)) {
		#print $where."\n";
		$where =~ s/^and//g;
		#print $where."\n";
		$where = "where category='vps' and ".$where;
	} else {
		$where = "where category='vps'";
	}
    return $self->_find($where,@_);
}

sub find_inactive {
	my $self=shift;
	my $where=shift;
	$where="PACKAGES.active!=1 ".$where;
	return $self->find($where,@_);
}
	
sub find_active {
	my $self=shift;
	my $where=shift;
	$where="PACKAGES.active=1 ".$where;
	return $self->find($where,@_);
}

#
# Fetches clients based on username
#
sub find_byusername {
    my $self=shift;
    my $username=shift;
    return $self->find("and username regexp ?", $username);
}
sub find_active_byusername {
    my $self=shift;
    my $username=shift;
    return $self->find_active("and username regexp ?", $username);
}

sub by_id {
    my $self=shift;
    my $id=shift;
	#print "Hunting for id: ";
	#print Dumper $id."\n";
	# Do not discriminate on active or not.
    return $self->find("and PACKAGES.packid=?", $id);
}

sub by_clientid {
    my $self=shift;
    my $id=shift;
	my $active=shift;
	my $where="and CLIENT.clientid=?";
	if ($active) {
		$where.=" and PACKAGES.active=1";
	}
	# Do not discriminate on active or not.
    return $self->find($where, $id);
}

#
# Fetches clients based on email address
#
sub find_bymail {
    my $self=shift;
    my $email=shift;
    return $self->find ("and email=?", $email);
}

#
# Fetches clients based on their host
#
sub find_byhost {
    my $self=shift;
    my $hostname=shift;
    return $self->find ("and servername=?", $hostname);
}

sub get_default_cluster {
	my $self=shift;
	return Annelidous::Cluster::GrokThis->new($self);
}

# Authentication per-service
# I.E. sub-accounts
sub auth_service {
    my $self=shift;
    my $username=shift;
    my $password=shift;
    my $c=$self->find("and username=? and password=?", $username,$password);

	# Return the single authorized package/service.
	return [$c->{id}];
}

# Authentication per-account
# I.E. master accounts
sub auth_account {
    my $self=shift;
    my $username=shift;
    my $password=shift;
    my @cl=$self->db_fetch("select clientid from CLIENT where clientid=? and password=? limit 1",$username,$password);
	if ($#cl > -1) {
		return $self->authorized_services($cl[0]->{clientid});
	}
	return 0;
}

sub authorized_services {
	my $self=shift;
	my $clientid=shift;
	my @services=();
    # Iterate over the options.
    foreach my $pack ($self->by_clientid($clientid)) {
        # Ignore broken guests
        next if ($pack->{username} =~ /^c?$/ || ! $pack->{ip});

        # Just get the first IP:
        @_=split (/ /, $pack->{ip});
        my $ip=$_[0];

        # Skip any entries that don't have IPs.
        next unless ($ip);
		push @services, $pack->{id};
	}
	# Authorized services by packid.
	return @services;
}


1;

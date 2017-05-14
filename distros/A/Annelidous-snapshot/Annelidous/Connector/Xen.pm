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

package Annelidous::Connector::Xen;
use base 'Annelidous::Connector';
use Data::Dumper;

#use Annelidous::Transport::SSH;

sub new {
	my $invocant = shift;
	my $class   = ref($invocant) || $invocant;
	my $self={
	    -transport=>'Annelidous::Transport::SSH',
	    -vm=>undef,
	    @_
	};
	bless $self, $class;

	if (defined($self->{-vm})) {
		$self->vm($self->{-vm});
	}

	$self->transport($self->{-transport},{-host=>$self->vm->get_host});
	return $self;
}

# Launch client guest OS into rescue mode
# takes a client_pool as argument 
sub rescue {
    my $self=shift;
    my $guest=$self->vm->data;

    #my @userinfo=getpwent($guest->{username});
    #my $homedir=$userinfo[7];
	my $hostname=$self->vm->get_host();
	my $guestVG="XenDomains";
	my $swapVG="XenDomains";
	if ($hostname =~ /(rorschach|fury)\.grokthis\.net/i) {
		$guestVG="SanXenDomains";
		$swapVG="XenSwap";
	}

    #print "Starting guest: ".$guest->{username}."\n";
    my @exec=("xm","create",
    "/dev/null",
    "name='".$guest->{username}."'",
    "kernel='/boot/xen/vmlinuz-".$guest->{bitness}."'",
    "memory=".$guest->{'memory'},
    "vif='vifname=".$guest->{username}.",ip=".$guest->{ip}."'",
    "disk='phy:mapper/".$guestVG."-".$guest->{username}.",sda1,w'",
    "disk='phy:mapper/".$swapVG."-".$guest->{username}."swap,sda2,w'",
    #"disk='phy:mapper/XenDomains-".$guest->{username}.",sda1,w'",
    #"disk='phy:mapper/XenDomains-".$guest->{username}."swap,sda2,w'",
    "root='/dev/sda1 ro'",
    "extra='init=/bin/sh console=xvc0'",
    "vcpus=".$guest->{cpu_count});
    #print join " ", @exec;
    $self->transport()->exec(@exec);

    # Configure IPv6 router IP for vif (no proxy arp here, we give a whole subnet)
    if ($guest->{'ip6router'}) {
        my @exec2=("ifconfig","inet6","add",$guest->{username},$guest->{ip6router});
        #print join " ", @exec2;
        $self->transport->exec(@exec2);
    }
}

# Launch client guest OS...
# takes a client_pool as argument 
sub boot {
    my $self=shift;
    my $guest=$self->vm->data;

    #my @userinfo=getpwent($guest->{username});
    #my $homedir=$userinfo[7];
	my $hostname=$self->vm->get_host();
	my $guestVG="XenDomains";
	my $swapVG="XenDomains";
	if ($hostname =~ /(rorschach|fury)\.grokthis\.net/i) {
		$guestVG="SanXenDomains";
		$swapVG="XenSwap";
	}

    #print "Starting guest: ".$guest->{username}."\n";
    my @exec=("xm","create",
    "/dev/null",
    "name='".$guest->{username}."'",
    "kernel='/boot/xen/vmlinuz-".$guest->{bitness}."'",
    "memory=".$guest->{'memory'},
    "vif='vifname=".$guest->{username}.",ip=".$guest->{ip4}."'",
    "disk='phy:mapper/".$guestVG."-".$guest->{username}.",sda1,w'",
    "disk='phy:mapper/".$swapVG."-".$guest->{username}."swap,sda2,w'",
    #"disk='phy:mapper/XenDomains-".$guest->{username}.",sda1,w'",
    #"disk='phy:mapper/XenDomains-".$guest->{username}."swap,sda2,w'",
    "root='/dev/sda1 ro'",
    "extra='3 console=xvc0'",
    "vcpus=1");
	#print "\n";
	#print join " ", @exec;
	#print "\n";
    $self->transport()->exec(@exec);

    # Configure IPv6 router IP for vif (no proxy arp here, we give a whole subnet)
    if ($guest->{'ip6router'}) {
        my @exec2=("ifconfig",$guest->{username},"inet6","add",$guest->{ip6router});
        $self->transport->exec(@exec2);
    }
}

sub destroy {
    my $self=shift;
    return $self->transport->exec("xm","destroy",$self->vm->data->{username});
}

sub shutdown {
    my $self=shift;
    return $self->transport->exec("xm","shutdown",$self->vm->data->{username});
}

sub status {
    my $self=shift;
    my $ret=${$self->transport->exec("xm","list",$self->vm->data->{username})}[0];
	return ($ret)?0:1;
}

sub uptime {
    my $self=shift;
    return ${$self->transport->exec("xm","uptime",$self->vm->data->{username})}[1];
}

sub console {
    my $self=shift;
    return $self->transport->tty("xm","console",$self->vm->data->{username});
}

sub reimage {
    my $self=shift;
	my @ip4=split (/ /, $self->vm->data->{ip4});
	my $ip=$ip4[0];
    return $self->transport->tty("/usr/bin/gt-xm-reimage",$self->vm->data->{username},$self->vm->data->{username},$self->vm->data->{memory},$ip);
}

#sub console {
#    my $self=shift;
#    # TODO: IMPLEMENT Xen Console
#    # provided is a suggested layout for this method...
#    #my $cap=new Annelidous::Capabilities;
#    #$cap->add("serial");
#    # Get the console here.
#    #$self->transport->exec("xm");
#    #if () {
#    #    $cap->add("tty");
#    #} else {
#    #    $cap->add("vnc");
#    #}
#}

1;

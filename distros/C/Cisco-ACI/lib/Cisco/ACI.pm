package Cisco::ACI;

use strict;
use warnings;

use Carp;
use JSON;
use HTTP::Request;
use LWP;
use XML::Simple;
use Cisco::ACI::Rule;
use Cisco::ACI::FvcapRule;
use Cisco::ACI::FvAEPg;
use Cisco::ACI::FvBD;
use Cisco::ACI::FvCEp;
use Cisco::ACI::FvRsBd;
use Cisco::ACI::Leaf;
use Cisco::ACI::Spine;
use Cisco::ACI::Tenant;
use Cisco::ACI::FaultCounts;
use Cisco::ACI::Eqpt::ExtCh;
use Cisco::ACI::Fault::Inst;
use Cisco::ACI::Fabric::Link;
use Cisco::ACI::Fabric::Pod;
use Cisco::ACI::Health::Inst;
use Cisco::ACI::Infra::WiNode;
use Cisco::ACI::Stats::Curr::OverallHealth;

our $VERSION = '0.151';

our @LOGIN_ATTR = qw(
buildTime
creationTime
firstLoginTime
firstName
guiIdleTimeoutSeconds
lastName
maximumLifetimeSeconds
node
refreshTimeoutSeconds
remoteUser
restTimeoutSeconds
sessionId
siteFingerprint
token
unixUserId
userName
version
);

our %OBJ_MAPPING = (
	tenant		=> 'fvTenant',
	contract	=> 'vzBrCP',
	service_graph	=> 'vnsGraphInst',
	concrete_devices=> 'vnsCDev',
	bd		=> 'fvBD',
	epg		=> 'fvAEPg',
	vrf		=> 'fvCtx',
	ep		=> 'fvCEp'
);

{
	for my $obj ( keys %OBJ_MAPPING ) {
		no strict 'refs';

		*{ __PACKAGE__ . "::$obj\_constraint" } = sub {
			my $self = shift;
			return $self->__get_constraint( $OBJ_MAPPING{ $obj } )
		};

		*{ __PACKAGE__ . "::$obj\_count" } = sub {
			my $self = shift;

			return $self->__get_count( $OBJ_MAPPING{ $obj } )
		}
	}
}

sub new {
	my ( $class, %args ) = @_;

	my $self = bless {}, $class;

	$self->__init( %args );

	return $self
}

sub error {
	my $self = shift;

	return $self->{ error }
}

sub login {
	my $self = shift;

	my $json = { aaaUser => { attributes => { name => $self->{ username }, pwd => $self->{ password } } } };

	my $r = $self->__request( $self->__get_login_uri, to_json( $json ) );

	return if $self->{ error };

	$r = from_json( $r->content );

	if ( defined $r->{ imdata } ) {
		for my $a ( @LOGIN_ATTR ) {
			$self->{ $a } = $r->{ imdata }->[0]->{ aaaLogin }->{ attributes }->{ $a }
		}
	}

	return $self
}

sub __jp {
	my $self = shift;

	return $self->{ __jp }
}

sub __init {
	my ( $self, %args ) = @_;

	defined $args{ username }
		? $self->{ username } = $args{ username }
		: die 'No username parameter provided to constructor.' ;

	defined $args{ password } 
		? $self->{ password } = $args{ password }
		: die 'No password parameter provided to constructor.' ;

	defined $args{ server }
		? $self->{ server } = $args{ server }
		: die 'No server parameter provided to constructor.' ;

	$self->{ port } = defined $args{ port }
		? $args{ port } 
		: 443;

	$self->{ proto }= defined $args{ port }
		? $args{ port }
		: 'https';

	$self->{ __ua } = LWP::UserAgent->new;
	$self->{ __ua }->ssl_opts( verify_hostname => 0 );
	$self->{ __ua }->ssl_opts( SSL_verify_mode => 0 );
	$self->{ __ua }->cookie_jar( {} );

	$self->{ __xp } = XML::Simple->new;

	$self->{ __jp } = JSON->new;
}

sub __get_constraint {
	my ( $self, $class ) = @_;

	return $self->{ __jp }->decode(
		$self->__request(
			$self->__get_uri( "/api/mo/uni/fabric/compcat-default/fvsw-default/capabilities/fvcaprule-$class-scope-policy-domain-type-limit.json" )
		)->content
	)->{ imdata }->[0]->{ fvcapRule }->{ attributes }->{ constraint }
}

sub __get_count {
	my ( $self, $class ) = @_;

	return $self->{ __jp }->decode(
		$self->__request(
			$self->__get_uri( "/api/class/$class.json?rsp-subtree-include=count" )
		)->content
	)->{ imdata }->[0]->{ moCount }->{ attributes }->{ count }
}

sub get_capability_rules {
	my $self = shift;

	return map { Cisco::ACI::FvcapRule->new( $_->{ fvcapRule }->{ attributes } ) } 
	@{ $self->{ __jp }->decode(
		$self->__request(
			$self->__get_uri( '/api/mo/uni/fabric/compcat-default/fvsw-default/capabilities.json?query-target=children&target-subtree-class=fvcapRule' )
		)->content
	)->{ imdata } }
}

sub tenant {
	my ( $self, $tenant ) = @_;

	confess 'Tenant identifier not provided' unless $tenant;

	my $args = $self->__jp->decode(
			$self->__request( 
				$self->__get_uri( '/api/mo/uni/tn-'. $tenant .'.json'
				)
			)->content
		)->{ imdata }->[0]->{ fvTenant }->{ attributes };

	confess "Tenant $tenant not defined." unless defined $args->{ dn };
	$args->{ __aci } = $self;

	return Cisco::ACI::Tenant->new( $args );
}

sub bds {
	my $self = shift;

	return map {
		Cisco::ACI::FvBD->new( $_->{ fvBD }->{ attributes } )
	}
	map {
		$_->{ fvBD }->{ attributes }->{ __aci } = $self; $_;
	}
	@{ $self->{ __jp }->decode(
		$self->__request(
			$self->__get_uri( '/api/class/fvBD.json' )
		)->content
	)->{ imdata } }
}

sub aepgs {
	my $self = shift;

	return map {
		Cisco::ACI::FvAEPg->new( $_->{ fvAEPg }->{ attributes } )
	}
	map {
		$_->{ fvAEPg }->{ attributes }->{ __aci } = $self; $_;
	}
	@{ $self->{ __jp }->decode(
		$self->__request(
			$self->__get_uri( '/api/class/fvAEPg.json' )
		)->content
	)->{ imdata } }
}

sub pod {
	my ( $self, $pod ) = @_;

	confess 'Pod identifier not provided' unless $pod;

	my $args = $self->__jp->decode(
			$self->__request( 
				$self->__get_uri( '/api/mo/topology/pod-'. $pod .'.json'
				)
			)->content
		)->{ imdata }->[0]->{ fabricPod }->{ attributes };

	confess "Pod $pod not defined." unless defined $args->{ dn };
	$args->{ __aci } = $self;

	return Cisco::ACI::Fabric::Pod->new( $args )
}
	
sub pods {
	my $self = shift;

	return map {
		Cisco::ACI::Fabric::Pod->new( $_->{ fabricPod }->{ attributes } )
	}
	map {
		$_->{ fabricPod }->{ attributes }->{ __aci } = $self; $_;
	}
	@{ $self->{ __jp }->decode(
		$self->__request(
			$self->__get_uri( '/api/class/fabricPod.json' )
		)->content
	)->{ imdata } }
}

sub fabric_links {
	my $self = shift;

	return map {
		Cisco::ACI::Fabric::Link->new( $_->{ fabricLink }->{ attributes } )
	}
	map {
		$_->{ fabricLink }->{ attributes }->{ __aci } = $self; $_;
	} 
	@{ $self->{ __jp }->decode( 
		$self->__request( 
			$self->__get_uri( '/api/class/fabricLink.json' ) 
		)->content
	)->{ imdata } }
}

sub cluster_appliances {
	my $self = shift;

	return map {
		Cisco::ACI::Infra::WiNode->new( $_->{ infraWiNode }->{ attributes } )
	}
	map {
		$_->{ infraWiNode }->{ attributes }->{ __aci } = $self; $_;
	} 
	@{ $self->{ __jp }->decode( 
		$self->__request( 
			$self->__get_uri( '/api/class/infraWiNode.json' ) 
		)->content
	)->{ imdata } }
}

sub cluster_standby_appliances {
	my $self = shift;

	return map {
		Cisco::ACI::Infra::SnNode->new( $_->{ infraSnNode }->{ attributes } )
	}
	map {
		$_->{ infraSnNode }->{ attributes }->{ __aci } = $self; $_;
	} 
	@{ $self->{ __jp }->decode( 
		$self->__request( 
			$self->__get_uri( '/api/class/infraSnNode.json' ) 
		)->content
	)->{ imdata } }
}

sub controllers {
	my $self = shift;

	return $self->__get_fabricnodes( 'controller' )
}

sub controller {
	my ( $self, $id ) = @_;

	$self->__get_fabricnodes( 'controller', $id )
}

sub spines {
	my $self = shift;

	$self->__get_fabricnodes( 'spine' )
}

sub spine {
	my ( $self, $id ) = @_;

	return $self->__get_fabricnode( 'spine', $id )
}

sub leafs {
	my $self = shift;

	return $self->__get_fabricnodes( 'leaf' )
}

sub leaf {
	my ( $self, $id ) = @_;

	return $self->__get_fabricnode( 'leaf', $id )
}

sub fexs {
	my $self = shift;

	return map {
		Cisco::ACI::Eqpt::ExtCh->new( $_->{ eqptExtCh }->{ attributes } )
	}
	map {
		$_->{ eqptExtCh }->{ attributes }->{ __aci } = $self; $_;
	} 
	@{ $self->{ __jp }->decode( 
		$self->__request( 
			$self->__get_uri( '/api/class/eqptExtCh.json' ) 
		)->content
	)->{ imdata } }
}

sub __get_fabricnode {
	my ( $self, $role, $id ) = @_;

	confess ucfirst( $role ) ." identifier not provided" unless $id;

	my $args = $self->{ __jp }->decode(
			$self->__request( 
				$self->__get_uri( "/api/class/fabricNode.json?query-target-filter=and(eq(fabricNode.role,\"$role\"),eq(fabricNode.id,\"$id\"))"
				)
			)->content
		)->{ imdata }->[0]->{ fabricNode }->{ attributes };
	$args->{ __aci } = $self;

	return Cisco::ACI::FabricNode->new( $args );
}

sub __get_fabricnodes {
	my ( $self, $role ) = @_;

	return map {
		Cisco::ACI::FabricNode->new( $_->{ fabricNode }->{ attributes } )
	}
	# We need to pass our $self (the Cisco::ACI object) as the __aci attribute
	# to our Leaf objects so that they can execute methods on "themselves"
	# using the connection, parser, and methods of the Cisco::ACI instance.
	# Hence the ugly line below.
	map {
		$_->{ fabricNode }->{ attributes }->{ __aci } = $self; $_;
	} 
	@{ $self->{ __jp }->decode( 
		$self->__request( 
			$self->__get_uri( "/api/class/fabricNode.json?query-target-filter=eq(fabricNode.role,\"$role\")" ) 
		)->content
	)->{ imdata } }
}

# While the controllers() method retrieves the APIC controllers as Cisco::ACI::FabricNode objects,
# this method retrieves 
sub __apic_appliances {

}

sub health {
	my $self = shift;

	return Cisco::ACI::Health::Inst->new( 
		$self->{ __jp }->decode( 
			$self->__request( 
				$self->__get_uri( '/api/node/mo/topology/health.json' ) 
			)->content
		)->{ imdata }->[0]->{ fabricHealthTotal }->{ attributes }
	)
}

sub overallHealth5min {
	my $self = shift;

	my $r = $self->{ __jp }->decode( 
		$self->__request( 
			$self->__get_uri( '/api/node/mo/topology/HDfabricOverallHealth5min-0.json' ) 
		)->content
	)->{ imdata }->[0];

	#print "r = $r->{ fabricOverallHealthHist5min }->{ attributes }->{ healthAvg }\n";

	my $h = Cisco::ACI::Stats::Curr::OverallHealth->new(
			healthAvg => $r->{ fabricOverallHealthHist5min }->{ attributes }->{ healthAvg }
	);	

	return $h
}

sub faults {
	my $self = shift;

	return map {
		Cisco::ACI::Fault::Inst->new( $_->{ faultInst }->{ attributes } )
	} @{ $self->{ __jp }->decode( 
		$self->__request( 
			$self->__get_uri( '/api/class/faultInst.json' )
		)->content
	)->{ imdata } }

}

sub __request {
	my ( $self, $uri, $data ) = @_;
	my $r;

	if ( $data ) {
		$r = HTTP::Request->new( POST => $uri );
		$r->content( $data );
	}
	else {
		$r = HTTP::Request->new( GET => $uri );
	}

	my $s = $self->{ __ua }->request( $r );
	$self->{ error } = "Login failure: $!" unless $s->is_success;

	return $s
}

sub __get_uri {
	my ( $self, $uri ) = @_;

	return ( $self->{ proto }
		. '://'
		. $self->{ server }
		. ':'
		. $self->{ port }
		. $uri
		)
}

sub __get_login_uri {
	my $self = shift;

	return $self->__get_uri( '/api/mo/aaaLogin.json' )
}

sub __get_fltCnts_uri {
	my $self = shift;

	return $self->__get_uri( '/api/node/mo/fltCnts.json' )
}

1;

__END__
=head2 NAME
Cisco::ACI - Perl interface to the Cisco APIC API.
=head2 SYNOPSIS
This module provides a Perl interface to Cisco APIC API.
    use Cisco::ACI;
    my $aci = Cisco::ACI->new(
			username=> $username,
			password=> $password,
			server	=> $server
    );
    # Required!
    $aci->login;
    # Get the leaf nodes of the pod as an array of
    # Cisco::ACI::FabricNode objects.
    my @leafs = $aci->get_leafs;
    # Same but for spines (both leaf and spine nodes
    # are Cisco::ACI::FabricNode objects).
    my @spines = $aci->get_spines;
    # Or, get a leaf by ID - still returns a 
    # Cisco::ACI::FabricNode object.
    my $leaf = $aci->(101);
    # Do some interesting stuff with it.
    # Like, get the 5min measurements of policy CAM (TCAM) usage
    # as a Cisco::ACI::Eqptcapacity::PolUsage object.
    my $pol_usage = $leaf->PolUsage( '5min' );
    # So now we can calculate the policy CAM utilisation
    my $pol_utilisation = ( $pol_usage->polUsageCum 
				/ $pol_usage->polUsageCapCum ) * 100;
    # Or get the number of faults present
    my $faults = $leaf->fault_counts;
    printf( 'Node %s has %d Minor, %d Major, %d Warning, and %d Critical faults\n',
		$leaf->name,
		$faults->minor,
		$faults->maj,
		$faults->warn,
		$faults->crit );
   
    # And much more... 
=head2 METHODS
=head3 new ( %ARGS )
Constructor.  Creates a new Cisco::ACI object.  This method accepts three mandatory
and two optional named parameters:
=over 4
=item B<username>
The username with which to connect to the Cisco APIC API.
=item B<password>
The password with which to connect to the Cisco APIC API.
=item B<server>
The resolvable hostname of the Cisco ACI APIC to connect to.
=item B<port>
The TCP port on which to connect to the Cisco ACI APIC, if not specified
this parameter will default to a value of 443, which is probably what you want.
=item B<proto>
The protocol to use when connecting to the Cisco ACI APIC, if not specified
this parameter will default to a value of 'https', which is probably what you want.
=back
=head3 bd_constraint ()
Returns the maximum configurable number Bridge Domains (fvBD) in the fabric.
=head3 bd_count ()
Returns the number of configured Bridge Domains (fvBD) in the fabric.
=head3 cluster_appliances ()
Returns all APICs in the cluster as an array of L<Cisco::ACI::Infra::WiNode>
objects.  Note that APICs are also separately represented as devices of type 
L<Cisco::ACI::FabricNode> within the Cisco APIC MO (see method B<controllers()>).
=head3 cluster_standby_appliances ()
Returns all standby APICs in the cluster as an array of L<Cisco::ACI::Infra::SnNode>
objects.
=head3 concrete_devices_constraint ()
Returns the maximum configurable number concrete devices (vnsCDev) in the fabric.
=head3 concrete_devices_count ()
Returns the number of configured concrete devices (vnsCDev) in the fabric.
=head3 contract_constraint ()
Returns the maximum configurable number contracts (vzBrCP) in the fabric.
=head3 contract_count ()
Returns the number of configured contracts (vzBrCP) in the fabric.
=head3 controllers ()
Returns all APICs in the cluster as an array of L<Cisco::ACI::FabricNode> objects.
Note that APICs are also separately represented as devices of type L<Cisco::ACI::Infra::WiNode> 
within the Cisco APIC MO (see method B<cluster_appliances()>).
=head3 controller ( $ID )
Returns the APIC identified by the $ID parameter as a L<Cisco::ACI::FabricNode>
object.  Note that APICs are numbered sequentially starting from 1.
=head3 ep_constraint ()
Returns the maximum configurable number end points (fvCEp) in the fabric.
=head3 ep_count ()
Returns the number of configured end points (fvCEp) in the fabric.
=head3 epg_constraint ()
Returns the maximum configurable number end point groups (fvAEPg) in the fabric.
=head3 epg_count ()
Returns the number of configured end point groups (fvAEPg) in the fabric.
=head3 fabric_links ()
Returns all fabric links as an array of L<Cisco::ACI::Fabric::Link> objects.
=head3 faults ()
Returns all fabric faults as an array of L<Cisco::ACI::Fault::Inst> objects.
=head3 fexs ()
Returns all fabric extendeds (fexs) as an array of L<Cisco::ACI::Eqpt::ExtCh> 
objects.
=head3 get_capability_rules ()
Returns all capacity rules as an array of L<Cisco::ACI::FvcapRule> objects.
=head3 health ()
Returns the fabric health as an array of L<Cisco::ACI::Health::Inst> objects.
=head3 leaf ( $ID )
Returns the leaf node identified the the B<$ID> parameter as a
L<Cisco::ACI::FabricNode> object.
=head3 leafs ()
Returns all leaf nodes as an array of L<Cisco::ACI::FabricNode> objects.
=head3 login ()
Perfoms a login to the ACI APIC API - note that merely calling the constructor
does not automatically log you into the fabric.  Rather you are required to invoke
this method to do so.
=head3 overallHealth5min ()
Returns the overall health of the fabric for the previous fivce minute interval as
an L<Cisco::ACI::Stats::Curr::OverallHealth> object.
=head3 service_graph_constraint ()
Returns the maximum configurable number of service graphs (vnsGraphInst) in the fabric.
=head3 service_graph_count ()
Returns the number of configured service graphs (vnsGraphInst) in the fabric.
=head3 spine ( $ID )
Returns the spine node identified the the B<$ID> parameter as a
L<Cisco::ACI::FabricNode> object.
=head3 spines ()
Returns all spine nodes as an array of L<Cisco::ACI::FabricNode> objects.
=head3 tenant ( $TENANT )
Returns the tenant identified by the $TENANT parameter as a L<Cisco::ACI:Tenant>
object.
=head3 tenant_constraint ()
Returns the maximum configurable number of tenant (fvTenant) in the fabric.
=head3 tenant_count ()
Returns the number of configured tenants (fvTenant) in the fabric.
=head3 vrf_constraint ()
Returns the maximum configurable number of VRFs (fvCtx) in the fabric.
=head3 vrf_count ()
Returns the number of configured VRFs (fvCtx) in the fabric.
=head2 AUTHOR
Luke Poskitt, C<< <ltp at cpan.org> >>
=head2 BUGS
Please report any bugs or feature requests to C<bug-cisco-aci at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-ACI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
=head2 SUPPORT
You can find documentation for this module with the perldoc command.
    perldoc Cisco::ACI
You can also look for information at:
=over 4
=item * RT: CPAN's request tracker (report bugs here)
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-ACI>
=item * AnnoCPAN: Annotated CPAN documentation
L<http://annocpan.org/dist/Cisco-ACI>
=item * CPAN Ratings
L<http://cpanratings.perl.org/d/Cisco-ACI>
=item * Search CPAN
L<http://search.cpan.org/dist/Cisco-ACI/>
=back
=head2 LICENSE AND COPYRIGHT
This software is Copyright (c) 2019 by WENWU YAN.

This is free software, licensed under:

  The (two-clause) FreeBSD License

The FreeBSD License

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the
     distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut

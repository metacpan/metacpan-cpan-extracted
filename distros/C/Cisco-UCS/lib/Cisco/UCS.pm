package Cisco::UCS;

use warnings;
use strict;

use Cisco::UCS::Chassis;
use Cisco::UCS::Interconnect;
use Cisco::UCS::FEX;
use Cisco::UCS::Blade;
use Cisco::UCS::Fault;
use Cisco::UCS::MgmtEntity;
use Cisco::UCS::ServiceProfile;
use LWP;
use XML::Simple;
use Carp qw(croak carp cluck);

use vars qw($VERSION);

our $VERSION		= '0.51';

our @ATTRIBUTES		= qw(dn cluster cookie);

our %ATTRIBUTES		= ();

sub new {
        my ( $class, %args ) = @_;

	my $self = {};
        bless $self, $class;

        defined $args{cluster}
		? $self->{cluster} = $args{cluster}
		: croak 'cluster not defined';

        defined $args{username}
		? $self->{username} = $args{username}
		: croak 'username not defined';

        defined $args{passwd}
		? $self->{passwd} = $args{passwd}
		: croak 'passwd not defined';

        defined $args{verify_hostname}
		? $self->{verify_hostname} = $args{verify_hostname}
		: 0;

	$self->{port}	= ( $args{port}	or 443      );
	$self->{proto}	= ( $args{proto} or 'https' );
	$self->{dn}	= ( $args{dn} or 'sys'      );

        return $self;
}

{
        no strict 'refs';

        while ( my ($pseudo, $attribute) = each %ATTRIBUTES ) { 
                *{ __PACKAGE__ . '::' . $pseudo } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }   

        foreach my $attribute (@ATTRIBUTES) {
                *{ __PACKAGE__ . '::' . $attribute } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }
}

sub login {
	my $self = shift;

	undef $self->{error};

	$self->{ua} = LWP::UserAgent->new( 
				ssl_opts => { 
					verify_hostname => $self->{verify_hostname}
				} 
			);

	$self->{uri} = $self->{proto}. '://' .$self->{cluster}
				. ':' .$self->{port}. '/nuova';

	$self->{req} = HTTP::Request->new(
					POST => $self->{uri}
			);

	$self->{req}->content_type( 'application/x-www-form-urlencoded' );

	$self->{req}->content( '<aaaLogin inName="'. $self->{username} 
				.'" inPassword="'. $self->{passwd} .'"/>' );

	my $res	= $self->{ua}->request( $self->{req} );

	unless ( $res->is_success ) {
		$self->{error} = 'Login failure: '.$res->status_line;
		return 0
	}

	$self->{parser}	= XML::Simple->new;
	my $xml         = $self->{parser}->XMLin( $res->content );

	if ( defined $xml->{'errorCode'} ) {
		$self->{error}	= 'Login failure: '
				. ( defined $xml->{'errorDescr'} 
					? $xml->{'errorDescr'}
					: 'Unspecified error'
				);
		return 0
	}

	$self->{cookie}	= $xml->{'outCookie'};

	return 1
}

sub refresh {
	my $self = shift;

	undef $self->{error};
	$self->{req}->content( '<aaaRefresh inName="'. $self->{username} 
				.'" inPassword="'. $self->{passwd} 
				.'" inCookie="' . $self->{cookie} . '"/>'
	);

	my $res	= $self->{ua}->request( $self->{req} );

	unless ( $res->is_success ) {
		$self->{error}	= 'Refresh failed: '. $res->status_line;
		return 0
	}

	my $xml	= $self->{parser}->XMLin( $res->content() );

	if ( defined $xml->{'errorCode'} ) {
		$self->{error}	= 'Refresh failure: '
				. ( defined $xml->{'errorDescr'} 
					? $xml->{'errorDescr'} 
					: 'Unspecified error'
				);
		return 0
	}

        $self->{cookie}	= $xml->{'outCookie'};

	return 1
}

sub logout {
	my $self = shift;

	return unless $self->{cookie};

	undef $self->{error};

	return ( $self->_ucsm_request( '<aaaLogout inCookie="'
				. $self->{cookie} .'" />' ) ? 1 : 0 
	)
}

sub _ucsm_request {
	my ( $self, $content, $class_id ) = @_;

	undef $self->{error};
	$self->{req}->content( $content );
	my $res	= $self->{ua}->request( $self->{req} );

	$self->error( $res->status_line ) unless $res->is_success;

	my $xml = ( $class_id 
			? $self->{parser}->XMLin( 
						$res->content, 
						KeyAttr => $class_id 
						)
			: $self->{parser}->XMLin( 
						$res->content, 
						KeyAttr => [ 'name', 'key', 'id', 'intId' ] 
						)
		);

	return ( $xml->{errorCode}
			? do {
				$self->{error} = ( $xml->{'errorDescr'} 
							? $xml->{'errorDescr'}
							: 'Unspecified error' 
						);
				undef
			  }
			: $xml
		);
}

# This private method provides an abstract factory-type constructor for resolved child
# objects of the specified dn.  To maintain compatibility with existing methods and to
# provide a single method for all child objects, there are a few important design
# considerations that have been made.
# 
# Importantly we check for a 'class_filter' argument to the method which if present is
# used to call the 'resolve_class_filter' method rather than the 'resolve_children' method.
# This is necessary due to limitations and difficulties present in resolving child objects
# for some objects can lead to incorrect results.  For example, resolving the child objects
# for a chassis to retrieve the blades in the chassis is difficult, instead we can use a much
# more efficient and simpler method of retrieving the blades in a specified chassis by
# resolving all objects in the specified class (i.e. computeBlade) and restricting the
# results returned using a filter method.
#
# The implication of doing this is that the call to 'resolve_class_filter' returns an array
# which cannot be processed using the same logic as for a hash returned by the 'resolve_children'
# method.  Therefore we perform extra processing to convert the returned array results to a 
# hash using a nominated attribute in the object as the hash index for the objects.
#
# SYNOPSIS
#	get_child_object ( %ARGS )
#
# PARAMETERS
#	id	The optional identifier of a specific child object.  This identifier is context
#		dependent and may be either numerical (as in the case of a chassis) or alphanumeric
#		(as is the case with a fabric interconnect - A or B).
#
#	type	The desired child object type to be resolved as according to the UCSM information 
#		management hierarchy name. e.g. etherPIo is the ethernet port child object type for line cards.
#
#	class	The class into which the child object will be blessed.
#
#	attr	The pseudo-namespace in the Cisco::UCS object in which the retrieved child onjects will be cached.
#		For example; attr => 'interconnect' will mean that Cisco::UCS::Interconnect objects retrieved in
#		a $ucs->get_interconnects method call will be stored in $ucs->{interconnects}->{$OBJ}.
#	
#	self	A reference to a Cisco::UCS object.  If not present $self is assumed to be a Cisco::UCS object.
#
#	uid	Where results are returned and parsed into an array and the array index is not aligned to an identifying 
#		attribute of the object (i.e. the array index has no relation to a unique identifier for the object) then
#		the uid may be used to refer to a unique identifying attribute of the object that should be used.
#		For example, in resolving all blades for a Cisco::UCS object, the uid value of bladeId is used to uniquely
#		identify all Cisco::UCS::Blade objects as the array index has no relation to a uniquely identifying feature
#		of the blade and is not guaranteed to be consistent.
#
#	class_filter (%ARGS)
#			A class filter may be specified to filter the results to a particular subset.  This is useful for
#			operations like retrieving all blades in a particular chassis rather than retrieving all blades and
#			manually filtering the results.
#
#	Where %ARGS:
#
#	classId	The UCSM class which should be used for the UCSM query.  For example: classId => etherPio.
#
#	filter	Where filter is composed of any number of valid attribute/value pairs.  For example: slotId => 1, switchId => $self->{id}.
#
#	eattrs	A hash containing key/value pairs that should be added to the retrieved child objects as additional
#		attributes.  This can be useful where child objects need to "know" some infomration about their
#		parent object.  e.g. an interconnect switchcard needs to know which interconnect it is located in (A or B)
#		as this information is not exposed as an attribute of the switchcard.  
#

sub _get_child_objects {
        my ( $self,%args ) = @_; 

	my $ucs = ( defined $self->{ucs}
			? $self->{ucs}
			: $self 
		);

	my $ref = ( defined $args{self}
			? $args{self}
			: $self 
		);

        my $xml = ( defined $args{class_filter} 
			? $ucs->resolve_class_filter( %{ $args{class_filter} } ) 
			: $ucs->resolve_children( dn => $ref->{dn} )
		  );

	if ( ref( $xml->{outConfigs}->{ $args{type} } ) eq 'ARRAY' ) {
		$args{uid} ||= 'id';
		my $res;
		
		foreach my $obj ( @{ $xml->{outConfigs}->{ $args{type} } } ) {
			$res->{ $obj->{ $args{uid} } } = $obj
		}

		$xml->{outConfigs}->{ $args{type} } = $res
	} 
	elsif ( ( ref( $xml->{outConfigs}->{ $args{type} } ) eq 'HASH' ) 
			and ( exists $xml->{outConfigs}->{ $args{type} }->{dn} ) ) {
		$args{uid} ||= 'id';
		my $res;
		$res->{ $xml->{outConfigs}->{ $args{type} }->{ $args{uid} } } 
			= $xml->{outConfigs}->{ $args{type} };

		$xml->{outConfigs}->{ $args{type} } = $res
	}

        return ( defined $xml->{outConfigs}->{ $args{type} }
                ? do {  my @res;
                        foreach my $res ( keys %{ $xml->{outConfigs}->{ $args{type} } } ) {
                                my $obj = $args{class}->new( 
							ucs => $ucs, 
							dn  => $xml->{outConfigs}->{ $args{type} }->{$res}->{dn}, 
							id  => $res 
				);

				map { $obj->{ $_ } = $args{ eattrs }{ $_ } } keys %{ $args{ eattrs } };

                                $ref->{ $args{attr} }->{$res} = $obj;
                                push @res, $obj;
                        }

                        return @res unless $args{id};

                        return $ref->{ $args{attr} }->{ $args{id} } 
				if $args{id} and $ref->{ $args{attr} }->{ $args{id} };

                        return
                     }    
                : ()
                );
    
}

sub get_error_id {
	warn "get_error_id has been deprecated in future releases";
	return get_error( @_ )
}

sub error {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{fault}->{$id} 
			? $self->{fault}->{$id} 
			: $self->get_error($id) 
	)
}

sub get_error {
	my ( $self, $id ) = @_;

	return $self->get_errors( $id )
}

sub get_errors {
	my ( $self, $id ) = @_;

	return $self->_get_child_objects(
				id           => $id, 
				type         => 'faultInst', 
				class        => 'Cisco::UCS::Fault', 
				uid          => 'id', 
				attr         => 'fault', 
				class_filter => { 
						classId => 'faultInst'
						}
			);
}

sub _isInHierarchical {
	my $inHierarchical = lc shift;

	return 'false' unless ( $inHierarchical =~ /true|false|0|1/ ); 

	return $inHierarchical if ( $inHierarchical =~ /^true|false$/ );

	return ( $inHierarchical == 0 ? 'false' : 'true' );
}

sub _createFilter {
	my ( $self, %args ) = @_;

	unless ( defined $args{classId} ) {
		$self->{error} = 'No classId specified';
		return
	}

	my $filter = '<inFilter><and>';

	while ( my( $property,$value ) = each %args ) {
		next if ( $property eq 'inHierarchical' or $property eq 'classId' );
		$filter	.= '<eq class="' . $args{classId} . '" property="' 
			. $property . '" value="' . $value . '" />';
	}

	$filter	.= '</and></inFilter>';

	return $filter;
}

sub resolve_class {
	my ( $self, %args ) = @_;

	unless ( defined $args{classId} ) {
		$self->{error} = 'No classId specified';
		return
	}

	$args{inHierarchical} = ( 
		defined $args{inHierarchical} 
			? _isInHierarchical( $args{inHierarchical} )
			: 'false'
	);

	my $xml	= $self->_ucsm_request( '<configResolveClass inHierarchical="' 
					. $args{inHierarchical} .'" cookie="' 
					. $self->{cookie} .'" classId="'
					. $args{classId} .'" />' ) or return;

	return $xml
}	

sub resolve_classes {
	my ( $self, %args ) = @_;

	unless ( defined $args{classId} ) {
		$self->{error} = 'No classID specified';
		return
	}

	$args{inHierarchical} = ( 
		defined $args{inHierarchical}
			? _isInHierarchical( $args{inHierarchical} )
			: 'false'
	);

	my $xml	= $self->_ucsm_request(	'<configResolveClasses inHierarchical="' 
					. $args{inHierarchical}
					. '" cookie="'. $self->{cookie} .'">' 
					. '<inIds><Id value="'. $args{classId} 
					. '" /></inIds></configResolveClasses>', 'classId'
	) or return;

	return $xml
}	

sub resolve_dn {
	my ( $self, %args ) = @_;

	unless ( defined $args{dn} ) {
		$self->{error} = 'No dn specified';
		return
	}

	$args{inHierarchical} = ( 
		defined $args{inHierarchical} 
			? _isInHierarchical( $args{inHierarchical} )
			: 'false'
	);

	my $xml	= $self->_ucsm_request(	'<configResolveDn dn="'. $args{dn} 
					. '" inHierarchical="'. $args{inHierarchical} 
					. '" cookie="'. $self->{cookie} .'" />' 
				) or return;

	return $xml;
}

sub resolve_children {
	my ( $self, %args ) = @_;

	unless ( defined $args{dn} ) {
		$self->{error} = 'No dn specified';
		return
	}

	$args{inHierarchical} = ( 
		defined $args{inHierarchical}
			? _isInHierarchical( $args{inHierarchical} )
			: 'false' 
	);

	my $xml	= $self->_ucsm_request(	'<configResolveChildren inHierarchical="' 
					. $args{inHierarchical} .'" cookie="' 
					. $self->{cookie} .'" inDn="'
					. $args{dn} .'"></configResolveChildren>'
				) or return;

	return $xml
}	

sub resolve_class_filter {
	my( $self, %args ) = @_;
	
	$args{inHierarchical} = ( 
		defined $args{inHierarchical}
			? _isInHierarchical( $args{inHierarchical} )
			: 'false'
	);

	my $filter	= $self->_createFilter( %args ) or return;

	my $xml		= $self->_ucsm_request( '<configResolveClass classId="' 
						. $args{classId} .'" inHierarchical="'
						. $args{inHierarchical} .'" cookie="'
						. $self->{cookie} .'">' . $filter 
						. '</configResolveClass>', $args{classId} 
					) or return;

	return $xml
}

sub get_cluster_status {
	my $self = shift;

	my $xml	= $self->resolve_dn( dn => 'sys' ) or return;

	return ( 
		defined $xml->{outConfig}->{topSystem}
			? $xml->{outConfig}->{topSystem} 
			: undef 
	)
}

sub version {
	my $self = shift;

	my $xml	= $self->resolve_dn( dn => 'sys/mgmt/fw-system' ) or return;

	return ( 
		defined $xml->{outConfig}->{firmwareRunning}->{version}
			? $xml->{outConfig}->{firmwareRunning}->{version}
			: undef
	)
}

sub mgmt_entity {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{mgmt_entity}->{$id}
			? $self->{mgmt_entity}->{$id}
			: $self->mgmt_entity($id)
	)
}

sub get_mgmt_entity {
	my ( $self, $id ) = @_;

	return $self->get_mgmt_entities( $id )
}

sub get_mgmt_entities {
        my ( $self, $id ) = @_;

	return $self->_get_child_objects(
				id    => $id, 
				type  => 'mgmtEntity',
				class => 'Cisco::UCS::MgmtEntity',
				attr  => 'mgmt_entity'
			);
}

sub get_primary_mgmt_entity {
	my $self = shift;

	my $xml	= $self->resolve_class_filter(
				classId    => 'mgmtEntity',
				leadership => 'primary'
			) or return;

	return ( 
		defined $xml->{outConfigs}->{mgmtEntity}
			? $xml->{outConfigs}->{mgmtEntity}
			: undef
	)
}

sub get_subordinate_mgmt_entity {
	my $self = shift;

	my $xml	= $self->resolve_class_filter(
				classId    => 'mgmtEntity', 
				leadership => 'subordinate'
			) or return;

	return ( 
		defined $xml->{outConfigs}->{mgmtEntity} 
			? $xml->{outConfigs}->{mgmtEntity}
			: undef
	);
}

sub service_profile {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{service_profile}->{$id}
			? $self->{service_profile}->{$id}
			: $self->get_service_profile($id) 
	)
}

sub get_service_profile {
	my ( $self, $id ) = @_;

	return $self->get_service_profiles( $id )
}

sub get_service_profiles {
	my ( $self, $id ) = @_;

	return $self->_get_child_objects(
				id           => $id, 
				type         => 'lsServer', 
				class        => 'Cisco::UCS::ServiceProfile', 
				uid          => 'name', 
				attr         => 'service_profile', 
				class_filter => { 
						classId => 'lsServer' 
						}
			);
}

sub interconnect {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{interconnect}->{$id}
			? $self->{interconnect}->{$id}
			: $self->get_interconnect($id) 
	)
}

sub get_interconnect {
	my ( $self, $id ) = @_;

	return $self->get_interconnects( $id )
}

sub get_interconnects {
	my ( $self, $id ) = @_;

	return $self->_get_child_objects(
				id    => $id, 
				type  => 'networkElement', 
				class => 'Cisco::UCS::Interconnect', 
				attr  => 'interconnect'
			);
}

sub blade {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{blade}->{$id} 
			? $self->{blade}->{$id}
			: $self->get_blade($id) 
	)
}

sub get_blade {
	my ( $self, $id ) = @_;

	return $self->get_blades( $id )
}

sub get_blades {
	my ( $self, $id, %args ) = @_;

	return $self->_get_child_objects(
				id           => $id, 
				type         => 'computeBlade', 
				class        => 'Cisco::UCS::Blade', 
				attr         => 'blade',
				uid          => 'serverId', 
				class_filter => { 
						classId => 'computeBlade' 
						}
			);
}

sub chassis {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{chassis}->{$id}
			? $self->{chassis}->{$id}
			: $self->get_chassis($id) 
	)
}

sub get_chassis {
	my ( $self, $id ) = @_;

	return $self->get_chassiss( $id )
}

sub get_chassiss {
	my ( $self, $id ) = @_;

	return $self->_get_child_objects(
				id    => $id, 
				type  => 'equipmentChassis', 
				class => 'Cisco::UCS::Chassis', 
				attr  => 'chassis'
			);
}

sub full_state_backup {
	my ( $self, %args ) = @_;

	$args{backup_type} = 'full-state';

	return ( $self->_backup( %args ) );
}
sub all_config_backup {
	my ( $self, %args ) = @_;

	$args{backup_type} = 'config-all';

	return ( $self->_backup( %args ) );
}

sub system_config_backup {
	my ( $self, %args ) = @_;

	$args{backup_type} = 'config-system';

	return ( $self->_backup( %args ) );
}

sub logical_config_backup {
	my ( $self, %args ) = @_;

	$args{backup_type} = 'config-logical';

	return ( $self->_backup( %args ) );
}

sub _backup {
	my ( $self, %args ) = @_;

	unless( defined $args{backup_type} 	and
		defined $args{backup_proto}	and
		defined $args{backup_host}	and
		defined $args{backup_target}	and
		defined $args{backup_passwd}	and
		defined $args{backup_username} ) 
	{
		$self->{error} = 'Bad argument list';
		return
	}

	$args{admin_state} = ( 
		defined $args{admin_state} 
			? $args{admin_state} 
			: 'enabled' 
	);

	$args{preserve_pooled_values} = ( 
		defined $args{preserve_pooled_values} 
			? $args{preserve_pooled_values} 
			: 'yes' 
	);

	unless ( $args{backup_type} =~ /(config-all|full-state|config-system|config-logical)/i ) {
		$self->{error} = "Bad backup type ($args{backup_type})";
		return
	}

	unless ( $args{backup_proto} =~ /^((t|s)?ftp)|(scp)$/i ) {
		$self->{error} = "Bad backup proto' ($args{backup_proto})";
		return
	}

	my $address	= $self->get_cluster_status->{address};

	my $data = <<"XML";
<configConfMos cookie="$self->{cookie}" inHierarchical="false">
  <inConfigs>
    <pair key="sys">
      <topSystem address="$address" dn="sys" name="$self->{cluster}">
        <mgmtBackup adminState="$args{admin_state}" descr="" preservePooledValues="$args{preserve_pooled_values}" 
          proto="$args{backup_proto}" pwd="$args{backup_passwd}" remoteFile="$args{backup_target}" 
          rn="backup-$args{backup_host}" type="$args{backup_type}" 
          user="$args{backup_username}" policyOwner="local">
        </mgmtBackup>
      </topSystem>
    </pair>
  </inConfigs>
</configConfMos>
XML

	my $xml = $self->_ucsm_request( $data ) or return;

	if ( defined $xml->{'errorCode'} ) {
		my $self->{error} = ( defined $xml->{'errorDescr'} 
					? $xml->{'errorDescr'} 
					: "Unspecified error"
				);
		return
	}

	return 1;
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS - A Perl interface to the Cisco UCS XML API

=head1 SYNOPSIS

	use Cisco::UCS;

	my $ucs = Cisco::UCS->new (
				cluster		=> $cluster, 
				username	=> $username,
				passwd		=> $password
				);

	$ucs->login();

	@errors = $ucs->get_errors(severity=>"critical",ack="no");

	foreach my $error_id (@errors) {
		my %this_error = $ucs->get_error_id($error_id);
		print "Error ID: $error_id.  Severity: $this_error{severity}."
			. "  Description: $this_error{descr}\n";
	}

	print "Interconnect A serial : " 
		. $ucs->interconnect(A)->serial 
		. "\n";

	# prints "Interconnect A serial : BFG9000"

	foreach my $chassis ($ucs->chassis) {
		print "Chassis " . $chassis->id 
			. " serial : " . $chassis->serial . "\n"
	}

	# prints:
	# "Chassis 1 serial : ABC1234"
	# "Chassis 2 serial : ABC1235"
	# etc.

	print "Interconnect A Ethernet 1/1 TX bytes: " 
		. $ucs->interconnect(A)->card(1)->eth_port(1)->tx_total_bytes;

	# prints "Interconnect A Ethernet 1/1 TX bytes: 83462486"

	$ucs->logout();

=head1 DESCRIPTION

This package provides an abstracted interface to the Cisco UCS Manager XML API 
and Cisco UCS Management Information Model.

The Cisco UCS Manager (UCSM) is an embedded software agent providing access to 
the hardware and configuration management features of attached Cisco UCS 
hardware.  The Management Information Model for the UCSM is organised into a 
structured heirachy of both physical and virtual objects.  Accessing objects 
within the heirachy is done through a number of high level calls to heirachy 
search and traversal methods.

The primary aim of this package is to provide a simplified and abstract 
interface to this management heirachy.

=head2 METHODS

=head3 new ( CLUSTER, PORT, PROTO, USERNAME, PASSWORD )

	my $ucs = Cisco::UCS->new ( 	
				cluster  => $cluster, 
				port     => $port,
				proto    => $proto,
				username => $username,
				passwd   => $passwd
				);

Constructor method.  Creates a new Cisco::UCS object representing a connection 
to the Cisco UCSM XML API.  

Parameters are:

=over 3

=item cluster

The common name of the target cluster.  This name should be resolvable on the 
host from which the script is run.

=item username

The username to use for the connection.  This username needs to have the 
correct RBAC role for the operations that one intends to perform.

=item passwd

The plaintext password of the username specified for the B<username> attribute 
for the connection.

=item port

The port on which to connect to the UCSM XML API on the target cluster.  This 
parameter is optional and will default to 443 if not provided.

=item proto

The protocol with which to connect to the UCSM XML API on the target cluster.  
This value is optional hould be one of 'http' or 'https' and will default to 
'https' if not provided.

=back

=head3 login ()

	$ucs->login;
	print "Authentication token is $ucs->cookie\n";

Creates a connection to the XML API interface of a USCM management instance.  
If sucessful, the attributes of the UCSM management instance are inherited by 
the object.  Most important of these parameters is 'cookie' representing the 
authetication token that uniquely identifies the connection and which is 
subsequently passed transparently on all further communications.

The default time-out value for a token is 10 minutes, therefore if you intend 
to create a long-running session you should periodically call refresh.

=head3 refresh ()

	$ucs->refresh;

Resets the expiry time limit of the existing authentication token to the 
default timeout period of 10m.  Usually not necessary for short-lived 
connections.

=head3 logout ()

	$ucs->logout;

Expires the current authentication token.  This method should always be called 
on completion of a script to expire the authentication token and free the 
current session for use by others.  The UCS XML API has a maximum number of 
available connections, and a maximum number of sessions per user.  In order to 
ensure that the session remain available (especially if using common 
credentials), you should always call this method on completion of a script, as 
an argument to die, or in any eval where a script may fail and exit before 
logging out;

=head3 cookie ()

	print $ucs->cookie;

Returns the value of the authentication token.

=head3 cluster ()

	print $ucs->cluster;

Returns the value of cluster as given in the constructor.

=head3 dn ()

	print $ucs->dn;

Returns the distinguished name that specifies the base scope of the Cisco::UCS 
object.

=cut

=head3 get_error_id ( $ID )

	my %error = $ucs->get_error_id($id);

	while (my($key,$value) = each %error) {
		print "$key:\t$value\n";
	}
	
B<This method is deprecated, please use the equivalent get_error method>.

Returns a hash containing the UCSM event detail for the given error id.  This 
method takes a single argument; the UCSM error_id of the desired error.

=cut


=head3 error ( $id )

	my $error = $ucs->get_error($id);
	print $error->id . ":" . $error->desc . "\n";

Returns a Cisco::UCS::Fault object representing the specified error.  Note 
that this is a caching method and will return a cached object that has been 
retrieved on previous queries should on be available.

If you require a fresh object, consider using the equivalent non-caching 
B<get_error> method below.

=head2 get_error ( $ID )

Returns a Cisco::UCS::Fault object representing the specified error.  Note 
that this is a non-caching method and that the UCSM will always be queried 
for information.  Consequently this method may be more expensive than the 
equivalent caching method B<error> described above.

=head3 get_errors ()

	map {
		print '-'x50,"\n";
		print "ID		: " . $_->id . "\n";
		print "Severity		: " . $_->severity . "\n";
		print "Description	: " . $_->description . "\n";
	} grep {
		$_->severity !~ /cleared/i;
	} $ucs->get_errors;

Returns an array of Cisco::UCS::Fault objects with each object representative 
of a fault on the target system.

=head3 resolve_class ( %ARGS )

This method is used to retrieve objects from the UCSM management heirachy by 
resolving the classId for specific object types.  This method reflects one of 
the base methods provided by the UCS XML API for resolution of objects. The 
method returns an XML::Simple parsed object from the UCSM containing the 
response.

This method accepts a hash containing the value of the classID to be resolved 
and unless you have read the UCS XML API Guide and are certain that you know 
what you want to do, you shouldn't need to alter this method.

=head3 resolve_classes ( %ARGS )

This method is used to retrieve objects from the UCSM management heirachy by 
resolving several classIds for specific object types.  This method reflects 
one of the base methods provided by the UCS XML API for resolution of objects. 
The method returns an XML::Simple object from the UCSM containing the parsed 
response.

Unless you have read the UCS XML API Guide and are certain that you know what 
you want to do, you shouldn't need to alter this method.

=head3 resolve_dn ( %ARGS )

	my $blade = $ucs->resolve_dn( dn => 'sys/chassis-1/blade-2');

This method is used to retrieve objects from the UCSM management heirachy by 
resolving a specific distinguished name (dn) for a managed object.  This 
method reflects one of the base methods provided by the UCS XML API for 
resolution of objects. The method returns an XML::Simple parsed object from 
the UCSM containing the response.

The method accepts a single key/value pair, with the value being the 
distinguished name of the object.  If not known, the dn can be usually be 
retrieved by first using one of the other methods to retrieve a list of all 
object types (i.e. get_blades) and then enumerating the results to extract the 
dn from the desired object.

	my @blades = $ucs->get_blades;

	foreach my $blade in (@blades) {
		print "Dn is $blade->{dn}\n";
	}

Unless you have read the UCS XML API Guide and are certain that you know what you want to do, you shouldn't need
to alter this method.

=head3 resolve_children ( %ARGS )

	use Data::Dumper;

	my $children = $ucs->resolve_children(dn => 'sys');
	print Dumper($children);

This method is used to resolve all child objects for a given distinguished 
named (dn) object in the UCSM management heirachy.  This method reflects one 
of the base methods provided by the UCS XML API for resolution of objects. The 
method returns an XML::Simple parsed object from the UCSM containing the 
response.

In combination with Data::Dumper this is an extremely useful method for further
development by enumerating the child objects of the specified dn.  Note 
however, that the response returned from UCSM may not always accurately reflect
all elements due to folding.

Unless you have read the UCS XML API Guide and are certain that you know what 
you want to do, you shouldn't need to alter this method.

=head3 get_cluster_status ()

	my $status = $ucs->get_cluster_status;

This method returns an anonymous hash representing a brief overall cluster 
status.  In the standard configuration of a HA pair of Fabric Interconnects, 
this status is representative of the cluster as a single managed entity.

=head3 resolve_class_filter ( %ARGS )

	my $associated_servers = 
		$ucs->resolve_class_filter(	
					classId		=> 'computeBlade',
					association	=> 'associatied' 	
					);

This method is used to retrieve objects from the UCSM management heirachy by 
resolving the classId for specific object types matching a specified filter 
composed of any number of key/value pairs that correlate to object attributes.

This method is very similar to the B<resolve_class> method, however a filter 
can be specified to restrict the objects returned to those having certain 
characteristics.  This method is largely exploited by subclasses to return 
specific object types.

The filter is to be specified as any number of name/value pairs in addition to
the classId parameter.

=cut

=head3 version ()

	my $version = $ucs->version;

This method returns a string containign the running UCSM software version.

=head3 mgmt_entity ( $id )

	print "HA status : " 
		. $ucs->mgmt_entity(A)->ha_readiness 
		. "\n";
	
	my $mgmt_entity = $ucs->mgmt_entity('B');
	print $mgmt_entity->leadership;

Returns a Cisco::UCS::MgmtEntity object for the specified management instance 
(either 'A' or 'B').

This is a caching method and will return a cached copy of a previously 
retrieved Cisco::UCS::MgmtEntity object should one be available.  If you 
require a fresh copy of the object then consider using the B<get_mgmt_entity>
method below.

Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_mgmt_entity ( $id )

	print "Management services state : " 
		. $ucs->get_mgmt_entity(A)->mgmt_services_state 
		. "\n";
	
Returns a Cisco::UCS::MgmtEntity object for the specified management instance 
(either 'A' or 'B').

This method always queries the UCSM for information on the specified management
entity - consequently this method may be more expensive that the equivalent 
caching method I<get_mgmt_entity>.

Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_mgmt_entities ()

	my @mgmt_entities = $ucs->get_mgmt_entities;

	foreach $entity ( @mgmt_entities ) {
		print "Management entity " 
			. $entity->id 
			. " is the " 
			. $entity->leadership 
			. " entity\n";
	}

Returns an array of Cisco::UCS::MgmtEntity objects representing all management 
entities in the cluster (usually two - 'A' and 'B').

=head3 get_primary_mgmt_entity ()

	my $primary = $ucs->get_primary_mgmt_entity;
	print "Management entity $entity->{id} is primary\n";

Returns an anonymous hash containing information on the primary UCSM management
entity object.  This is the active managing instance of UCSM in the target 
cluster.

=head3 get_subordinate_mgmt_entity ()

	print   'Management entity ', 
		$ucs->get_subordinate_mgmt_entity->{id}, 
		' is the subordinate management entity in cluster ',
		$ucs->{cluster},"\n";

Returns an anonymous hash containing information on the subordinate UCSM 
management entity object.  

=head3 service_profile ( $ID )

Returns a Cisco::UCS::ServiceProfile object where $ID is the user-specified 
name of the service profile.

This is a caching method and will return a cached copy of a previously 
retrieved Cisco::UCS::ServiceProfile object should one be available.  If you 
require a fresh copy of the object then consider using the 
B<get_service_profile> method below.

Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_service_profile ( $ID )

Returns a Cisco::UCS::ServiceProfile object where $ID is the user-specified 
name of the service profile.

This method always queries the UCSM for information on the specified service 
profile - consequently this method may be more expensive that the equivalent 
caching method I<service_profile>.

Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_service_profiles ()

	my @service_profiles = $ucs->get_service_profiles;

	foreach my $service_profile (@service_profiles) {
		print "Service Profile: " 
			. $service_profile->name 
			. " associated to blade: " 
			. $service_profile->pnDn 
			. "\n";
	}

Returns an array of Cisco::UCS::ServiceProfile objects representing all service
profiles currently present on the target UCS cluster.

=head3 interconnect ( $ID )

	my $serial = $ucs->interconnect(A)->serial;

	print "Interconnect $_ serial: " 
		. $ucs->interconnect($_) 
		. "\n" 
	for qw(A B);

Returns a Cisco::UCS::Interconnect object for the specified interconnect ID 
(either A or B).

Note that the default behaviour of this method is to return a cached copy of a 
previously retrieved Cisco::UCS::Interconnect object if one is available.  
Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_interconnect ( $ID )

	my $interconnect = $ucs->get_interconnect(A);

	print $interconnect->model;

Returns a Cisco::UCS::Interconnect object for the specified interconnect ID
(either A or B).

This method always queries the UCSM for information on the specified 
interconnect - contrast this with the behaviour of the caching method 
I<interconnect()>.

Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_interconnects ()

	my @interconnects = $ucs->get_interconnects;

	foreach my $ic (@interconnects) {
		print "Interconnect $ic->id operability is $ic->operability\n";
	}

Returns an array of Cisco::UCS::Interconnect objects.  This is a non-caching 
method.

=head3 blade ( $ID )

	print "Blade 1/1 serial : " . $ucs->blade('1/1')->serial . "\n;

Returns a Cisco::UCS::Blade object representing the specified blade as given by
the value of $ID.  The blade ID should be given using the standard Cisco UCS 
blade identification form as used in the UCSM CLI; namely 
B<chassis_id/blade_id> where both chassis_id and blade_id are valid numerical 
values for the target cluster.  Note that you will have to enclose the value of
$ID in quotation marks to avoid a syntax error.

Note that this is a caching method and the default behaviour of this method is 
to return a cached copy of a previously retrieved Cisco::UCS::Blade object if 
one is available.  If a non-cached object is required, then please consider 
using the equivalent B<get_blade> method below.

Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_blade ( $ID )

	print "Blade 1/1 serial : " . $ucs->get_blade('1/1')->serial . "\n;

Returns a Cisco::UCS::Blade object representing the specified blade as given by
the value of $ID.  The blade ID should be given using the standard Cisco UCS 
blade identification form as used in the UCSM CLI; namely 
B<chassis_id/blade_id> where both chassis_id and blade_id are valid numerical 
values for the target cluster.  Note that you will have to enclose the value of
$ID in quotation marks to avoid a syntax error.

Note that this method is non-caching and always queries the UCSM for 
information.  Consequently may be more expensive than the equivalent caching 
B<blade> method described above.

=head3 get_blades ()

	my @blades = $ucs->get_blades();

	foreach my $blade ( @blades ) {
		print "Model: $blade->{model}\n";
	}

Returns an array of B<Cisco::UCS::Blade> objects with each object representing 
a blade within the UCS cluster.

=head3 chassis ( $ID )

	my $chassis = $ucs->chassis(1);
	print "Chassis 1 serial : " . $chassis->serial . "\n";
	# or
	print "Chassis 1 serial : " . $ucs->chassis(1)->serial . "\n";

	foreach my $psu ( $ucs->chassis(1)->get_psus ) {
		print $psu->id . " thermal : " . $psu->thermal . "\n"
	}

Returns a Cisco::UCS::Chassis object representing the chassis identified by by 
the specified value of ID.

Note that this is a caching method and the default behaviour of this method is 
to return a cached copy of a previously retrieved Cisco::UCS::Chassis object if
one is available.  If a non-cached object is required, then please consider 
using the equivalent B<get_chassis> method below.

Please see the B<Caching Methods> section in B<NOTES> for further information.

=head3 get_chassis ( $ID )

	my $chassis = $ucs->get_chassis(1);
	print "Chassis 1 label : " . $chassis->label . "\n";
	# or
	print "Chassis 1 label : " . $ucs->get_chassis(1)->label . "\n";

Returns a Cisco::UCS::Chassis object representing the chassis identified by the
specified value of ID.

Note that this method is non-caching and always queries the UCSM for 
information.  Consequently may be more expensive than the equivalent caching 
B<chassis> method described above.

=head3 get_chassiss
	
	my @chassis = $ucs->get_chassiss();

	foreach my $chassis (@chassis) {
		print "Chassis $chassis->{id} serial number: $chassis->{serial}\n";
	}

Returns an array of Cisco::UCS::Chassis objects representing all chassis 
present within the cluster.

Note that this method is named get_chassiss (spelt with two sets of double-s's)
as there exists no English language collective plural for the word chassis.

=head3 full_state_backup

This method generates a new "full state" type backup for the target UCS 
cluster.  Internally, this method is implemented as a wrapper method around the
private backup method.  Required parameters for this method:

=over 3

=item backup_proto 

The protocol to use for transferring the backup from the target UCS cluster to 
the backup host.  Must be one of: ftp, tftp, scp or sftp.

=item backup_host

The host to which the backup will be transferred.

=item backup_target

The fully qualified name of the file to which the backup is to be saved on the 
backup host.  This should include the full directory path and the target 
filename.

=item backup_username

The username to be used for creation of the backup file on the backup host.  
This username should have write/modify file system access to the backup target 
location on the backup host using the protocol specified in the backup-proto 
attribute.

=item backup_passwd

The plaintext password of the user specified for the backup_username attribute.

=back

=head3 all_config_backup

This method generates a new "all configuration" backup for the target UCS 
cluster.  Internally, this method is implemented as a wrapper method around the
private backup method.  For the required parameters for this method, please 
refer to the documentation of the B<full_state_backup> method.

=head3 system_config_backup

This method generates a new "system configuration" backup for the target UCS 
cluster.  Internally, this method is implemented as a wrapper method around the
private backup method.  For the required parameters for this method, please 
refer to the documentation of the B<full_state_backup> method.

=head3 logical_config_backup

This method generates a new "logical configuration" backup for the target UCS 
cluster.  Internally, this method is implemented as a wrapper method around the
private backup method.  For the required parameters for this method, please 
refer to the documentation of the B<full_state_backup> method.

=head1 NOTES

=head2 Caching Methods

Several methods in the module return cached objects that have been previously 
retrieved by querying UCSM, this is done to improve the performance of methods 
where a cached copy is satisfactory for the intended purpose.  The trade off 
for the speed and lower resource requirement is that the cached copy is not 
guaranteed to be an up-to-date representation of the current state of the 
object.

As a matter of convention, all caching methods are named after the singular 
object (i.e. interconnect(), chassis()) whilst non-caching methods are named 
I<get_<object>>.  Non-caching methods will always query UCSM for the object,
as will requests for cached objects not present in cache.

=cut

=over 3

=item *

The documentation could be cleaner and more thorough.  The module was written 
some time ago with only minor amounts of time and effort invested since.
There's still a vast opportunity for improvement.

=item *

Better error detection and handling.  Liberal use of Carp::croak should ensure 
that we get some minimal diagnostics and die nicely, and if used according to 
instructions, things should generally work.  When they don't however, it would 
be nice to know why.

=item *

Detection of request and return type.  Most of the methods are fairly 
explanatory in what they return, however it would be nice to make better use of
wantarray to detect what the user wants and handle it accordingly.

=item *

Clean up of the UCS package to remove unused methods and improve the ones that 
we keep.  I'm still split on leaving some of the methods common to most object 
type (fans, psus) in the main package.

=back

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cisco-ucs at rt.cpan.org>, 
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as 
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

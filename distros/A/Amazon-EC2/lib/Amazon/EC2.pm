package Amazon::EC2;

use strict;
use warnings;

use parent qw/Amazon::API/;

use Amazon::Credentials;
use JSON qw/from_json to_json/;
use Scalar::Util qw/reftype/;
use XML::Simple;
use Data::Dumper;

=pod

=head1 NAME

C<Amazon::EC2>

=head1 SYNOPSIS

 use strict;
 use warnings;
 
 use Amazon::EC2;
 use Amazon::Credentials;
 use Data::Dumper;
 
 my $ec2 = new Amazon::EC2({credentials => new Amazon::Credentials});
 
 my $result = $ec2->DescribeInstances();
 
 print Dumper($result);

=head1 DESCRIPTION

Perl interface to the Amazon EC2 API

=head1 METHODS

See the Amazon EC2 API documentation for method
arguments. L</http://docs.aws.amazon.com/AWSEC2/latest/APIReference/Welcome.html>

=cut


=pod

=head2 new

 new( options )

=over 5

=item region

AWS region.  default: us-east-1

=item credentials

An C<Amazon::Credentials> object.  You can specify your credentials
using this object or by setting your access keys and optional token
directly.

=item aws_secret_access_key

Your AWS secret access key.

=item aws_access_key_id

Your AWS access key id.

=item token

Optional token if your credentials were temporary (from the role or assumed role).

=back

I<Note that if no credentials are given, the constructor will behave as if you had done:>

 new Amazon::EC2({credentials => new Amazon::Credentials});

I<...which will use your default credentials. See C<Amazon::Credentials>.>

=cut

my @API_METHODS = qw/AcceptReservedInstancesExchangeQuote
		     AcceptVpcEndpointConnections
		     AcceptVpcPeeringConnection
		     AllocateAddress
		     AllocateHosts
		     AssignIpv6Addresses
		     AssignPrivateIpAddresses
		     AssociateAddress
		     AssociateDhcpOptions
		     AssociateIamInstanceProfile
		     AssociateRouteTable
		     AssociateSubnetCidrBlock
		     AssociateVpcCidrBlock
		     AttachClassicLinkVpc
		     AttachInternetGateway
		     AttachNetworkInterface
		     AttachVolume
		     AttachVpnGateway
		     AuthorizeSecurityGroupEgress
		     AuthorizeSecurityGroupIngress
		     BundleInstance
		     CancelBundleTask
		     CancelConversionTask
		     CancelExportTask
		     CancelImportTask
		     CancelReservedInstancesListing
		     CancelSpotFleetRequests
		     CancelSpotInstanceRequests
		     ConfirmProductInstance
		     CopyFpgaImage
		     CopyImage
		     CopySnapshot
		     CreateCustomerGateway
		     CreateDefaultSubnet
		     CreateDefaultVpc
		     CreateDhcpOptions
		     CreateEgressOnlyInternetGateway
		     CreateFlowLogs
		     CreateFpgaImage
		     CreateImage
		     CreateInstanceExportTask
		     CreateInternetGateway
		     CreateKeyPair
		     CreateLaunchTemplate
		     CreateLaunchTemplateVersion
		     CreateNatGateway
		     CreateNetworkAcl
		     CreateNetworkAclEntry
		     CreateNetworkInterface
		     CreateNetworkInterfacePermission
		     CreatePlacementGroup
		     CreateReservedInstancesListing
		     CreateRoute
		     CreateRouteTable
		     CreateSecurityGroup
		     CreateSnapshot
		     CreateSpotDatafeedSubscription
		     CreateSubnet
		     CreateTags
		     CreateVolume
		     CreateVpc
		     CreateVpcEndpoint
		     CreateVpcEndpointConnectionNotification
		     CreateVpcEndpointServiceConfiguration
		     CreateVpcPeeringConnection
		     CreateVpnConnection
		     CreateVpnConnectionRoute
		     CreateVpnGateway
		     DeleteCustomerGateway
		     DeleteDhcpOptions
		     DeleteEgressOnlyInternetGateway
		     DeleteFlowLogs
		     DeleteFpgaImage
		     DeleteInternetGateway
		     DeleteKeyPair
		     DeleteLaunchTemplate
		     DeleteLaunchTemplateVersions
		     DeleteNatGateway
		     DeleteNetworkAcl
		     DeleteNetworkAclEntry
		     DeleteNetworkInterface
		     DeleteNetworkInterfacePermission
		     DeletePlacementGroup
		     DeleteRoute
		     DeleteRouteTable
		     DeleteSecurityGroup
		     DeleteSnapshot
		     DeleteSpotDatafeedSubscription
		     DeleteSubnet
		     DeleteTags
		     DeleteVolume
		     DeleteVpc
		     DeleteVpcEndpointConnectionNotifications
		     DeleteVpcEndpoints
		     DeleteVpcEndpointServiceConfigurations
		     DeleteVpcPeeringConnection
		     DeleteVpnConnection
		     DeleteVpnConnectionRoute
		     DeleteVpnGateway
		     DeregisterImage
		     DescribeAccountAttributes
		     DescribeAddresses
		     DescribeAggregateIdFormat
		     DescribeAvailabilityZones
		     DescribeBundleTasks
		     DescribeClassicLinkInstances
		     DescribeConversionTasks
		     DescribeCustomerGateways
		     DescribeDhcpOptions
		     DescribeEgressOnlyInternetGateways
		     DescribeElasticGpus
		     DescribeExportTasks
		     DescribeFlowLogs
		     DescribeFpgaImageAttribute
		     DescribeFpgaImages
		     DescribeHostReservationOfferings
		     DescribeHostReservations
		     DescribeHosts
		     DescribeIamInstanceProfileAssociations
		     DescribeIdentityIdFormat
		     DescribeIdFormat
		     DescribeImageAttribute
		     DescribeImages
		     DescribeImportImageTasks
		     DescribeImportSnapshotTasks
		     DescribeInstanceAttribute
		     DescribeInstanceCreditSpecifications
		     DescribeInstances
		     DescribeInstanceStatus
		     DescribeInternetGateways
		     DescribeKeyPairs
		     DescribeLaunchTemplates
		     DescribeLaunchTemplateVersions
		     DescribeMovingAddresses
		     DescribeNatGateways
		     DescribeNetworkAcls
		     DescribeNetworkInterfaceAttribute
		     DescribeNetworkInterfacePermissions
		     DescribeNetworkInterfaces
		     DescribePlacementGroups
		     DescribePrefixLists
		     DescribePrincipalIdFormat
		     DescribeRegions
		     DescribeReservedInstances
		     DescribeReservedInstancesListings
		     DescribeReservedInstancesModifications
		     DescribeReservedInstancesOfferings
		     DescribeRouteTables
		     DescribeScheduledInstanceAvailability
		     DescribeScheduledInstances
		     DescribeSecurityGroupReferences
		     DescribeSecurityGroups
		     DescribeSnapshotAttribute
		     DescribeSnapshots
		     DescribeSpotDatafeedSubscription
		     DescribeSpotFleetInstances
		     DescribeSpotFleetRequestHistory
		     DescribeSpotFleetRequests
		     DescribeSpotInstanceRequests
		     DescribeSpotPriceHistory
		     DescribeStaleSecurityGroups
		     DescribeSubnets
		     DescribeTags
		     DescribeVolumeAttribute
		     DescribeVolumes
		     DescribeVolumesModifications
		     DescribeVolumeStatus
		     DescribeVpcAttribute
		     DescribeVpcClassicLink
		     DescribeVpcClassicLinkDnsSupport
		     DescribeVpcEndpointConnectionNotifications
		     DescribeVpcEndpointConnections
		     DescribeVpcEndpoints
		     DescribeVpcEndpointServiceConfigurations
		     DescribeVpcEndpointServicePermissions
		     DescribeVpcEndpointServices
		     DescribeVpcPeeringConnections
		     DescribeVpcs
		     DescribeVpnConnections
		     DescribeVpnGateways
		     DetachClassicLinkVpc
		     DetachInternetGateway
		     DetachNetworkInterface
		     DetachVolume
		     DetachVpnGateway
		     DisableVgwRoutePropagation
		     DisableVpcClassicLink
		     DisableVpcClassicLinkDnsSupport
		     DisassociateAddress
		     DisassociateIamInstanceProfile
		     DisassociateRouteTable
		     DisassociateSubnetCidrBlock
		     DisassociateVpcCidrBlock
		     EnableVgwRoutePropagation
		     EnableVolumeIO
		     EnableVpcClassicLink
		     EnableVpcClassicLinkDnsSupport
		     GetConsoleOutput
		     GetConsoleScreenshot
		     GetHostReservationPurchasePreview
		     GetLaunchTemplateData
		     GetPasswordData
		     GetReservedInstancesExchangeQuote
		     ImportImage
		     ImportInstance
		     ImportKeyPair
		     ImportSnapshot
		     ImportVolume
		     ModifyFpgaImageAttribute
		     ModifyHosts
		     ModifyIdentityIdFormat
		     ModifyIdFormat
		     ModifyImageAttribute
		     ModifyInstanceAttribute
		     ModifyInstanceCreditSpecification
		     ModifyInstancePlacement
		     ModifyLaunchTemplate
		     ModifyNetworkInterfaceAttribute
		     ModifyReservedInstances
		     ModifySnapshotAttribute
		     ModifySpotFleetRequest
		     ModifySubnetAttribute
		     ModifyVolume
		     ModifyVolumeAttribute
		     ModifyVpcAttribute
		     ModifyVpcEndpoint
		     ModifyVpcEndpointConnectionNotification
		     ModifyVpcEndpointServiceConfiguration
		     ModifyVpcEndpointServicePermissions
		     ModifyVpcPeeringConnectionOptions
		     ModifyVpcTenancy
		     MonitorInstances
		     MoveAddressToVpc
		     PurchaseHostReservation
		     PurchaseReservedInstancesOffering
		     PurchaseScheduledInstances
		     RebootInstances
		     RegisterImage
		     RejectVpcEndpointConnections
		     RejectVpcPeeringConnection
		     ReleaseAddress
		     ReleaseHosts
		     ReplaceIamInstanceProfileAssociation
		     ReplaceNetworkAclAssociation
		     ReplaceNetworkAclEntry
		     ReplaceRoute
		     ReplaceRouteTableAssociation
		     ReportInstanceStatus
		     RequestSpotFleet
		     RequestSpotInstances
		     ResetFpgaImageAttribute
		     ResetImageAttribute
		     ResetInstanceAttribute
		     ResetNetworkInterfaceAttribute
		     ResetSnapshotAttribute
		     RestoreAddressToClassic
		     RevokeSecurityGroupEgress
		     RevokeSecurityGroupIngress
		     RunInstances
		     RunScheduledInstances
		     StartInstances
		     StopInstances
		     TerminateInstances
		     UnassignIpv6Addresses
		     UnassignPrivateIpAddresses
		     UnmonitorInstances
		     UpdateSecurityGroupRuleDescriptionsEgress
		     UpdateSecurityGroupRuleDescriptionsIngress
		    /;

our $VERSION = '1.0.1';

sub new {
  my $class = shift;
  my $options = shift || {};

  $class->SUPER::new({
		      %$options,
		      service_url_base => 'ec2',
		      version          => '2016-11-15',
		      api_methods      => \@API_METHODS
		     });
}

=pod

=head2 DescribeInstances

 DescribeInstances(options)

C<options> is a hash of optional parameters to pass to the API.  See
the API description at
L</http://docs.aws.amazon.com/AWSEC2/latest/APIReference/Welcome.html>

To create pass the C<Filter> parameters, pass an array of hash references.

 my $filter [{Name => 'instance-id', Value => 'i-0b91d8e165cf2f41b'}]);
 my $result = $ec2->DescribeInstances(Filter => $filter);
 print to_json($result, { pretty  => 1 });

=cut

sub DescribeInstances {
  my $self = shift;
  my %args = @_;
  my @options;
  
  foreach my $param (keys %args) {
    if ( ref($args{$param}) && reftype($args{$param}) eq 'ARRAY') {
      push @options, _format_filter($args{$param});
    }
    else {
      push @options, sprintf("%s=%s", $param, $args{$param});
    }
  }
    
  return XMLin($self->describe_instances(@options ? \@options : ()));
}


sub CreateSnapshot {
  my $self = shift;
  my %args = @_;
  my @parms = _format_parameters(%args);
  
  return XMLin($self->create_snapshot(\@parms));
}

=pod

=head2 CreateTags

 CreateTags( resources ) 

 CreateTags( $id => { Key => 'Name', Value => 'foo' } );
 CreateTags( $id => [ { Key => 'Name', Value => 'foo' },
                      { Key => 'Environment', Value => 'boo'}
                    ]);

=cut

sub CreateTags {
  my $self = shift;
  my %resources = @_;

  my @params;
  my $idx=1;
  
  foreach my $r (keys %resources) {
    if ( reftype($resources{$r}) ne 'ARRAY' ) {
      $resources{$r} = [ $resources{$r} ];
    }
    
    foreach (@{$resources{$r}}) {
      push @params, sprintf("ResourceId.%d=%s", $idx, $r);
      push @params, sprintf("Tag.%d.Key=%s", $idx, $_->{Key});
      push @params, sprintf("Tag.%d.Value=%s", $idx, $_->{Value});
      $idx++;
    }
  }
  
  return XMLin($self->create_tags(\@params));
}

sub _format_parameters {
  my %args = @_;
  my @options;
  
  foreach (keys %args) {
    push @options, sprintf("%s=%s", $_, $args{$_});
  }
  
  return @options;
}

sub _format_filter {
  my $filter = shift;
  
  my @options;

  for (my $idx=0; $idx<@{$filter}; $idx++) {
    push @options, sprintf("Filter.%d.Name=%s&Filter.%d.Value=%s",
			   $idx+1, $filter->[$idx]->{Name},
			   $idx+1, $filter->[$idx]->{Value});
  }
  
  return @options;
}


=pod

=head1 NOTES

This is a work-in-progress. I'll add API methods as I need them and
B<pull requests> gladly accepted. ;-)

Why another Perl module for the EC2 API when there are already a
couple candidates out there and the C<PAWS> project is tracking the
Python B<boto> library?

Well, probably for no good reason other than those others are,
generally speaking, fairly heavy with lot's of dependencies.  This
module is designed to be light and require few additional Perl
modules.  Hopefully, that means it will be relatively fast compared to
using something like the AWS CLI or C<Paws> (which seems to rely on
Moose, which seems to rely on, well most of the known CPAN universe).

YMMV, but if you find this useful, good.  If not, try C<PAWS>,
C<Net::Amazon::EC2>, or C<VM::EC2>.

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=head1 SEE ALSO

C<Amazon::API>, C<Amazon::Credentials>, C<PAWS>, C<Net::Amazon::EC2>,
C<VM::EC2>

=cut

1;

package App::EC2;

use strict;
use warnings;

use App::FargateStack::Constants;
use Carp;
use Data::Dumper;
use File::Temp qw(tempfile);
use List::Util qw(any none uniq);
use JSON;
use Text::ASCIITable::EasyTable;

use Role::Tiny::With;
with 'App::AWS';

use parent 'App::Command';

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    profile
    region
    security_group_name
    subnets
    vpc_id
  )
);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $self = $class->SUPER::new(@args);

  if ( !$self->get_vpc_id ) {
    my @eligible_vpcs = $self->find_eligible_vpcs;
    $self->get_logger->info( sprintf 'eligible VPCS: [%s]', join q{,}, @eligible_vpcs );

    croak 'ERROR: could not find a Fargate-compatible VPC'
      if !@eligible_vpcs;

    croak sprintf "ERROR: found more than one Fargate-compatible VPC:\n%s", join "\n  - ", q{}, @eligible_vpcs
      if @eligible_vpcs > 1;

    $self->get_logger->warn( sprintf 'WARNING: no vpc_id set in config, using compatible VPC: [%s]', $eligible_vpcs[0] );

    $self->set_vpc_id( $eligible_vpcs[0] );
  }

  my $subnets = $self->get_subnets;
  my $vpc_id  = $self->get_vpc_id;

  # if the caller did not send any subnets, find all usable public and
  # private subnets
  if ( !$subnets ) {
    my $result = $self->describe_subnets( $vpc_id, 'Subnets' );

    croak sprintf "ERROR: there are no subnets in %s\n", $vpc_id
      if !@{$result};

    $subnets = $self->categorize_subnets;  # find private, public subnets
    $self->set_subnets($subnets);
  }
  else {
    my $usable_subnets = $self->categorize_subnets;

    my @all_subnets = map { @{ $usable_subnets->{$_} || [] } } qw(public private);

    $self->get_logger->debug(
      sub {
        return Dumper(
          [ all_subnets    => \@all_subnets,
            usable_subnets => $usable_subnets,
            subnets        => $subnets,
          ]
        );
      }
    );

    my $warning = <<'END_OF_WARNING';
WARNING: %s is not in the list of subnets with a route to the internet.

Tasks in private subnets require either:
- A NAT gateway (for general internet access), or
- Properly configured VPC endpoints for ECR, S3, STS, Logs, etc.

Without one of these, your task may fail to start or access required services.
END_OF_WARNING

    foreach my $type (qw(public private)) {
      foreach my $id ( @{ $subnets->{$type} || [] } ) {
        next if any { $_ eq $id } @all_subnets;
        $self->get_logger->warn( sprintf $warning, $id );
      }
    }
  }

  return $self;
}

########################################################################
sub find_eligible_vpcs {
########################################################################
  my ($self) = @_;

  my $result = $self->describe_internet_gateways('InternetGateways[].Attachments[]');

  my @vpcs_with_igw = map { $_->{VpcId} } @{ $result || [] };
  my @vpcs_with_natgw;

  my $query = 'NatGateways[?State==`available`][{VpcId: VpcId}][].VpcId';

  foreach my $vpc_id (@vpcs_with_igw) {
    my $gateways = $self->describe_nat_gateways( vpc_id => $vpc_id, query => $query );
    push @vpcs_with_natgw, @{$gateways};
  }

  return uniq @vpcs_with_natgw, @vpcs_with_igw;
}

########################################################################
sub describe_internet_gateways {
########################################################################
  my ( $self, $query ) = @_;

  return $self->command( 'describe-internet-gateways' => [ $query ? ( '--query' => $query ) : () ] );
}

########################################################################
sub find_security_group_name {
########################################################################
  my ( $self, $group_id ) = @_;

  my $query = 'SecurityGroups[].GroupName';

  return $self->command(
    'describe-security-groups' => [
      '--group-ids' => $group_id,
      '--output'    => 'text',
      '--query'     => $query,
    ]
  );
}

########################################################################
sub is_sg_authorized {
########################################################################
  my ( $self, $group_id, $source_group ) = @_;

  croak "usage: is_sg_authorized(group-id, source-group-id)\n"
    if !$group_id || !$source_group;

  my $query = sprintf 'SecurityGroups[].IpPermissions[].UserIdGroupPairs[?GroupId==`%s`][]', $source_group;

  my $result = $self->command(
    'describe-security-groups' => [
      '--group-ids' => $group_id,
      '--query'     => $query
    ]
  );

  croak sprintf "could not describe-security-groups for [%s]\n%s", $group_id, $self->get_error
    if !$result;

  return @{$result} ? $TRUE : $FALSE;
}

########################################################################
sub describe_nat_gateways {
########################################################################
  my ( $self, %args ) = @_;

  my ( $vpc_id, $query, $output ) = @args{qw(vpc_id query output)};

  my $filters = $vpc_id ? sprintf 'Name=vpc-id,Values=%s', $vpc_id : $EMPTY;

  my $result = $self->command(
    'describe-nat-gateways' => [
      $filters ? ( '--filter' => $filters ) : (),
      $query   ? ( '--query'  => $query )   : (),
      $output  ? ( '--output' => $output )  : (),
    ]
  );

  croak sprintf "could not describe NAT gateway\n%s", $self->get_error
    if !$result;

  return $result;
}

########################################################################
sub describe_vpc_nat_gateways {
########################################################################
  my ( $self, $vpc_id ) = @_;

  $vpc_id //= $self->get_vpc_id;

  my $filters = sprintf 'Name=vpc-id,Values=%s', $vpc_id;

  my $query = 'NatGateways[*].{Id:NatGatewayId, SubnetId:SubnetId, State:State}';

  my $result = $self->command(
    'describe-nat-gateways' => [
      '--filter' => $filters,
      '--query'  => $query
    ]
  );

  croak sprintf "could not describe NAT gateway for VPC: [%s]\n%s", $vpc_id, $self->get_error
    if !$result;

  return $result;
}

########################################################################
sub describe_subnet {
########################################################################
  my ( $self, $subnets, $query ) = @_;

  croak "usage: describe_subnet(subnet-id)\n"
    if !$subnets;

  my @subnets = ref $subnets ? @{$subnets} : ($subnets);

  return $self->command(
    'describe-subnets' => [
      '--subnet-id' => @subnets,
      $query ? ( '--query' => $query ) : ()
    ]
  );

}

########################################################################
sub describe_security_group_rules {
########################################################################
  my ( $self, %args ) = @_;

  my ( $group_id, $query, $filters ) = @args{qw(group_id query filters)};

  if ($group_id) {
    $filters = sprintf 'Name=group-id,Values=%s', $group_id;
  }

  return $self->command(
    'describe-security-group-rules' => [ $filters ? ( '--filters' => $filters ) : (), $query ? ( '--query' => $query ) : (), ]
  );
}

########################################################################
sub describe_subnets {
########################################################################
  my ( $self, @args ) = @_;

  my $params = ref $args[0] ? $args[0] : { vpc_id => $args[0], query => $args[1] };

  $params->{vpc_id} //= $self->get_vpc_id;

  my ( $vpc_id, $subnet_ids, $query ) = @{$params}{qw(vpc_id subnets query)};

  my @subnets = $subnet_ids ? @{$subnet_ids} : ();

  return $self->command(
    'describe-subnets' => [
      $vpc_id  ? ( '--filters', 'Name=vpc-id,Values=' . $vpc_id ) : (),
      $query   ? ( '--query' => $query )                          : (),
      @subnets ? ( '--subnet-ids' => @subnets )                   : (),
    ]
  );
}

########################################################################
sub find_public_subnets {
########################################################################
  my ($self) = @_;

  return $self->get_subnets->{public};
}

########################################################################
sub find_private_subnets {
########################################################################
  my ($self) = @_;

  return $self->get_subnets->{private};
}

########################################################################
sub _find_subnets {
########################################################################
  my ( $self, $type ) = @_;

  my $subnets = $self->get_subnets;

  croak "subnets is not set\n"
    if !$subnets;

  return $subnets->{ lc $type };
}

########################################################################
sub describe_route_tables {
########################################################################
  my ( $self, %args ) = @_;

  my ( $query, $route_table_id ) = @args{qw(query route_table_id)};

  my $vpc_id = $self->get_vpc_id;

  my $result = $self->command(
    'describe-route-tables' => [
      '--filters' => 'Name=vpc-id,Values=' . $vpc_id,
      $query          ? ( '--query'           => $query )                             : (),
      $route_table_id ? ( '--route-table-ids' => ( split /\s/xsm, $route_table_id ) ) : ()
    ]
  );

  croak sprintf "unable to describe-route-tables for [%s]\n%s", $route_table_id, $self->get_error
    if !$result;

  return $result;
}

########################################################################
sub list_route_table_associations {
########################################################################
  my ($self) = @_;

  my $vpc_id = $self->get_vpc_id;

  my $query = 'RouteTables[].{RouteTableId:RouteTableId, Associations:Associations[].SubnetId}';

  return $self->describe_route_tables( query => $query );
}

########################################################################
sub categorize_subnets {
########################################################################
  my ( $self, $vpc_id ) = @_;

  $vpc_id //= $self->get_vpc_id;

  my $result = $self->describe_route_tables( query => 'RouteTables' );

  my %subnets;

  my @route_tables = @{$result};

  foreach my $r (@route_tables) {
    my $has_igw = any {
           exists $_->{DestinationCidrBlock}
        && $_->{DestinationCidrBlock} eq '0.0.0.0/0'
        && exists $_->{GatewayId}
        && $_->{GatewayId} =~ /^igw/xsm
    } @{ $r->{Routes} };

    my $has_nat = any {
           exists $_->{DestinationCidrBlock}
        && $_->{DestinationCidrBlock} eq '0.0.0.0/0'
        && exists $_->{NatGatewayId}
        && $_->{NatGatewayId}
    } @{ $r->{Routes} };

    my $type = $has_igw ? 'public' : $has_nat ? 'private' : 'isolated';

    foreach my $a ( @{ $r->{Associations} } ) {
      next if !$a->{SubnetId};
      push @{ $subnets{$type} }, $a->{SubnetId};
    }
  }

  return \%subnets;
}

########################################################################
sub describe_security_groups {
########################################################################
  my ( $self, $query, @filters ) = @_;

  my $vpc_id = $self->get_vpc_id;

  croak "no vpc_id\n"
    if !$vpc_id;

  push @filters, 'Name=vpc-id,Values=' . $vpc_id;

  return $self->command(
    'describe-security-groups' => [ $query ? ( '--query' => $query ) : (), map { ( '--filters' => $_ ) } @filters, ] );
}

########################################################################
sub describe_security_group {
########################################################################
  my ( $self, $security_group, $query, $filters ) = @_;

  my $result = $self->command(
    'describe-security-groups' => [

      '--filters', 'Name=vpc-id,Values=' . $self->get_vpc_id,
      '--query' => sprintf( q{SecurityGroups[?GroupName == '%s']}, $security_group ),
      $query   ? ( '--query'   => $query ) : (),
      $filters ? ( '--filters' => $query ) : ()
    ]
  );

  return
    if !$result;

  return $result->[0];
}

########################################################################
sub create_security_group {
########################################################################
  my ( $self, $security_group_name, $description ) = @_;

  croak "usage: create_security_group(name, description)\n"
    if !$security_group_name || !$description;

  return $self->command(
    'create-security-group' => [
      '--group-name'  => $security_group_name,
      '--description' => $description,
      '--vpc-id'      => $self->get_vpc_id,
      '--query'       => 'GroupId',
      '--output'      => 'text',
    ]
  );
}

########################################################################
sub revoke_security_group_ingress {
########################################################################
  my ( $self, %args ) = @_;

  my ( $group_id, $port, $protocol, $source_group ) = @args{qw(group_id port protocol source_group)};

  $protocol //= 'tcp';
  $port     //= '80';

  return $self->command(
    'revoke-security-group-ingress' => [
      '--group-id'     => $group_id,
      '--port'         => $port,
      '--protocol'     => $protocol,
      '--source-group' => $source_group,
    ]
  );

}

########################################################################
sub authorize_security_group_ingress {
########################################################################
  my ( $self, %args ) = @_;

  my ( $group_id, $port, $protocol, $source_group, $cidr ) = @args{qw(group_id port protocol source_group cidr)};

  $protocol //= 'tcp';
  $port     //= '80';

  return $self->command(
    'authorize-security-group-ingress' => [
      '--group-id' => $group_id,
      '--port'     => $port,
      '--protocol' => $protocol,
      $cidr         ? ( '--cidr'         => $cidr )         : (),
      $source_group ? ( '--source-group' => $source_group ) : (),
    ]
  );
}

########################################################################
sub validate_subnets {
########################################################################
  my ( $self, $subnets ) = @_;

  # flatten private, public subnets
  my @all_subnets = map { @{ $subnets->{$_} // [] } } keys %{$subnets};

  my @valid_subnets = map { $_->{SubnetId} } @{ $self->describe_subnets()->{Subnets} };

  foreach my $s (@all_subnets) {
    croak sprintf "ERROR: The subnet [%s] does not exist in vpc: [%s]\nvalid subnets: \n\t%s\n", $s,
      $self->get_vpc_id, join "\n\t", @valid_subnets
      if none { $_ eq $s } @valid_subnets;
  }

  return;
}

########################################################################
sub delete_security_group {
########################################################################
  my ( $self, $security_group_id ) = @_;

  return $self->command( 'delete-security-group' => [ '--group-id' => $security_group_id ] );
}

########################################################################
sub describe_network_interfaces {
########################################################################
  my ( $self, $eni_list, $query ) = @_;

  return $self->command(
    'describe-network-interfaces' => [
      '--network-interface-ids' => ( ref $eni_list ? @{$eni_list} : $eni_list ),
      $query ? ( '--query' => $query ) : ()
    ]
  );
}

1;

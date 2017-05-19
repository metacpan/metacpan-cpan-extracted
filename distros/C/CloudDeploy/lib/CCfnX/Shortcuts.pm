package Fn;
  use strict;
  use warnings;
  sub Join {
    my ($with, @args) = @_;
    return { 'Fn::Join' => [ $with, [ @args ] ] };
  }

  sub ImportValue {
    my ($value) = @_;
    return { "Fn::ImportValue" => $value };
  }

  sub Split {
    my ($delimiter, $string) = @_;
    return { "Fn::Split" => [ $delimiter, $string ] };
  }

  sub FindInMap {
    my ($map_name, @keys) = @_;
    return { "Fn::FindInMap" => [ $map_name, @keys ] };
  }

  sub Sub {
    my ($string, @vars) = @_;
    if (@vars) {
      return { "Fn::Sub" => [ $string, { @vars } ] };
    } else {
      return { "Fn::Sub" => $string };
    }
  }

  sub Base64 {
    my ($what) = @_;
    return { "Fn::Base64" => $what };
  }

  sub GetAZs {
    return { "Fn::GetAZs" => "" };
  }

  sub Select {
    my ($index, $array) = @_;
    return { "Fn::Select" => [ $index, $array ] };
  }

  sub Equals {
    my $value1 = shift;
    my $value2 = shift;
    die "Fn::Equals only admits two parameters" if (@_ > 0);
    return { "Fn::Equals" => [ $value1, $value2 ] };
  }

  sub Not {
    my $condition = shift;
    die "Fn::Equals only admits one parameter" if (@_ > 0);
    return { "Fn::Not" => [ $condition ] }
  }

  sub If {
    my $condition_name = shift;
    my $value_true = shift;
    my $value_false = shift;
    die "Fn::If only admits three parameters" if (@_ > 0);
    return { "Fn::If" => [ $condition_name, $value_true, $value_false ] };
  }
  
  sub Or {
    my @conditions = @_;
    return { 'Fn::Or' => [ @conditions ] };
  }

1;
package CCfnX::Shortcuts; 

  use Carp;
  use Moose::Exporter;
  
  Moose::Exporter->setup_import_methods(
    with_meta => [ 'resource', 'output', 'condition', 'metadata', 'stack_version' ],
    as_is => [ qw/Ref ConditionRef GetAtt UserData CfString Parameter Attribute FindImage ImageFor Tag GetPolicy ELBListener TCPELBListener SGRule GetASGStatus GetInstanceStatus/ ],
  );

  sub condition {
    Moose->throw_error('Usage: output \'name\' => Ref|GetAtt|{}')
        if (@_ != 3);
    my ( $meta, $name, $condition ) = @_;

    if ($meta->find_attribute_by_name($name)){
      die "Redeclared resource/output/condition $name";
    }

    $meta->add_attribute(
      $name,
      is => 'rw',
      isa => "Cfn::Value",
      traits => [ 'Condition' ],
      lazy => 1,
	  coerce => 1,
      default => sub {
        $condition;
      },
    );
  }
  
  sub resource {
    # TODO: Adjust this error condition to better detect incorrect num of params passed
    Moose->throw_error('Usage: resource \'name\' => \'Type\', { key => value, ... }[, { DependsOn => ... }]')
        if (@_ != 4 and @_ != 5);
    my ( $meta, $name, $resource, $options, $extra ) = @_;

    if ($meta->find_attribute_by_name($name)){
      die "Redeclared resource/output/condition $name";
    }

    $extra = {} if (not defined $extra);

    my %args = ();
    if (ref($options) eq 'CODE'){
      %args = &$options();
    } elsif (ref($options) eq 'HASH'){
      %args = %$options;
    }

    my $res_isa;
    if ($resource =~ m/^Custom::/){
      $res_isa = "Cfn::Resource::AWS::CloudFormation::CustomResource";
    } else {
      $res_isa = "Cfn::Resource::$resource";
    }
    
    $meta->add_attribute(
      $name,
      is => 'rw', 
      isa => $res_isa, 
      traits => [ 'Resource' ],
      lazy => 1, 
      default => sub {
        return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource')->coerce({
          Type => $resource, 
          Properties => \%args, 
          %$extra }
        );
      },
    );
  }

  sub output {
    Moose->throw_error('Usage: output \'name\' => Ref|GetAtt|{}')
        if (@_ != 3);
    my ( $meta, $name, $options ) = @_;
 
    if ($meta->find_attribute_by_name($name)){
      die "Redeclared resource/output/condition $name";
    }
   
    if (my ($att) = ($name =~ m/^\+(.*)/)) {
      $meta->add_attribute(
        $att,
        is => 'rw', 
        isa => 'Cfn::Value',
        coerce => 1,
        traits => [ 'Output', 'PostOutput' ],
        lazy => 1, 
        default => sub { return $options },
      );
    } else {
      $meta->add_attribute(
        $name,
        is => 'rw', 
        isa => 'Cfn::Value',
        coerce => 1,
        traits => [ 'Output' ],
        lazy => 1, 
        default => sub {
          return $options;
        },
      );
    }
  }

  sub metadata {
    Moose->throw_error('Usage: metadata \'name\' => {json-object}')
        if (@_ != 3);
    my ( $meta, $name, $options ) = @_;

    if (my ($att) = ($name =~ m/^\+(.*)/)) {
      $meta->add_attribute(
        $att,
        is => 'rw',
        isa => 'Cfn::Value',
        coerce => 1,
        traits => [ 'Metadata' ],
        lazy => 1,
        default => sub { return $options },
      );
    } else {
      $meta->add_attribute(
        $name,
        is => 'rw',
        isa => 'Cfn::Value',
        coerce => 1,
        traits => [ 'Metadata' ],
        lazy => 1,
        default => sub { return $options },
      );
    }
  }

  sub stack_version {
    Moose->throw_error('Usage: stack_version \'version\'')
        if (@_ != 2);
    my ( $meta, $version ) = @_;

    $meta->add_attribute(
      'StackVersion',
      is => 'rw',
      isa => 'Cfn::Value',
      coerce => 1,
      traits => [ 'Metadata' ],
      lazy => 1,
      default => sub { return $version },
    );
  }

#    Moose->throw_error('Usage: resource \'name\' => ( key => value, ... )')
#        if @_ % 2 == 1;
#  
#    my %context = Moose::Util::_caller_info;
#    $context{context} = 'resource declaration';
#    $context{type} = 'class';
#    my %options = ( definition_context => \%context, @_ );
#    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
#    $meta->add_attribute( $_, is => 'rw', isa => 'AWS::EC2::Instance', lazy => 1, %options ) for @$attrs;
#  }

  sub GetPolicy {
    my $param = shift;
    die "Must specify an exported policy" unless defined $param;
    return CCfnX::DynamicValue->new(Value => sub {
      return @{ $_[0]->params->$param->{Policy} };
    });
  }

  sub Parameter {
    my $param = shift;
    die "Must specify a parameter to read from" if (not defined $param);
    return CCfnX::DynamicValue->new(Value => sub { return $_[0]->params->$param });
  }
  
  sub Attribute {
    my $path = shift;
    my ($attribute, $method, $rest) = split /\./, $path;
    croak "Don't understand attributes with more than two path elements" if (defined $rest);
    croak "Must specify an attribute read from" if (not defined $attribute);
    if (not defined $method) {
      return CCfnX::DynamicValue->new(Value => sub { return $_[0]->$attribute });
    } else {
      return CCfnX::DynamicValue->new(Value => sub { return $_[0]->$attribute->$method });
    }
  }

  sub SpecifyInSubClass {
    return CCfnX::DynamicValue->new(Value => sub { die "You must specify a value" });
  }

  sub Tag {
    my ($tag_key, $tag_value, %rest) = @_;
    { Key => $tag_key, Value => $tag_value, %rest };
  }

  sub Ref {
    my $ref = shift;
    die "Ref expected a logical name to reference to" if (not defined $ref);
    return { Ref => $ref };
  }

  sub ConditionRef {
    my $condition = shift;
    die "Condition expected a logical name to reference to" if (not defined $condition);
    return { Condition => $condition };
  }

  sub GetAtt {
    my ($ref, $property) = @_;
    die "GetAtt expected a logical name and a property name" if (not defined $ref or not defined $property);
    { 'Fn::GetAtt' => [ $ref, $property ] }
  }

  sub ELBListener {
    my ($lbport, $lbprotocol, $instanceport, $instanceprotocol) = @_;
    die "no port for ELB listener passed" if (not defined $lbport);
    die "no protocol for ELB listener passed" if (not defined $lbprotocol);
    $instanceport     = $lbport     if (not defined $instanceport);
    $instanceprotocol = $lbprotocol if (not defined $instanceprotocol);

    return { InstancePort => $instanceport,
             InstanceProtocol => $instanceprotocol,
             LoadBalancerPort => $lbport,
             Protocol => $lbprotocol
           }
  }

  sub TCPELBListener {
    my ($lbport, $instanceport) = @_;
    return ELBListener($lbport, 'TCP', $instanceport);
  }

  # Creates a rule for a security group:
  # IF port is a number, it opens just that port
  # IF port is a range: number-number, it opens that port range
  # to: where to open the rule to. If this looks like a CIDR, it will populate CidrIP in the rule,
  #     else, it will populate SourceSecurityGroupId. (This means that you can't use this shortcut
  #     to open a SG to a Ref(...) in a parameter, for example).
  # proto: if specified, uses that protocol. If not, TCP by default
  sub SGRule {
    my ($port, $to, $proto) = @_;

    my ($from_port, $to_port);
    if ($port =~ m/\-/) {
      if ($port eq '-1') { 
        ($from_port, $to_port) = (-1, -1);
      } else {
        ($from_port, $to_port) = split /\-/, $port, 2;
      }
    } else {
      ($from_port, $to_port) = ($port, $port);
    }

    $proto = 'tcp' if (not defined $proto);
    my $rule = { IpProtocol => $proto, FromPort => $from_port, ToPort => $to_port};

    my $key;
    # Rules to detect when we're trying to open to a CIDR
    $key = 'CidrIp' if ($to =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/);
    # Fallback to SSGroupId
    $key = 'SourceSecurityGroupId' if (not defined $key);
    
    $rule->{ $key } = $to;

    return $rule;
  }

  sub FindImage {
    my ($name, %criterion) = @_;
    require CloudDeploy::AMIDB;
    return CCfnX::DynamicValue->new(Value => sub {
      my $self = shift;
      my $amidb = CloudDeploy::AMIDB->new;
	  if (ref($name) and $name->isa('CCfnX::DynamicValue')){
        $name = $name->to_value($self)->Value;
	  }
	  foreach my $key (keys %criterion) {
		  if(ref($criterion{$key}) and $criterion{$key}->isa('CCfnX::DynamicValue')){
			  $criterion{$key} = $criterion{$key}->to_value($self)->Value;
		  }
	  }
      $amidb->find(
        Account => CloudDeploy::Config->new->account, 
        Region => $self->params->region,
        Name => $name,
        %criterion
      )->prop('ImageId');
    });
  }

  sub OSImage {
    require CloudDeploy::AMIDB;

  }

  use CCfnX::LocateAMI;
  sub ImageFor {
    my ($name, $arch, $root) = @_;
    warn "ImageFor is getting deprecated! Substitute for FindImage('$name', Arch => '$arch', Root => '$root', Tags => '...')";
    return CCfnX::DynamicValue->new(Value => sub {
      my $self = shift;
      return CCfnX::LocateAMI->new(
        name => $name
      )->ami($self->params->region, $arch, $root);
    })
  }

  use CCfnX::UserData;
  sub UserData {
    my @args = @_;
    return CCfnX::DynamicValue->new(Value => sub {
      my @ctx = @_;
      CCfnX::UserData->new(text => $args[0])->as_hashref(@ctx);
    });
  }

  sub CfString {
    my $string = shift;
    return CCfnX::DynamicValue->new(Value => sub {
      my @ctx = @_;
      CCfnX::UserData->new(text => $string)->as_hashref_joins(@ctx);
    });
  }

  sub GetASGStatus {
     my ($asg_name, %defaults) = @_;
  
     require Paws;
  
     my %dyn_values = ();
     foreach my $property (keys %defaults) {
       $dyn_values{ $property } =  CCfnX::DynamicValue->new(Value => sub {
         my $self = shift;
         my $stack_name = $self->params->name;
         if ($self->params->update) {
           #return get_asg_info($self->params->region, $stack_name, $asg_name, $property)
           my $resources = $self->stash->{ cfn_resources };
           if (not defined $resources) {
             my $res_array = Paws->service('CloudFormation',
               region => $self->params->region
             )->DescribeStackResources(StackName => $stack_name)->StackResources;
  
             $resources = $self->stash->{ cfn_resources } = { map {
                 ($_->LogicalResourceId => $_ )
               } @$res_array
             };
           }
  
           my $asg = $self->stash->{ asg };
           if (not defined $asg){
             my $asg_physid = $resources->{ $asg_name }->PhysicalResourceId;
             $asg = Paws->service('AutoScaling',
               region => $self->params->region
             )->DescribeAutoScalingGroups(AutoScalingGroupNames => [
               $asg_physid
             ]);
             die "Didn't find autoscaling group $asg_physid" if (scalar(@{ $asg->AutoScalingGroups } == 0));
             $asg = $self->stash->{ asg } = $asg->AutoScalingGroups->[0];
           }
  
           return $asg->$property;
         } else {
           return $defaults{ $property }
         }
       });
     }
     return %dyn_values;
  }
  
  sub GetInstanceStatus {
     my ($instance_name, %defaults) = @_;
  
     require Paws;
  
     my %dyn_values = ();
     foreach my $property (keys %defaults) {
       $dyn_values{ $property } =  CCfnX::DynamicValue->new(Value => sub {
         my $self = shift;
         my $stack_name = $self->params->name;
         if ($self->params->update) {
           my $resources = $self->stash->{ cfn_resources };
           if (not defined $resources) {
             my $res_array = Paws->service('CloudFormation',
               region => $self->params->region
             )->DescribeStackResources(StackName => $stack_name)->StackResources;
  
             $resources = $self->stash->{ cfn_resources } = { map {
                 ($_->LogicalResourceId => $_ )
               } @$res_array
             };
           }
  
           my $instance = $self->stash->{ instance };
           if (not defined $instance){
             my $instance_physid = $resources->{ $instance_name }->PhysicalResourceId;
             $instance = Paws->service('EC2',
               region => $self->params->region
             )->DescribeInstances(InstanceIds => [
               $instance_physid
             ]);
             die "Didn't find instance $instance_physid" if (scalar(@{ $instance->Reservations } == 0));
             $instance = $self->stash->{ instance } = $instance->Reservations->[0]->Instances->[0];
           }
  
           return $instance->$property;
         } else {
           return $defaults{ $property }
         }
       });
     }
     return %dyn_values;
  }
  
1;

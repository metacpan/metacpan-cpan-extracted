package AWS;
  use strict;
  use warnings;

  sub AccountId {
    return { Ref => 'AWS::AccountId' };
  }
  sub NotificationARNs {
    return { Ref => 'AWS::NotificationARNs' };
  }
  sub NoValue {
    return { Ref => 'AWS::NoValue' };
  }
  sub Region {
    return { Ref => 'AWS::Region' };
  }
  sub StackId {
    return { Ref => 'AWS::StackId' };
  }
  sub StackName {
    return { Ref => 'AWS::StackName' };
  }

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

  sub Cidr {
    my ($ipblock, $count, $sizemask) = @_;
    if (defined $sizemask) {
      return { 'Fn::Cidr' => [ $ipblock, $count, $sizemask ] };
    } else {
      return { 'Fn::Cidr' => [ $ipblock, $count ] };
    }
  }

  # Generates { "Fn::Transform" : { "Name" : macro name, "Parameters" : {key : value, ... } } }
  sub Transform {
    my ($macro_name, $params) = @_;

    return { 'Fn::Transform' => {
      name => $macro_name,
      parameters => $params,
    }}
  };

1;
package CCfnX::Shortcuts;

  use Carp;
  use Moose::Exporter;
  use Regexp::Common qw(net);
  use LWP::Simple;
  use JSON::MaybeXS;
  use Scalar::Util qw(looks_like_number);
  use CCfnX::DSL::Inheritance;

  our $ubuntu_release_table_url = 'https://cloud-images.ubuntu.com/locator/ec2/releasesTable';

  Moose::Exporter->setup_import_methods(
    with_meta => [ 'resource', 'output', 'condition', 'mapping', 'metadata', 'stack_version', 'transform' ],
    as_is => [ qw/Ref ConditionRef GetAtt UserData CfString Parameter Attribute FindImage Json
                Tag GetPolicy ELBListener TCPELBListener SGRule SGEgressRule
                GetASGStatus GetInstanceStatus FindUbuntuImage FindBaseImage SpecifyInSubClass/ ],
  );

  sub transform {
    Moose->throw_error('Usage: transform name1, name2, ... , nameN;')
        if ( @_ < 1 );
    my ( $meta, @transforms ) = @_;

    if ( $meta->find_attribute_by_name('transform') ) {
      die "There is already a transform element in the template";
    }

    # Allow just one of this to be declared
    $meta->add_attribute(
      'transform_spec',
      is      => 'rw',
      isa     => 'ArrayRef[Str]',
      traits  => ['Transform'],
      lazy    => 1,
      default => sub { \@transforms },
    );

  }


  sub condition {
    Moose->throw_error('Usage: output \'name\' => Ref|GetAtt|{}')
        if (@_ != 3);
    my ( $meta, $name, $condition ) = @_;

    if ($meta->find_attribute_by_name($name)){
      die "Redeclared resource/output/condition/mapping $name";
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

    $extra = {} if (not defined $extra);

    my %args = ();
    if (ref($options) eq 'CODE'){
      %args = &$options();
    } elsif (ref($options) eq 'HASH'){
      %args = %$options;
    };

    my $res_isa;
    if ($resource =~ m/^Custom::/){
      $res_isa = "Cfn::Resource::AWS::CloudFormation::CustomResource";
    } else {
      $res_isa = "Cfn::Resource::$resource";
    }

    my $default_coderef = resolve_resource_inheritance_dsl({
      meta => $meta,
      name => $name,
      resource => $resource,
      attr_family => 'CCfnX::Meta::Attribute::Trait::Resource',
      properties => \%args,
      extra => $extra,
    });

    $meta->add_attribute(
      $name,
      is => 'rw',
      isa => $res_isa,
      traits => [ 'Resource' ],
      lazy => 1,
      default => $default_coderef,
    );

  }

  sub output {
    Moose->throw_error('Usage: output \'name\' => Ref|GetAtt|{}[, { Condition => ... }]')
        if ( @_ lt 3 and @_ gt 5  );
    my ( $meta, $name, $options, $extra ) = @_;

    if ($meta->find_attribute_by_name($name)){
      die "Redeclared resource/output/condition/mapping $name";
    }

    $extra = {} if (not defined $extra);

    if (my ($att) = ($name =~ m/^\+(.*)/)) {
      $meta->add_attribute(
        $att,
        is => 'rw',
        isa => 'Cfn::Output',
        coerce => 1,
        traits => [ 'Output', 'PostOutput' ],
        lazy => 1,
        default => sub {
          return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Output')->coerce({
            Value => $options,
            %$extra }
          );
        },
      );
    } else {
      $meta->add_attribute(
        $name,
        is => 'rw',
        isa => 'Cfn::Output',
        coerce => 1,
        traits => [ 'Output' ],
        lazy => 1,
        default => sub {
          return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Output')->coerce({
            Value => $options,
            %$extra }
          );
        },
      );
    }
  }

  sub mapping {
    Moose->throw_error('Usage: mapping \'name\' => { key => value, ... }')
        if (@_ != 3);
    my ( $meta, $name, $options ) = @_;

    if ($meta->find_attribute_by_name($name)){
      die "Redeclared resource/output/condition/mapping $name";
    }

    my %args = ();
    if (ref($options) eq 'CODE'){
      %args = &$options();
    } elsif (ref($options) eq 'HASH'){
      %args = %$options;
    }

    $meta->add_attribute(
      $name,
      is => 'rw',
      isa => 'Cfn::Mapping',
      traits => [ 'Mapping' ],
      lazy => 1,
      default => sub {
        return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Mapping')->coerce({ %args });
      },
    );
  }

  sub metadata {
    Moose->throw_error('Usage: metadata \'name\' => {json-object}')
        if (@_ != 3);
    my ( $meta, $name, @options ) = @_;

    if (my ($att) = ($name =~ m/^\+(.*)/)) {
      $meta->add_attribute(
        $att,
        is => 'rw',
        isa => 'Cfn::Value',
        coerce => 1,
        traits => [ 'Metadata' ],
        lazy => 1,
        default => sub {
          return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce(@options);
        },
      );
    } else {
      $meta->add_attribute(
        $name,
        is => 'rw',
        isa => 'Cfn::Value',
        coerce => 1,
        traits => [ 'Metadata' ],
        lazy => 1,
        default => sub {
          return Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value')->coerce(@options);
        },
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
    # When CCfnX::Shortcuts is attached to a class, it
    # overrides the Parameters method of Cfn without warning, making $cfn->Parameter('') return unexpected
    # things.
    #
    # This "if" is a hack to detect when Parameters is being called as a method ($_[0] is a ref)
    # or if it's being called as a shortcut
    #
    # TODO: decide how to fix the fact that Cfn has a Parameters method
    if (@_ > 1){
      my ($self, $key, $value) = @_;
      if (defined $value) {
        # Setter
        $self->Parameters({}) if (not defined $self->Parameters);
        $self->Parameters->{ $key } = $value;
      } else {
        # Getter
        return $self->Parameters->{ $key } if (defined $self->Parameters);
        return undef;
      }
    }
    my $param = shift;
    die "Must specify a parameter to read from" if (not defined $param);
    return CCfnX::DynamicValue->new(Value => sub {
      my $cfn = shift;
      Moose->throw_error("DynamicValue didn't get it's context") if (not defined $cfn);
      return $cfn->params->$param
    });
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

  sub Json {
    my $json = shift;
    return decode_json($json);
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
    my ($port, $to, $proto_or_desc, $desc) = @_;
    my $proto;

    if (defined($proto_or_desc)) {
        if ($proto_or_desc eq 'tcp'
                or $proto_or_desc eq 'udp'
                or $proto_or_desc eq 'icmp'
                or looks_like_number($proto_or_desc)) {
            $proto = $proto_or_desc;
        } else {
            $proto = 'tcp';
            $desc  = $proto_or_desc;
        }
    }

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
    $rule->{ Description } = $desc if (defined $desc);

    my $key;
    # Rules to detect when we're trying to open to a CIDR

    # If $to is a reference, it means that it is either:
    #   - A CloudDeploy Ref of another resource
    #   - A CCfnX::DynamicValue object (usually coming from a Parameter())
    # In both cases, it ends up pointing to a SG identifier.
    # If $to is an IP address, it will come in form of a string (scalar)
    # hence falling back to a SSGroupId
    unless (ref($to)) {
        $key = 'CidrIp' if ($to =~ m/$RE{net}{IPv4}/);
        $key = 'CidrIpv6' if ($to =~ m/$RE{net}{IPv6}/);
    }

    # Fallback to SSGroupId
    $key = 'SourceSecurityGroupId' if (not defined $key);

    $rule->{ $key } = $to;

    return $rule;
  }

  sub SGEgressRule {
    my ($port, $to, $proto_or_desc, $desc) = @_;
    my $proto;

    if (defined($proto_or_desc)) {
        if ($proto_or_desc eq 'tcp'
                or $proto_or_desc eq 'udp'
                or $proto_or_desc eq 'icmp'
                or looks_like_number($proto_or_desc)) {
            $proto = $proto_or_desc;
        } else {
            $proto = 'tcp';
            $desc  = $proto_or_desc;
        }
    }

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
    $rule->{ Description } = $desc if (defined $desc);

    my $key;
    # Rules to detect when we're trying to open to a CIDR

    # If $to is a reference, it means that it is either:
    #   - A CloudDeploy Ref of another resource
    #   - A CCfnX::DynamicValue object (usually coming from a Parameter())
    # In both cases, it ends up pointing to a SG identifier.
    # If $to is an IP address, it will come in form of a string (scalar)
    # hence falling back to a SSGroupId
    unless (ref($to)) {
        $key = 'CidrIp' if ($to =~ m/$RE{net}{IPv4}/);
        $key = 'CidrIpv6' if ($to =~ m/$RE{net}{IPv6}/);
    }

    # Fallback to SSGroupId
    $key = 'DestinationSecurityGroupId' if (not defined $key);

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

  sub _extract_ami_from_uri {
      my $uri = shift || confess "Need URI";

      $uri =~ m{<a.*href.*>([\s\S]+?)</a>};
      return $1;
  }

  # NOTE: Only hvm:ebs-ssd supported!
  sub FindUbuntuImage {
      my $region = shift || confess "Need Region";
      my $version = shift || confess "Need Version";

      my $raw = get $ubuntu_release_table_url;
      die "Could not get Ubuntu release information" unless defined $raw;

      my $json = JSON->new->utf8->relaxed(1);
      my $info = $json->decode($raw)->{aaData};
      my @h = map {
        _extract_ami_from_uri($_->[6])
      } grep {
            $_->[0] eq $region &&
            $_->[1] eq $version &&
            $_->[3] eq 'amd64' &&
            $_->[4] eq 'hvm:ebs-ssd'
      } @$info;

      if (scalar @h > 1) {
          confess "Got more than a single AMI!";
      } elsif (scalar @h == 0) {
          confess "Did not find an image for '$version' in region '$region'";
      }

      return shift @h;

  }

  sub FindBaseImage {
    my $region  = shift;
    my @filters = @_;

    use DateTime::Format::Strptime qw( );

    my @describe_images_filter = map {
      my ( $name, $value ) = split( '=', $_ );
      { Name => $name, Values => [$value] };
    } @filters;

    my $ec2 = Paws->service( 'EC2', region => $region );
    my @amis = @{ $ec2->DescribeImages(
        Filters => \@describe_images_filter,
    )->Images };

    # print "\n\n Unsorted list of amis: \n";
    # foreach my $ami (@amis) { printf( "%s - %s\n", $ami->ImageId, $ami->CreationDate ) }

    my @sorted_amis = sort {

      my $format = DateTime::Format::Strptime->new(
        pattern   => '%Y-%m-%dT%T',
        time_zone => 'UTC',
        on_error  => 'croak',
        strict    => 1,
      );
      my $dta = $format->parse_datetime( $a->CreationDate );
      my $dtb = $format->parse_datetime( $b->CreationDate );

      # Reversed sort so the latest one ends up in position 0
      $dtb <=> $dta
    } @amis;

    # print "\n\n Sorted list of amis: \n";
    # foreach my $ami (@sorted_amis) { printf( "%s - %s\n", $ami->ImageId, $ami->CreationDate ) }

    my $ami = $sorted_amis[0];

    die "FindBaseImage: Couldn't find any image that match the specified filters\n" if not defined $ami;
    warn sprintf( "FindBaseImage: using '%s' with ID '%s' as the base image (created at %s)\n", $ami->Name, $ami->ImageId, $ami->CreationDate );
    return $ami->ImageId;
  }

  sub OSImage {
    require CloudDeploy::AMIDB;

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

             $resources = { map {
                 ($_->LogicalResourceId => $_ )
               } @$res_array
             };
             $self->add_to_stash('cfn_resources', $resources);
           }

           my $asg = $self->stash->{ $asg_name };
           if (not defined $asg){
             my $asg_physid = $resources->{ $asg_name }->PhysicalResourceId;
             $asg = Paws->service('AutoScaling',
               region => $self->params->region
             )->DescribeAutoScalingGroups(AutoScalingGroupNames => [
               $asg_physid
             ]);
             die "Didn't find autoscaling group $asg_physid" if (scalar(@{ $asg->AutoScalingGroups } == 0));
             $asg = $asg->AutoScalingGroups->[0];
             $self->add_to_stash($asg_name, $asg);
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

             $resources = { map {
                 ($_->LogicalResourceId => $_ )
               } @$res_array
             };
             $self->add_to_stash('cfn_resources', $resources);
           }

           my $instance = $self->stash->{ $instance_name };
           if (not defined $instance){
             my $instance_physid = $resources->{ $instance_name }->PhysicalResourceId;
             $instance = Paws->service('EC2',
               region => $self->params->region
             )->DescribeInstances(InstanceIds => [
               $instance_physid
             ]);
             die "Didn't find instance $instance_physid" if (scalar(@{ $instance->Reservations } == 0));
             $instance = $self->stash->{ instance } = $instance->Reservations->[0]->Instances->[0];
             $self->add_to_stash($instance_name, $instance);
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

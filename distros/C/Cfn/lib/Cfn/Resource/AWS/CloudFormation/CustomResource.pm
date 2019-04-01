use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFormation::CustomResource',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFormation::CustomResource->new( %$_ ) };

package Cfn::Resource::Properties::AWS::CloudFormation::CustomResource {
  use Moose;
  use MooseX::SlurpyConstructor;
  extends 'Cfn::Resource::Properties';
  # ServiceToken is the only defined property in a CustomResource. The rest of it's properties
  # are free-form, so we store them in _extra (via the slurpy attribute that MooseX::SlurpyConstructor
  # provides
  has ServiceToken => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1);
  has _extra => (isa => 'Cfn::Value::Hash', is => 'ro', coerce => 1, slurpy => 1);

  override as_hashref => sub {
    my $self = shift;
    my @args = @_;

    my $ret = { ServiceToken => $self->ServiceToken->as_hashref(@args) };
    return $ret if (not defined $self->_extra);

    foreach my $att (keys %{ $self->_extra->Value }) {;
      if (defined $self->_extra->Value->{ $att }) {
        my @ret = $self->_extra->Value->{ $att }->as_hashref(@args);
        if (@ret == 1) {
          $ret->{ $att } = $ret[0];
        } else {
          die "A property returned an odd number of values";
        }
      }
    }
    return $ret;
  };

}

package Cfn::Resource::AWS::CloudFormation::CustomResource {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFormation::CustomResource', is => 'rw', coerce => 1, required => 1);
  has Version    => (isa => 'Cfn::Value', is => 'rw', coerce => 1);

  sub AttributeList { undef }

  sub supported_regions {
    require Cfn::Resource::AWS::IAM::User;
    Cfn::Resource::AWS::IAM::User->supported_regions;
  }

  # CustomResources don't have a defined set of attributes for GetAtt
  override hasAttribute => sub {
    my ($self, $attribute) = @_;
    return 1;
  };

  around as_hashref => sub {
    my ($orig, $self, @rest) = @_;
    my $cfn = $rest[0];

    my $hash = $self->$orig(@rest);
    $hash->{ Type } = 'AWS::CloudFormation::CustomResource' if ($cfn->cfn_options->custom_resource_rename);
    $hash->{ Version } = $self->Version->as_hashref if (defined $self->Version);
    return $hash;
  };
}

1;

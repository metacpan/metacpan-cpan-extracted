use Moose::Util::TypeConstraints;

subtype 'Cfn::ValueHash',
     as 'HashRef[Cfn::Value]';

my $cfn_value_constraint = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Value');
coerce 'Cfn::ValueHash',
  from 'HashRef',  via {
  my $original = $_;
  return { map { ($_ =>  $cfn_value_constraint->coerce($original->{ $_ }) ) } keys %$original };
};

coerce 'Cfn::Resource::Properties::AWS::CloudFormation::CustomResource',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFormation::CustomResource->new( %$_ ) };

package Cfn::Resource::Properties::AWS::CloudFormation::CustomResource {
  use Moose;
  use MooseX::SlurpyConstructor;
  extends 'Cfn::Resource::Properties';
  has ServiceToken => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
  has _extra => (isa => 'Cfn::ValueHash', is => 'ro', coerce => 1, slurpy => 1);

  override as_hashref => sub {
    my $self = shift;
    my @args = @_;

    my $ret = { ServiceToken => $self->ServiceToken->as_hashref(@args) };
    foreach my $att (keys %{ $self->_extra }) {;
      if (defined $self->_extra->{ $att }) {
        my @ret = $self->_extra->{ $att }->as_hashref(@args);
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
}

1;

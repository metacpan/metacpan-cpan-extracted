package Cfn::Resource::AWS::IAM::ExportablePolicy {
  use Moose;
  extends 'Cfn::Resource';
  use Cfn::Resource::AWS::IAM::Policy;

  sub BUILD {
    my $self = shift;
    $self->Metadata({ Policy => $self->Properties->PolicyDocument->Value->{Statement} });
    $self->Type('AWS::IAM::Policy');
  }
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IAM::Policy', is => 'rw', coerce => 1, required => 1);
}

1;

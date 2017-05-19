use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CertificateManager::Certificate',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CertificateManager::Certificate->new( %$_ ) };

package Cfn::Resource::AWS::CertificateManager::Certificate {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CertificateManager::Certificate', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::CertificateManager::Certificate  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has DomainName => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has DomainValidationOptions => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has SubjectAlternativeNames => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
  has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1)
}

1;

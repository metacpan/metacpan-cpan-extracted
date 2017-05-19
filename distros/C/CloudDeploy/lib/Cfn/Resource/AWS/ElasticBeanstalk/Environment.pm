use Moose::Util::TypeConstraints;

#coerce 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Environment',
#  from 'HashRef',
#   via { Cfn::Resource::Properties::AWS::ElasticBeanstalk::Environment->new( %$_ ) };
#
#class Cfn::Resource::AWS::ElasticBeanstalk::Environment {
#  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Environment', is => 'rw', coerce => 1, required => 1);
#}
#
#class Cfn::Resource::Properties::AWS::ElasticBeanstalk::Environment  {
#  has  => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
#  has  => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
#}
#
#1;

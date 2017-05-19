use Moose::Util::TypeConstraints;

#coerce 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application',
#  from 'HashRef',
#   via { Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application->new( %$_ ) };
#
#class Cfn::Resource::AWS::ElasticBeanstalk::Application {
#  has Properties => (isa => 'Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application', is => 'rw', coerce => 1, required => 1);
#}
#
#class Cfn::Resource::Properties::AWS::ElasticBeanstalk::Application  {
#  has  => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
#  has  => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
#}
#
#1;

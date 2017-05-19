use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::RDS::OptionGroup',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::RDS::OptionGroup->new( %$_ ) };

package Cfn::Resource::AWS::RDS::OptionGroup {
        use Moose;
        extends 'Cfn::Resource';
        has Properties => (isa => 'Cfn::Resource::Properties::AWS::RDS::OptionGroup', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::RDS::OptionGroup  {
        use Moose;
        use MooseX::StrictConstructor;
        extends 'Cfn::Resource::Properties';
        has EngineName => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has MajorEngineVersion => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
        has OptionGroupDescription => (isa => 'Cfn::Value', is => 'rw', coerce => 1);
		has OptionConfigurations => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
        has Tags => (isa => 'Cfn::Value::Array|Cfn::Value::Function', is => 'rw', coerce => 1);
}

1;


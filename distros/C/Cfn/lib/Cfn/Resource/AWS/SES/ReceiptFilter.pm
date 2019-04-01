# AWS::SES::ReceiptFilter generated from spec 2.25.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::SES::ReceiptFilter->new( %$_ ) };

package Cfn::Resource::AWS::SES::ReceiptFilter {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter::IpFilter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter::IpFilter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SES::ReceiptFilter::IpFilterValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SES::ReceiptFilter::IpFilterValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Cidr => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Policy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter::Filter',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter::Filter',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::SES::ReceiptFilter::FilterValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::SES::ReceiptFilter::FilterValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IpFilter => (isa => 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter::IpFilter', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::SES::ReceiptFilter {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Filter => (isa => 'Cfn::Resource::Properties::AWS::SES::ReceiptFilter::Filter', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;

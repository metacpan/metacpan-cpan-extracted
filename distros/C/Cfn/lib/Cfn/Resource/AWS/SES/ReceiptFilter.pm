# AWS::SES::ReceiptFilter generated from spec 18.4.0
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
       return Cfn::Resource::Properties::Object::AWS::SES::ReceiptFilter::IpFilter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SES::ReceiptFilter::IpFilter {
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
       return Cfn::Resource::Properties::Object::AWS::SES::ReceiptFilter::Filter->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::SES::ReceiptFilter::Filter {
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
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::SES::ReceiptFilter - Cfn resource for AWS::SES::ReceiptFilter

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::SES::ReceiptFilter.

See L<Cfn> for more information on how to use it.

=head1 AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut

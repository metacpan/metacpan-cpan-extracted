# AWS::IoTThingsGraph::FlowTemplate generated from spec 18.4.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTThingsGraph::FlowTemplate',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTThingsGraph::FlowTemplate->new( %$_ ) };

package Cfn::Resource::AWS::IoTThingsGraph::FlowTemplate {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTThingsGraph::FlowTemplate', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-southeast-2','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTThingsGraph::FlowTemplate::DefinitionDocument',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTThingsGraph::FlowTemplate::DefinitionDocument',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTThingsGraph::FlowTemplate::DefinitionDocument->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTThingsGraph::FlowTemplate::DefinitionDocument {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Language => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Text => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTThingsGraph::FlowTemplate {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CompatibleNamespaceVersion => (isa => 'Cfn::Value::Double', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Definition => (isa => 'Cfn::Resource::Properties::AWS::IoTThingsGraph::FlowTemplate::DefinitionDocument', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTThingsGraph::FlowTemplate - Cfn resource for AWS::IoTThingsGraph::FlowTemplate

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTThingsGraph::FlowTemplate.

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

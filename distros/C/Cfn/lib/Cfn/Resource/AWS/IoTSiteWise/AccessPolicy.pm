# AWS::IoTSiteWise::AccessPolicy generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy->new( %$_ ) };

package Cfn::Resource::AWS::IoTSiteWise::AccessPolicy {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'AccessPolicyArn','AccessPolicyId' ]
  }
  sub supported_regions {
    [ 'ap-southeast-1','ap-southeast-2','cn-north-1','eu-central-1','eu-west-1','us-east-1','us-west-2' ]
  }
}



subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::User',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::User',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::User->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::User {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::Project',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::Project',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::Project->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::Project {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::Portal',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::Portal',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::Portal->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::Portal {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has id => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::IamUser',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::IamUser',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::IamUser->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::IamUser {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::IamRole',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::IamRole',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::IamRole->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::IamRole {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has arn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::AccessPolicyResource',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::AccessPolicyResource',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::AccessPolicyResource->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::AccessPolicyResource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Portal => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::Portal', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Project => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::Project', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::AccessPolicyIdentity',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::AccessPolicyIdentity',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::AccessPolicyIdentity->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::IoTSiteWise::AccessPolicy::AccessPolicyIdentity {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has IamRole => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::IamRole', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IamUser => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::IamUser', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has User => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::User', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has AccessPolicyIdentity => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::AccessPolicyIdentity', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AccessPolicyPermission => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has AccessPolicyResource => (isa => 'Cfn::Resource::Properties::AWS::IoTSiteWise::AccessPolicy::AccessPolicyResource', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::IoTSiteWise::AccessPolicy - Cfn resource for AWS::IoTSiteWise::AccessPolicy

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::IoTSiteWise::AccessPolicy.

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

# AWS::Cognito::UserPoolResourceServer generated from spec 6.3.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer->new( %$_ ) };

package Cfn::Resource::AWS::Cognito::UserPoolResourceServer {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [  ]
  }
  sub supported_regions {
    [ 'ap-northeast-1','ap-northeast-2','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-west-1','eu-west-2','us-east-1','us-east-2','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeType',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       die 'Only accepts functions'; 
     }
   },
  from 'ArrayRef',
   via {
     Cfn::Value::Array->new(Value => [
       map { 
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeType')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeType',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeType',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeTypeValue->new( %$_ );
     }
   };

package Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeTypeValue {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ScopeDescription => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ScopeName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Identifier => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Scopes => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Cognito::UserPoolResourceServer::ResourceServerScopeType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UserPoolId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;

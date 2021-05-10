# AWS::Kendra::DataSource generated from spec 34.0.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::Kendra::DataSource->new( %$_ ) };

package Cfn::Resource::AWS::Kendra::DataSource {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource', is => 'rw', coerce => 1);
  
  sub AttributeList {
    [ 'Arn','Id' ]
  }
  sub supported_regions {
    [ 'ap-southeast-2','eu-west-1','us-east-1','us-west-2' ]
  }
}


subtype 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DateFieldFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceToIndexFieldMappingList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DocumentDataFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DateFieldFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DateFieldFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DateFieldFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DateFieldFormat => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}
subtype 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration',
     as 'Cfn::Value',
  where { $_->isa('Cfn::Value::Array') or $_->isa('Cfn::Value::Function') },
message { "$_ is not a Cfn::Value or a Cfn::Value::Function" };

coerce 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration',
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
         Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration')->coerce($_)
       } @$_
     ]);
   };

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DocumentDataFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardKnowledgeArticleTypeConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardKnowledgeArticleTypeConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardKnowledgeArticleTypeConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardKnowledgeArticleTypeConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DocumentDataFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceKnowledgeArticleStateList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceKnowledgeArticleStateList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceKnowledgeArticleStateList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceKnowledgeArticleStateList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SalesforceKnowledgeArticleStateList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfigurationList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfigurationList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfigurationList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfigurationList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SalesforceCustomKnowledgeArticleTypeConfigurationList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceChatterFeedIncludeFilterTypes',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceChatterFeedIncludeFilterTypes',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceChatterFeedIncludeFilterTypes->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceChatterFeedIncludeFilterTypes {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SalesforceChatterFeedIncludeFilterTypes => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::S3Path',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::S3Path',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::S3Path->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::S3Path {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has Bucket => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Key => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveUserList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveUserList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::OneDriveUserList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::OneDriveUserList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OneDriveUserList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DataSourceInclusionsExclusionsStrings => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfluenceSpaceList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceFieldMappingsList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceFieldMappingsList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceFieldMappingsList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceFieldMappingsList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfluenceSpaceFieldMappingsList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceToIndexFieldMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageFieldMappingsList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageFieldMappingsList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluencePageFieldMappingsList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluencePageFieldMappingsList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfluencePageFieldMappingsList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageToIndexFieldMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogFieldMappingsList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogFieldMappingsList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceBlogFieldMappingsList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceBlogFieldMappingsList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfluenceBlogFieldMappingsList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogToIndexFieldMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentFieldMappingsList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentFieldMappingsList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceAttachmentFieldMappingsList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceAttachmentFieldMappingsList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfluenceAttachmentFieldMappingsList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentToIndexFieldMapping', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ChangeDetectingColumns',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ChangeDetectingColumns',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ChangeDetectingColumns->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ChangeDetectingColumns {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChangeDetectingColumns => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SqlConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SqlConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SqlConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SqlConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has QueryIdentifiersEnclosingOption => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowServiceCatalogConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowServiceCatalogConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ServiceNowServiceCatalogConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ServiceNowServiceCatalogConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CrawlAttachments => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentDataFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludeAttachmentFilePatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeAttachmentFilePatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowKnowledgeArticleConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowKnowledgeArticleConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ServiceNowKnowledgeArticleConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ServiceNowKnowledgeArticleConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CrawlAttachments => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentDataFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludeAttachmentFilePatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeAttachmentFilePatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfigurationList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfigurationList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardObjectConfigurationList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardObjectConfigurationList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SalesforceStandardObjectConfigurationList => (isa => 'ArrayOfCfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectAttachmentConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectAttachmentConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardObjectAttachmentConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceStandardObjectAttachmentConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceKnowledgeArticleConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceKnowledgeArticleConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceKnowledgeArticleConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceKnowledgeArticleConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CustomKnowledgeArticleTypeConfigurations => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceCustomKnowledgeArticleTypeConfigurationList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludedStates => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceKnowledgeArticleStateList', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StandardKnowledgeArticleTypeConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardKnowledgeArticleTypeConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceChatterFeedConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceChatterFeedConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceChatterFeedConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceChatterFeedConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DocumentDataFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeFilterTypes => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceChatterFeedIncludeFilterTypes', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveUsers',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveUsers',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::OneDriveUsers->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::OneDriveUsers {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has OneDriveUserList => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveUserList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OneDriveUserS3Path => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::S3Path', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeUserAccountsList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeUserAccountsList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ExcludeUserAccountsList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ExcludeUserAccountsList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExcludeUserAccountsList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeSharedDrivesList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeSharedDrivesList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ExcludeSharedDrivesList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ExcludeSharedDrivesList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExcludeSharedDrivesList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeMimeTypesList',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeMimeTypesList',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ExcludeMimeTypesList->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ExcludeMimeTypesList {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExcludeMimeTypesList => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DocumentsMetadataConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DocumentsMetadataConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DocumentsMetadataConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DocumentsMetadataConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has S3Prefix => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceVpcConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceVpcConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceVpcConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceVpcConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has SecurityGroupIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SubnetIds => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConnectionConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConnectionConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConnectionConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConnectionConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DatabaseHost => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabasePort => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TableName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceSpaceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CrawlArchivedSpaces => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CrawlPersonalSpaces => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludeSpaces => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeSpaces => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpaceFieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceFieldMappingsList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluencePageConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluencePageConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has PageFieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageFieldMappingsList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceBlogConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceBlogConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has BlogFieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogFieldMappingsList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceAttachmentConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceAttachmentConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttachmentFieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentFieldMappingsList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CrawlAttachments => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ColumnConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ColumnConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ColumnConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ColumnConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChangeDetectingColumns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ChangeDetectingColumns', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentDataColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentIdColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::AclConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::AclConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::AclConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::AclConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AllowedGroupsColumnName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::AccessControlListConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::AccessControlListConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::AccessControlListConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::AccessControlListConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has KeyPath => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SharePointConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SharePointConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SharePointConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SharePointConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has CrawlAttachments => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DisableLocalGroups => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentTitleFieldName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SharePointVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Urls => (isa => 'Cfn::Value::Array|Cfn::Value::Function|Cfn::DynamicValue', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has UseChangeLog => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceVpcConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ServiceNowConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ServiceNowConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has HostUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KnowledgeArticleConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowKnowledgeArticleConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceCatalogConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowServiceCatalogConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNowBuildVersion => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::SalesforceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ChatterFeedConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceChatterFeedConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has CrawlAttachments => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludeAttachmentFilePatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IncludeAttachmentFilePatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has KnowledgeArticleConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceKnowledgeArticleConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServerUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StandardObjectAttachmentConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectAttachmentConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has StandardObjectConfigurations => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceStandardObjectConfigurationList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::S3DataSourceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::S3DataSourceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::S3DataSourceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::S3DataSourceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AccessControlListConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::AccessControlListConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BucketName => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DocumentsMetadataConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DocumentsMetadataConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InclusionPrefixes => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::OneDriveConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::OneDriveConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has DisableLocalGroups => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OneDriveUsers => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveUsers', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has TenantDomain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::GoogleDriveConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::GoogleDriveConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::GoogleDriveConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::GoogleDriveConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ExcludeMimeTypes => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeMimeTypesList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludeSharedDrives => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeSharedDrivesList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExcludeUserAccounts => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ExcludeUserAccountsList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has FieldMappings => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceToIndexFieldMappingList', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DatabaseConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DatabaseConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DatabaseConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DatabaseConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AclConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::AclConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ColumnConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ColumnConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ConnectionConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConnectionConfiguration', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseEngineType => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SqlConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SqlConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceVpcConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::ConfluenceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has AttachmentConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceAttachmentConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has BlogConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceBlogConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ExclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InclusionPatterns => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceInclusionsExclusionsStrings', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PageConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluencePageConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SecretArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServerUrl => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SpaceConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceSpaceConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Version => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has VpcConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceVpcConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

subtype 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceConfiguration',
     as 'Cfn::Value';

coerce 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceConfiguration',
  from 'HashRef',
   via {
     if (my $f = Cfn::TypeLibrary::try_function($_)) {
       return $f
     } else {
       return Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceConfiguration->new( %$_ );
     }
   };

package Cfn::Resource::Properties::Object::AWS::Kendra::DataSource::DataSourceConfiguration {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Value::TypedValue';
  
  has ConfluenceConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ConfluenceConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has DatabaseConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DatabaseConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has GoogleDriveConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::GoogleDriveConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has OneDriveConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::OneDriveConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has S3Configuration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::S3DataSourceConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SalesforceConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SalesforceConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has ServiceNowConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::ServiceNowConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has SharePointConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::SharePointConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

package Cfn::Resource::Properties::AWS::Kendra::DataSource {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has DataSourceConfiguration => (isa => 'Cfn::Resource::Properties::AWS::Kendra::DataSource::DataSourceConfiguration', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Description => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has IndexId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Name => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has RoleArn => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Schedule => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Type => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Cfn::Resource::AWS::Kendra::DataSource - Cfn resource for AWS::Kendra::DataSource

=head1 DESCRIPTION

This module implements a Perl module that represents the CloudFormation object AWS::Kendra::DataSource.

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

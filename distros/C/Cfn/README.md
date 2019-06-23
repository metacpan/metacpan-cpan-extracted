# NAME

Cfn - An object model for CloudFormation documents

# DESCRIPTION

This module helps parse, manipulate, validate and generate CloudFormation documents in JSON
and YAML formats (see stability section for more information on YAML). It creates an object 
model of a CloudFormation template so you can work with the document as a set of objects. 
See [https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html) for
more information.

It provides full blown objects for all know CloudFormation resources. See 
[https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) for a list
of all resource types. These objects live in the `Cfn::Resource` namespace.

The module provides a set of objects representing each piece of CloudFormation. Following is a list of all
object types in the distribution:

# Cfn object

The `Cfn` class is the "root" of a CloudFormation document. It represents an entire CloudFormation document.
It has attributes and methods to access the parts of a CloudFormation document.

    use Cfn;
    my $cfn = Cfn->new;
    $cfn->addResource('MyRes' => ...);
    my $res = $cfn->Resource('MyRes');

## Constructors

### new(Resources => { ... }, Outputs => { }, ...)

The default Moose constructor. You can initialize an empty document like this:

    my $cfn = Cfn->new;
    print $cfn->as_json;

### from\_hashref

CloudFormation documents resemble Perl HashRefs (since they're just JSON datastructures).
This method converts a hashref that represents a CloudFormation document into a Cfn object.

    use Data::Dumper;
    my $cfn = Cfn->from_hashref({ Resources => { R1 => { Type => '...', Properties => { ... } } } });
    print Dumper($cfn->Resource('R1');

### from\_json

This method creates a Cfn object from a JSON string that contains a CloudFormation document in JSON format

### from\_yaml

This method creates a Cfn object from a YAML string that contains a CloudFormation document in YAML format

## Attributes

### json

When serializing to JSON with `as_json`, the encode method on this object is called passing the
documents hashref representation. By default the JSON generated is "ugly", that is, all in one line,
but in canonical form (so a given serialization always has attributes in the same order).

You can specify your own JSON serializer to control how JSON is generated:

    my $cfn = Cfn->new(json => JSON->new->canonical->pretty);
    ...
    print $cfn->as_json;

### yaml

Holds a configured `YAML::PP` parser for use when serializing and deserializing to and from YAML.
Methods `load_string` and `dump_string` are called when needed from convert the object model
to a YAML document, and to convert a YAML document to a datastructure that can later be coerced
into the object model.

### cfn\_options

A `Cfn::Internal::Options` object instance that controls how the as\_hashref method converts the Cfn object
to a datastructure suitable for CloudFormation (only HashRefs, ArrayRefs and Scalars).

You can specify your own options as a hashref with the attributes to `Cfn::Internal::Options` in the
constructor.

    my $cfn = Cfn->new(cfn_options => { custom_resource_rename => 1 });
    ...
    print Dumper($cfn->as_hashref);

See the `Cfn::Internal::Options` object for more details

### AWSTemplateFormatVersion

A string with the value of the AWSTemplateFormatVersion field of the CloudFormation document. Can be undef.

### Description

A string with the value of the Description field of the CloudFormation document. Can be undef.

### Transform

An ArrayRef of Strings with the values of the Transform field of the CloudFormation document. Can be undef.

### Parameters

A HashRef of `Cfn::Parameter` objects. The keys are the name of the Parameters. 
There are a set of convenience methods for accessing this attribute:

    $cfn->Parameter('ParamName') # returns a Cfn::Parameter or undef
    $cfn->ParameterList # returns a list of the parameters in the document
    $cfn->ParameterCount # returns the number of parameters in the document

### Mappings

A HashRef of `Cfn::Mapping` objects. The keys are the name of the Mappings. 
There are a set of convenience methods for accessing this attribute:

    $cfn->Mapping('MappingName') # returns a Cfn::Parameter or undef
    $cfn->MappingList # returns a list of the mappings in the document
    $cfn->MappingCount # returns the number of mappings in the document

### Conditions

A HashRef of `Cfn::Condition` objects. The keys are the name of the Mappings. 
There are a set of convenience methods for accessing this attribute:

    $cfn->Mapping('MappingName') # returns a Cfn::Mapping or undef
    $cfn->MappingList # returns a list of the mappings in the document
    $cfn->MappingCount # returns the number of mappings in the document

### Resources

A HashRef of `Cfn::Resource` objects. The keys are the name of the Resources. 
There are a set of convenience methods for accessing this attribute:

    $cfn->Resource('ResourceName') # returns a Cfn::Resource or undef
    $cfn->ResourceList # returns a list of the resources in the document
    $cfn->ResourceCount # returns the number of resources in the document

### Outputs

A HashRef of `Cfn::Output` objects. The keys are the name of the Outputs. 
There are a set of convenience methods for accessing this attribute:

    $cfn->Output('OutputName') # returns a Cfn::Output or undef
    $cfn->OutputList # returns a list of the outputs in the document
    $cfn->OutputCount # returns the number of outputs in the document

### Metadata

A HashRef of `Cfn::Value` or subclasses of `Cfn::Value`. Represents the 
Metadata key of the CloudFormation document.

There are a set of convenience methods for accessing this attribute:

    $cfn->Metadata('MetadataName') # returns a Cfn::Metadata or undef
    $cfn->MetadataList # returns a list of keys in the document Metadata
    $cfn->MetadataCount # returns the number of keys in the document Metadata

## Methods

### as\_hashref

Returns a Perl HashRef representation of the CloudFormation document. This HashRef
has no objects in it. It is suitable for converting to JSON and passing to CloudFormation

`as_hashref` triggers the serialization process of the document, which scans the whole
object model asking it's components to serialize (calling their `as_hashref`). Objects
can decide how they serialize to a hashref.

When `$cfn-`as\_hashref> is invoked, all the dynamic values in the Cfn object will be 
called with the `$cfn` instance as the first parameter to their subroutine

    $cfn->addResource('R1', 'AWS::IAM::User', Path => Cfn::DynamicValue->new(Value => sub {
      my $cfn = shift;
      return $cfn->ResourceCount + 41
    }));
    $cfn->as_hashref->{ Resources }->{ R1 }->{ Properties }->{ Path } # == 42

### as\_json

Returns a JSON representation of the current instance

### as\_yaml

Returns a YAML representation of the current instance

### path\_to($path)

Given a path in the format `'Resources.R1.Properties.PropName'` it will return the value
stored in PropName of the resource R1. Use `'Resource.R1.Properties.ArrayProp.0'` to access
Arrays.

### resolve\_dynamicvalues

Returns a new `Cfn` object with all `Cfn::DynamicValues` resolved.

### ResourcesOfType($type)

Returns a list of all the Resources of a given type.

    foreach my $iam_user ($cfn->ResourcesOfType('AWS::IAM::User')) {
      ...
    }

### addParameter($name, $object)

Adds an already instanced `Cfn::Parameter` object. Throws an exception if the parameter already exists.

    $cfn->addParameter('P1', Cfn::Parameter->new(Type => 'String', MaxLength => 5));

### addParameter($name, $type, %properties)

Adds a named parameter to the document with the specified type and properties. See `Cfn::Parameter` for available
properties. Throws an exception if the parameter already exists.

    $cfn->addParameter('P1', 'String', MaxLength => 5);

### addMapping($name, $object\_or\_hashref);

Adds a named mapping to the mappings of the document. The second parameter can be a `Cfn::Mapping` object or 
a HashRef that will be coerced to a `Cfn::Mapping` object

    $cfn->addMapping('amis', { 'eu-west-1' => 'ami-12345678' });
    $cfn->addMapping('amis', Cfn::Mapping->new(Map => { 'eu-west-1' => 'ami-12345678' }));
    # $cfn->Mapping('amis') is a Cfn::Mapping object

### addOutput($name, $object)

Adds an already instanced `Cfn::Output` object. Throws an exception if the output already exists.

    $cfn->addParameter('O1', Cfn::Output->new(Value => { Ref => 'R1' });

### addOutput($name, $output\[, %output\_attributes\]);

Adds a named output to the document. See `Cfn::Output` for available
output\_attributes. Throws an exception if the output already exists.

    $cfn->addParameter('O1', { Ref => 'R1' });
    $cfn->addParameter('O1', { Ref => 'R1' }, Description => 'Bla bla');

### addCondition($name, $value)

Adds a named condition to the document. The value parameter should be
a HashRef that expresses a CloudFormation condition. See [https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)

### addResource($name, $object)

Adds a named resource to the document. $object has to be an instance of a 
subclass of `Cfn::Resource`. Throws an exception if a resource already
exists with that name.

### addResource($name, $type, %properties)

Adds a named resource to the document, putting the specified properties in the 
resources properties. See subclasses of `Cfn::Resource` for more details.

    $cfn->addResource('R1', 'AWS::IAM::User');

    $cfn->addResource('R2', 'AWS::IAM::User', Path => '/');
    # $cfn->Resource('R2')->Properties->Path is '/'

Throws an exception if a resource already exists with that name.

### addResource($name, $name, $properties, $resource\_attributes)

Adds a named resource to the document. properties and resource\_attributes
are hashrefs.

    $cfn->addResource('R3', 'AWS::IAM::User', { Path => '/' });
    # $cfn->Resource('R3')->Properties->Path is '/'
    $cfn->addResource('R3', 'AWS::IAM::User', { Path => '/' }, { DependsOn => [ 'R2' ] });
    # $cfn->Resource('R3')->DependsOn->[0] is 'R2'

Throws an exception if a resource already exists with that name.

### addResourceMetadata($name, %metadata);

Adds metadata to the Metadata attribute of a Resource.

    $cfn->addResourceMetadata('R1', MyMetadataKey1 => 'Value');
    # $cfn->Resource('R1')->Metadata->{ MyMedataKey1 } is 'Value'

### addDependsOn($resource\_name, $depends\_on1, $depends\_on2)

    $cfn->addDependsOn('R1', 'R2', 'R3');
    # $cfn->Resource('R1')->DependsOn is [ 'R2', 'R3' ]

### addDeletionPolicy($resource\_name)

    Adds a DeletionPolicy to the resource. L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html>

### addUpdatePolicy($resource\_name)

    Adds an UpdatePolicy to the resource. L<https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html>

# Cfn::Value

Is a base class for the attributes of Cloudformation values. In Cloudformation you can find that in
a resources attributes you can place functions, references, etc.

    "Attribute": "hello"
    "Attribute": { "Ref": "R1" }
    "Attribute": { "Fn::GetAtt": [ "R1", "InstanceId" ] }

All value objects in the Cfn toolkit subclass `Cfn::Value` as a common ancestor. Once the object model is built,
you can find that a

    $cfn->addResource('R1', 'AWS::IAM::User', Path => '/');
    # $cfn->Resource('R1')->Properties->Path is a Cfn::Value::Primitive

    $cfn->addResource('R1', 'AWS::IAM::User', Path => { 'Fn::Join' => [ '/', { Ref => 'Param1' }, '/' ] });
    # $cfn->Resource('R1')->Properties->Path is a Cfn::Value::Function::Join

All `Cfn::Value` subclasses have to implement an `as_hashref` method that returns a HashRef suitable for 
conversion to JSON for CloudFormation. A attributes of objects that hold `Cfn::Value` subclasses should
enable coercion of the attribute so that plain hashrefs can be coerced into the appropiate Cfn::Value objects

Here is a Hierarchy of the different Cfn::Value descendant object:

    Cfn::Value
    |--Cfn::DynamicValue
    |--Cfn::Value::Function
    |  |--Cfn::Value::Function::Condition
    |  |--Cfn::Value::Function::Ref
    |     |--Cfn::Value::Function::PseudoParameter
    |  |--Cfn::Value::Function::GetAtt
    |--Cfn::Value::Array
    |--Cfn::Value::Hash
    |--Cfn::Value::Primitive
    |  |--Cfn::Boolean
    |  |--Cfn::Integer
    |  |--Cfn::Long
    |  |--Cfn::String
    |  |--Cfn::Double
    |  |--Cfn::Timestamp
    |--Cfn::Value::TypedValue
    

## Cfn::DynamicValue

The `Value` attribute of this object is a CodeRef that get's called
when as\_hashref is called.

    $cfn->addResource('R1', 'AWS::IAM::User', Path => Cfn::DynamicValue->new(Value => sub { return 'Hello' });
    $cfn->path_to('Resources.R1.Properties.Path') # isa Cfn::DynamicValue
    $cfn->path_to('Resources.R1.Properties.Path')->as_hashref # eq 'Hello'

When `$cfn-`as\_hashref> is invoked, all the dynamic values in the Cfn object will be 
called with the `$cfn` instance as the first parameter to their subroutine

    $cfn->addResource('R1', 'AWS::IAM::User', Path => Cfn::DynamicValue->new(Value => sub {
      my $cfn = shift;
      return $cfn->ResourceCount + 41
    }));
    $cfn->as_hashref->{ Resources }->{ R1 }->{ Properties }->{ Path } # == 42

## Cfn::Value::Function

All function statements derive from Cfn::Value::Function. 
The name of the function can be found in the `Function` attribute
It's value can be found in the `Value` attribute

## Cfn::Value::Function::Ref

Object of this class represent a CloudFormation Ref. You can find the value 
of the reference in the `Value` attribute. Note that the Value attribute contains
another `Cfn::Value`. It derives from `Cfn::Value::Function`

    $cfn->addResource('R1', 'AWS::IAM::User', Path => { Ref => 'AWS::Region' });
    $cfn->path_to('Resources.R1.Properties.Path') # isa Cfn::Value::Function::PseudoParameter

## Cfn::Value::Function::PseudoParameter

This is a subclass of `Cfn::Value::Function::Ref` used to hold what CloudFormation
calls PseudoParameters.

    $cfn->addResource('R1', 'AWS::IAM::User', Path => { Ref => 'AWS::Region' });
    $cfn->path_to('Resources.R1.Properties.Path') # isa Cfn::Value::Function::PseudoParam

## Cfn::Value::Function::GetAtt

This class represents 'Fn::GetAtt' nodes in the object model. It's a subclass of `Cfn::Value::Function`.

    $cfn->addResource('R1', 'AWS::IAM::User', Path => { 'Fn::GetAtt' => [ 'R1', 'InstanceId' ] });
    $cfn->path_to('Resources.R1.Properties.Path')             # isa Cfn::Value::Function::GetAtt
    $cfn->path_to('Resources.R1.Properties.Path')->LogicalId  # eq 'R1'
    $cfn->path_to('Resources.R1.Properties.Path')->Property   # eq 'InstanceId'

## Cfn::Value::Array

This class represents Arrays in the object model. It's `Value` property is an ArrayRef
of `Cfn::Values` or `Cfn::Resource::Properties`.

There is also a subtype called `Cfn::Value::ArrayOfPrimitives` that restricts the values
in the array to `Cfn::Value::Primitive` types.

## Cfn::Value::Hash

This class represents JSON objects whose keys are not defined beforehand (arbitrary keys).
It's `Value` property is a HashRef of `Cfn::Value`s.

## Cfn::Value::Primitive

This is a base class for any "simple" value (what the CloudFormation spec calls `PrimitiveType`).
This classes `Value` attribute has no type constraint, so it actually accepts anything. This class
is supposed to only be inherited from, specializing the `Value` attribute to a specific type.

## Cfn::Boolean

Used to store and validate CloudFormation `Boolean` values. Has a `stringy` attribute that controls if `as_hashref`
returns a string boolean `"true"` or `"false"` or a literal `true` or `false`, since these two
boolean forms are accepted in CloudFormation.

## Cfn::Integer

Used to store and validate CloudFormation `Integer` values.

## Cfn::Long

Used to store and validate CloudFormation `Long` values.

## Cfn::String

Used to store and validate CloudFormation `String` values.

## Cfn::Double

Used to store and validate CloudFormation `Double` values.

## Cfn::Timestamp

Used to store CloudFormation `Timestamp` values. Only validates that it's a string.

## Cfn::Value::TypedValue

Used as a base class for structured properties of CloudFormation resources. The subclasses
of TypedValue declare Moose attributes that are used to represent and validate that the
properties of a CloudFormation resource are well formed.

# Cfn::Resource

Represents a CloudFormation Resource. All `Cfn::Resource::*` objects (like [Cfn::Resource::AWS::IAM::User](https://metacpan.org/pod/Cfn::Resource::AWS::IAM::User))
use `Cfn::Resource` as a base class.

## Attributes for Cfn::Resource objects

The attributes for Cfn::Resource objects map to the attributes of CloudFormation Resources.

    {
      "Type": "AWS::IAM::User",
      "Properties": { ... },
      "DependsOn": "R2"
      ...
    }

### Type

Holds a string with the type of the resource.

### Properties

Holds a `Cfn::Value::Properties` subclass with the properties of the resource.

### DeletionPolicy

Holds the DeletionPolicy. Validates that the DeletionPolicy is valid

### DependsOn

Can hold either a single string or an arrayref of strings. This is because CloudFormation
supports `DependsOn` in these two forms. Method `DependsOnList` provides a uniform way
of accessing the DependsOn attribute.

### Condition

Can hold a String identifying the Condition property of a resource

### Metadata

Is a `Cfn::Value::Hash` for the resources metadata

### UpdatePolicy

Holds the UpdatePolicy. Validates that the UpdatePolicy is valid

### CreationPolicy

HashRef with the CreationPolicy. Doesn't validate CreationPolicies.

## Methods for Cfn::Resource objects

### AttributeList

Returns an ArrayRef of attributes that can be recalled in CloudFormation via `Fn::GetAtt`.

Can also be retrieved as a class method `Cfn::Resource::...-`AttributeList>

### supported\_regions

Returns an ArrayRef of the AWS regions where the resource can be provisioned.

Can also be retrieved as a class method `Cfn::Resource::...-`supported\_regions>

### DependsOnList

Returns a list of dependencies from the DependsOn attribute (it doesn't matter
if the DependsOn attribute is a String or an ArrayRef of Strings.

    my @deps = $cfn->Resource('R1')->DependsOnList;

### hasAttribute($attribute)

Returns true if the specified attribute is in the `AttributeList`. Note that some resources
(AWS::CloudFormation::CustomResource) can return true for values that are not in AttributeList

### as\_hashref

Like `Cfn::Values`, as\_hashref returns a HashRef representation of the object ready
for transforming to JSON.

# Cfn::Resource::Properties

A base class for the objects that the `Properties` attribute of `Cfn::Resource`s hold.
Subclasses of `Cfn::Resource::Properties` are used to validate and represent the properties
of resources inside the object model. See [Cfn::Resource::Properties::AWS::IAM::User](https://metacpan.org/pod/Cfn::Resource::Properties::AWS::IAM::User) for 
an example.

Each subclass of `Cfn::Resource::Properties` has to have attributes to hold the values of 
the properties of the resource it represents.

# Cfn::Parameter

Represents a Parameter in a CloudFormation document

    my $cfn = Cfn->new;
    $cfn->addParameter('P1', 'String', Default => 5);
    $cfn->Parameter('P1')->Default  # 5
    $cfn->Parameter('P1')->NoEcho   # undef

## Cfn::Parameter Attributes

### Type

A string with the type of parameter. Validates that it's a CloudFormation supported parameter type.

### Default

Holds the default value for the parameter

### NoEcho

Holds the NoEcho property of the parameter

### AllowedValues

An ArrayRef of the allowed values of the parameter

### AllowedPattern

A String holding the pattern that the value of this parameter can take

### MaxLength, MinLength, MaxValue, MinValue

Values holding the MaxLength, MinLength, MaxValue, MinValue of the parameter

### Description

A string description of the parameter

### ConstraintDescription

A string description of the constraint of the parameter

# Cfn::Mapping

This object represents the value of the `Mappings` key in a CloudFormation
document. It has a `Map` attribute to hold the Mappings in the CloudFormation
document.

# Cfn::Output

Represents an output object in a CloudFormation document

## Attributes for Cfn::Output objects

    "Outputs": {
      "Output1": {
        "Value": { "Ref": "Instance" }
      }
    }

### Value

Holds the Value key of an output. Is a `Cfn::Value`

### Description

Holds a String with the descrption of the output

### Condition

Holds a String with the condition of the output

### Export

Holds a HashRef with the export definition of the object

## Methods for Cfn::Output objects

### as\_hashref

Returns a HashRef representation of the output that is convertible to JSON

# STABILITY

YAML support is recent, and due to the still evolving YAML::PP module, may break 
(altough the tests are there to detect that). This distribution will try to keep up 
as hard as it can with latest YAML::PP developments.

# SEE ALSO

[https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html)

This module kind of resembles troposphere (python): [https://github.com/cloudtools/troposphere](https://github.com/cloudtools/troposphere).

# AUTHOR

    Jose Luis Martinez
    CAPSiDE
    jlmartinez@capside.com

# Contributions

Thanks to Sergi Pruneda, Miquel Ruiz, Luis Alberto Gimenez, Eleatzar Colomer, Oriol Soriano, 
Roi Vazquez for years of work on this module.

TINITA for helping make the YAML support possible. First for the YAML::PP module, which is the only
Perl module to support sufficiently modern YAML features, and also for helping me in the use of
YAML::PP.

# BUGS and SOURCE

The source code is located here: [https://github.com/pplu/cfn-perl](https://github.com/pplu/cfn-perl)

Please report bugs to: [https://github.com/pplu/cfn-perl/issues](https://github.com/pplu/cfn-perl/issues)

# COPYRIGHT and LICENSE

Copyright (c) 2013 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

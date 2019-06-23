#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;
use Data::Dumper;
use YAML::PP;
use Cfn;
use Moose::Util::TypeConstraints qw/find_type_constraint/;

#https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html

my $cfn_value_tc = find_type_constraint('Cfn::Value');
my $cfn = Cfn->new;
my $yaml_parser = YAML::PP->new;

sub yaml {
  my ($yaml, $reference_struct, $json) = @_;

  {
    note "--- YAML ---";
    note $yaml;
    my $parsed_yaml = $cfn->yaml->load_string($yaml);
    my $object_from_yaml = $cfn_value_tc->coerce($parsed_yaml);
    note "--- YAML object ---";
    note Dumper($object_from_yaml->as_hashref);
    isa_ok($object_from_yaml, 'Cfn::Value::Function', 'yaml coerced to Cfn::Value is a Cfn::Value::Function subclass');
    is_deeply($object_from_yaml->as_hashref, $reference_struct, 'yaml coerced: the Cfn::Value::Function object is equivalent to the reference struct');
  }

  {
    note "--- JSON ---";
    note $json;
    my $parsed_json = decode_json($json);
    my $object_from_json = $cfn_value_tc->coerce($parsed_json);
    note "--- JSON object---";
    note Dumper($object_from_json->as_hashref);
    isa_ok($object_from_json, 'Cfn::Value::Function', 'json coerced to Cfn::Value is a Cfn::Value::Function subclass');
    is_deeply($object_from_json->as_hashref, $reference_struct, 'yaml coerced: the Cfn::Value::Function object is equivalent to the reference struct');
  }

  note "--- Reference ---";
  note Dumper($reference_struct);

}

# Fn::Base64
yaml("Fn::Base64: AWS CloudFormation\n", { 'Fn::Base64' => 'AWS CloudFormation' }, '{ "Fn::Base64" : "AWS CloudFormation" }');
yaml('!Base64 valueToEncode', { 'Fn::Base64' => 'valueToEncode' }, '{ "Fn::Base64": "valueToEncode" }');

yaml(<<EOY, { "Fn::Cidr" => [ 'ipBlock', 'count', 'cidrBits' ] }, '{ "Fn::Cidr" : [ "ipBlock", "count", "cidrBits" ] }');
Fn::Cidr: 
  - ipBlock 
  - count
  - cidrBits
EOY

yaml('!Cidr [ ipBlock, count, cidrBits ]', { "Fn::Cidr" => [ 'ipBlock', 'count', 'cidrBits' ] }, '{ "Fn::Cidr" : ["ipBlock", "count", "cidrBits" ]}');
yaml('!Cidr [ "192.168.0.0/24", 6, 5 ]', { "Fn::Cidr" => [ '192.168.0.0/24', 6, 5 ] }, '{ "Fn::Cidr" : [ "192.168.0.0/24", "6", "5"] }');

yaml(<<EOY, { "Fn::GetAtt" => [ 'logicalNameOfResource', 'attributeName' ] }, '{ "Fn::GetAtt" : [ "logicalNameOfResource", "attributeName" ] }');
Fn::GetAtt: [ logicalNameOfResource, attributeName ]
EOY

yaml('Ref: logicalName', { Ref => 'logicalName' }, '{ "Ref" : "logicalName" }');
yaml('!Ref logicalName', { Ref => 'logicalName' }, '{ "Ref" : "logicalName" }');

yaml('Fn::GetAtt: [ logicalNameOfResource, attributeName ]', { 'Fn::GetAtt' => [ 'logicalNameOfResource', 'attributeName' ] }, '{ "Fn::GetAtt" : [ "logicalNameOfResource", "attributeName" ] }');
yaml('!GetAtt logicalNameOfResource.attributeName', { 'Fn::GetAtt' => [ 'logicalNameOfResource', 'attributeName' ] }, '{ "Fn::GetAtt" : [ "logicalNameOfResource", "attributeName" ] }');

yaml('Fn::FindInMap: [ MapName, TopLevelKey, SecondLevelKey ]', { "Fn::FindInMap" => [ "MapName", "TopLevelKey", "SecondLevelKey"] }, '{ "Fn::FindInMap" : [ "MapName", "TopLevelKey", "SecondLevelKey"] }');

yaml('Fn::GetAZs: region', { "Fn::GetAZs" => "region" }, '{ "Fn::GetAZs" : "region" }');
yaml('!GetAZs region', { "Fn::GetAZs" => "region" }, '{ "Fn::GetAZs" : "region" }');

yaml('Fn::ImportValue: sharedValueToImport', { "Fn::ImportValue" => 'sharedValueToImport' }, '{ "Fn::ImportValue" : "sharedValueToImport" }');
yaml('!ImportValue sharedValueToImport', { "Fn::ImportValue" => 'sharedValueToImport' }, '{ "Fn::ImportValue" : "sharedValueToImport" }');

{
  my $json = <<EOJ;
{
  "Fn::Join": [
    "", [
      "arn:",
      {
        "Ref": "Partition"
      },
      ":s3:::elasticbeanstalk-*-",
      {
        "Ref": "AWS::AccountId"
      }
    ]
  ]
}
EOJ

my $yaml = <<EOY;
Fn::Join:
  - ''
  - - 'arn:'
    - Ref: Partition
    - ':s3:::elasticbeanstalk-*-'
    - Ref: 'AWS::AccountId'
EOY

  yaml($yaml, { "Fn::Join" => [ "", [ "arn:", { Ref => "Partition" }, ":s3:::elasticbeanstalk-*-", { Ref => "AWS::AccountId" } ] ] }, $json);
}

yaml(
  '!Join [ ":", [ a, b, c ] ]',
  { 'Fn::Join', [ ':', [ 'a', 'b', 'c' ] ] },
  '{ "Fn::Join" : [ ":", [ "a", "b", "c" ] ] }',
);

{
  my $json = <<EOJ;
{
  "Fn::Join": [
    "", [
      "arn:",
      {
        "Ref": "Partition"
      },
      ":s3:::elasticbeanstalk-*-",
      {
        "Ref": "AWS::AccountId"
      }
    ]
  ]
}
EOJ

my $yaml = <<EOY;
!Join
  - ''
  - - 'arn:'
    - !Ref Partition
    - ':s3:::elasticbeanstalk-*-'
    - !Ref 'AWS::AccountId'
EOY

  yaml($yaml, { "Fn::Join" => [ "", [ "arn:", { Ref => "Partition" }, ":s3:::elasticbeanstalk-*-", { Ref => "AWS::AccountId" } ] ] }, $json);
}


yaml(
  '!Select [ "1", [ "apples", "grapes", "oranges", "mangoes" ] ]',
  { "Fn::Select" => [ 1, [ "apples", "grapes", "oranges", "mangoes" ] ] },
  '{ "Fn::Select" : [ "1", [ "apples", "grapes", "oranges", "mangoes" ] ] }'
);

yaml(
  'Fn::FindInMap: [ MapName, TopLevelKey, SecondLevelKey ]',
  { 'Fn::FindInMap', [ 'MapName', 'TopLevelKey', 'SecondLevelKey' ] },
  '{ "Fn::FindInMap" : [ "MapName", "TopLevelKey", "SecondLevelKey"] }'
);

yaml(
  '!FindInMap [ MapName, TopLevelKey, SecondLevelKey ]',
  { 'Fn::FindInMap', [ 'MapName', 'TopLevelKey', 'SecondLevelKey' ] },
  '{ "Fn::FindInMap" : [ "MapName", "TopLevelKey", "SecondLevelKey"] }'
);

{
my $yaml = <<EOY;
!FindInMap
 - RegionMap
 - !Ref 'AWS::Region'
 - HVM64
EOY

  yaml($yaml,
       { "Fn::FindInMap" => [ "RegionMap", { 'Ref' => 'AWS::Region' }, 'HVM64' ] },
       '{ "Fn::FindInMap" : [ "RegionMap", { "Ref" : "AWS::Region" }, "HVM64" ] }'
      );
}

yaml(
  'Fn::Split: [ delimiter, source string ]',
  { 'Fn::Split' => [ 'delimiter', 'source string' ] },
  '{ "Fn::Split" : [ "delimiter", "source string" ] }'
);

yaml(
  '!Split [ delimiter, source string ]',
  { 'Fn::Split' => [ 'delimiter', 'source string' ] },
  '{ "Fn::Split" : [ "delimiter", "source string" ] }'
);

yaml(
  '!Split [ "|" , "a|b|c" ]',
  { 'Fn::Split' => [ '|', 'a|b|c' ] },
  '{ "Fn::Split" : [ "|" , "a|b|c" ] }'
);

yaml(
  '!Select [2, !Split [",", !ImportValue AccountSubnetIDs]]',
  { "Fn::Select" => [ 2, { "Fn::Split" => [ ',', { 'Fn::ImportValue' => 'AccountSubnetIDs' } ] } ] },
  '{ "Fn::Select" : [ "2", { "Fn::Split": [",", {"Fn::ImportValue": "AccountSubnetIDs"}]}] }'
);

{
  my $yaml = <<EOY;
Fn::Sub:
  - String
  - { Var1Name: Var1Value, Var2Name: Var2Value }
EOY

  yaml(
    $yaml,
    { 'Fn::Sub' => [ 'String', { Var1Name => 'Var1Value', Var2Name => 'Var2Value' } ] },
    '{ "Fn::Sub" : [ "String", { "Var1Name": "Var1Value", "Var2Name": "Var2Value" } ] }'
  );
}
 
{
  my $yaml = <<EOY;
!Sub
  - String
  - { Var1Name: Var1Value, Var2Name: Var2Value }
EOY

  yaml(
    $yaml,
    { 'Fn::Sub' => [ 'String', { Var1Name => 'Var1Value', Var2Name => 'Var2Value' } ] },
    '{ "Fn::Sub" : [ "String", { "Var1Name": "Var1Value", "Var2Name": "Var2Value" } ] }'
  );
}

yaml(
  '!Sub String',
  { 'Fn::Sub' => 'String' },
  '{ "Fn::Sub": "String" }',
);

yaml(
  'Fn::Sub: String',
  { 'Fn::Sub' => 'String' },
  '{ "Fn::Sub": "String" }',
);

{
  my $yaml = <<EOY;
!Sub
  - www.\${Domain}
  - { Domain: !Ref RootDomainName }
EOY

  yaml(
    $yaml,
    { 'Fn::Sub' => [ 'www.${Domain}', { Domain => { Ref => 'RootDomainName' } } ] },
    '{ "Fn::Sub": [ "www.${Domain}", { "Domain": {"Ref" : "RootDomainName" }} ]}'
  );
}

yaml(
  q|!Sub 'arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:vpc/${vpc}'|,
  { "Fn::Sub" => 'arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:vpc/${vpc}' },
  '{ "Fn::Sub": "arn:aws:ec2:${AWS::Region}:${AWS::AccountId}:vpc/${vpc}" }'
);

{
  my $yaml = <<EOY;
Fn::Transform:
  Name : macro name
  Parameters :
          Key : value
EOY

  yaml(
    $yaml,
    { 'Fn::Transform' => { "Name" => "macro name", "Parameters" => { Key => 'value' } } },
    '{ "Fn::Transform" : { "Name" : "macro name", "Parameters" : {"Key" : "value" } } }'
  );
}

yaml(
  '!Transform { "Name" : macro name, "Parameters" : {Key : value } }',
  { 'Fn::Transform' => { "Name" => "macro name", "Parameters" => { Key => 'value' } } },
  '{ "Fn::Transform" : { "Name" : "macro name", "Parameters" : {"Key" : "value" } } }'
);

{
  my $json = <<EOJ;
{
   "Fn::And": [
      {"Fn::Equals": ["sg-mysggroup", {"Ref": "ASecurityGroup"}]},
      {"Condition": "SomeOtherCondition"}
   ]
}
EOJ

my $yaml = <<EOY;
!And
  - !Equals ["sg-mysggroup", !Ref "ASecurityGroup"]
  - !Condition SomeOtherCondition
EOY

  yaml($yaml, {
    "Fn::And" => [
      {"Fn::Equals" => ["sg-mysggroup", {"Ref" => "ASecurityGroup"}]},
      {"Condition" => "SomeOtherCondition"}
   ]
  }, $json);
}

yaml(
  '!Equals [!Ref EnvironmentType, prod]',
  { "Fn::Equals" => [ { Ref => 'EnvironmentType' }, 'prod' ] },
  '{ "Fn::Equals": [ {"Ref": "EnvironmentType"}, "prod" ] }'
);

yaml(
  '!If [CreateNewSecurityGroup, !Ref NewSecurityGroup, !Ref ExistingSecurityGroup]',
  { 'Fn::If' => [ "CreateNewSecurityGroup" => { Ref => "NewSecurityGroup" }, { Ref => 'ExistingSecurityGroup' } ] },
  '{ "Fn::If" : [ "CreateNewSecurityGroup", {"Ref" : "NewSecurityGroup"}, {"Ref" : "ExistingSecurityGroup"} ] }'
);

yaml('!If [CreateLargeSize, 100, 10]', { 'Fn::If' => [ 'CreateLargeSize', 100, 10 ] }, '{ "Fn::If" : [ "CreateLargeSize", "100", "10" ]}');

{
  my $json = <<EOJ;
{
   "Fn::Not" : [{
      "Fn::Equals" : [
         {"Ref" : "EnvironmentType"},
         "prod"
      ]
   }]
}
EOJ

my $yaml = <<EOY;
!Not [!Equals [!Ref EnvironmentType, prod]]
EOY

  yaml($yaml, {
    'Fn::Not' => [ { 'Fn::Equals' => [ { Ref => 'EnvironmentType' }, 'prod' ] } ]
  }, $json);
}

{
  my $json = <<EOJ;
{
   "Fn::Or": [
      {"Fn::Equals": [ "sg-mysggroup", {"Ref":"ASecurityGroup"} ] },
      {"Condition": "SomeOtherCondition"}
   ]
}
EOJ

my $yaml = <<EOY;
!Or [!Equals [sg-mysggroup, !Ref ASecurityGroup], !Condition SomeOtherCondition]
EOY

  yaml($yaml, {
    'Fn::Or' => [
      {"Fn::Equals" => [ "sg-mysggroup", { Ref => 'ASecurityGroup' } ] },
      {"Condition" => "SomeOtherCondition"}
    ]
  }, $json);
}

yaml(<<EOY, { "Fn::GetAtt" => [ 'ElasticLoadBalancer', 'SourceSecurityGroup.OwnerAlias' ] }, '{ "Fn::GetAtt" : [ "ElasticLoadBalancer", "SourceSecurityGroup.OwnerAlias" ] }');
!GetAtt [ElasticLoadBalancer, SourceSecurityGroup.OwnerAlias]
EOY

{
  throws_ok(sub {
    my $parsed_yaml = $cfn->yaml->load_string('!UnsupportedScalar XxX');
  }, qr/Unsupported scalar tag '!UnsupportedScalar'/);
}

{
  throws_ok(sub {
    my $parsed_yaml = $cfn->yaml->load_string('!UnsupportedSequence [ XxX, YyY ]');
  }, qr/Unsupported sequence tag '!UnsupportedSequence'/);
}

{
  throws_ok(sub {
    my $parsed_yaml = $cfn->yaml->load_string('!UnsupportedMapping { "Key": Value }');
  }, qr/Unsupported mapping tag '!UnsupportedMapping'/);
}


done_testing;

__END__

These are not valid CloudFormation
"!Base64 !Sub string"
"!Base64 !Ref logical_ID"

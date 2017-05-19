#!/usr/bin/env perl

use Test::More;

package TestClass {
  use Moose;
  extends 'CCfn';
  use CCfnX::Shortcuts;
  use CCfnX::CommonArgs;

  has params => (is => 'ro', isa => 'CCfnX::CommonArgs', default => sub { CCfnX::CommonArgs->new(
    region => 'eu-west-1',
    account => 'devel-capside',
    name => 'NAME'
  ); } );

  resource StaticPolicy => 'AWS::S3::BucketPolicy', {
    Bucket => { Ref => 'AppBucket' },
    PolicyDocument => {
      Id => 'StaticPolicy',
      Statement => [ {
        Sid => 'PublicAccessToStaticContent',
        Effect => 'Allow',
        Principal => { "AWS" => "*" },
        Action => [ "s3:GetObject" ],
        Resource => [ 
          CfString("arn:aws:s3:::#-#AppBucket#-#/static/*"), 
          CfString("arn:aws:s3:::#-#AppBucket->Attribute#-#/static/*"), 
        ]
      } ],
    }
  };

}

my $obj = TestClass->new;
my $struct = $obj->as_hashref;

#p $struct;

is_deeply($struct->{Resources}{StaticPolicy}{Properties}{PolicyDocument}{Statement}[0]{Resource}[0],
          { "Fn::Join" => [ "", [ "arn:aws:s3:::", { Ref => 'AppBucket' }, "/static/*" ] ] },
          'Got the correct structure for the CfString shortcut for Ref');

is_deeply($struct->{Resources}{StaticPolicy}{Properties}{PolicyDocument}{Statement}[0]{Resource}[1],
          { "Fn::Join" => [ "", [ "arn:aws:s3:::", { 'Fn::GetAtt' => [ 'AppBucket', 'Attribute' ] }, "/static/*" ] ] },
          'Got the correct structure for the CfString shortcut for GetAtt');



done_testing;

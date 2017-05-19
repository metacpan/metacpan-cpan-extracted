#!/usr/bin/env perl

use Test::More;
use CCfn;
use Test::Exception;

#
# This test is designed to verify that the shortcut "resource" assigns extra information (the
# fourth parameter) correctly to resources
#

package Params {
  use Moose;
  use MooseX::Getopt;
  with 'MooseX::Getopt';
}

dies_ok {
  package TestClass {
    use Moose;
    extends 'CCfn';
    use CCfnX::Shortcuts;
  
    has params => (is => 'ro', isa => 'Params', default => sub { Params->new_with_options });
  
    resource User => 'AWS::IAM::User', {
      Path => '/',
    };
  
    resource User => 'AWS::IAM::User', {
      Path => '/2/',
    };
  } 
} 'Repeated resource should not be permitted';

done_testing; 

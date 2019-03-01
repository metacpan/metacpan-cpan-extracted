#!/usr/bin/env perl

use Test::More;
use Test::Exception;

use FindBin;
use Cfn;
use File::Slurp;
use JSON;

use strict;

my @tests = (
  { Resources => {
      R1 => { Type => 'AWS::IAM::User' } }
  },
  { Parameters => {
      P1 => { 'Type' => 'String' }
    },
    Resources => {
      R2 => { Type => 'AWS::IAM::User' },
      R3 => { Type => 'AWS::IAM::User' },
    }
  },
  { Resources => { R1 => { Type => 'AWS::IAM::User' } },
    Outputs => {
       output1 => { Value => { Ref => "ElbRecordSet" } },
    },
  },
  { Resources => { R1 => { Type => 'AWS::IAM::User' } },
    Mappings => {
      Mapping01 => {
        Key01 => {
          Value => "Value01"
        },
        Key02 => {
          Value => "Value02"
        },
      }
    }
  },
  { Resources => { R1 => { Type => 'AWS::IAM::User' } },
    Outputs => {
       output1 => { Value => { Ref => "ElbRecordSet" } },
    },
  },
);

my $i = 0;
foreach my $test (@tests) {
  my $title = "index $i";
  my $cfn;
  lives_ok { $cfn = Cfn->from_hashref($test); 
             test_ds_vs_parsed($test, $cfn, $title);
  } "Construct from_hash $title";

  $i++;
}


my $t_dir = "$FindBin::Bin/cfn_json/";
use IO::Dir;
my $d = IO::Dir->new($t_dir);

while (my $file = $d->read){
  next if ($file =~ m/^\./);
  next if (not $file =~ m/\.json$/);
  my $content = read_file("$t_dir/$file");
  my $cfn;
  note "for file $t_dir/$file";
  eval { $cfn = Cfn->from_json($content) };
  if ($@){
    if ($@ =~ m/you may need to install the .* module/){
      TODO:{
        local $TODO = 'The module for something in this JSON is not developed yet';
        fail("JSON file $t_dir/$file didn't parse");
      };
    } else {
      diag($@);
      fail("JSON file $t_dir/$file didn't parse");
    }
  } else {
    pass("JSON file $t_dir/$file parsed without problems");
    my $hash = from_json($content);
    test_ds_vs_parsed($hash, $cfn, $file);
  }
}
$d->close;

done_testing;

sub test_ds_vs_parsed {
  my ($datastruct, $parsed, $test_name) = @_;

  cmp_ok($parsed->ResourceCount,  '==', scalar(keys %{ $datastruct->{ Resources  } }), "Got the same number of resources for $test_name");
  cmp_ok($parsed->ParameterCount, '==', scalar(keys %{ $datastruct->{ Parameters } }), "Got the same number of parameter for $test_name");
  cmp_ok($parsed->OutputCount,    '==', scalar(keys %{ $datastruct->{ Outputs    } }), "Got the same number of ouputs for $test_name");
  cmp_ok($parsed->MappingCount,   '==', scalar(keys %{ $datastruct->{ Mappings   } }), "Got the same number of mappings for $test_name");
  cmp_ok($parsed->ConditionCount, '==', scalar(keys %{ $datastruct->{ Conditions } }), "Got the same number of conditions for $test_name");
  cmp_ok($parsed->MetadataCount,  '==', scalar(keys %{ $datastruct->{ Metadata   } }), "Got the same number of metadata entries for $test_name");
}


#!/usr/bin/env perl

use Test::More;

use JSON;
use File::Slurp;

use Moose::Util::TypeConstraints;
use Cfn;

my @files = @ARGV;
@files = glob('t/001_parse/*.res') if (not @files);

foreach my $file (@files){
  my $struct = eval { from_json(read_file($file)) };
  if ($@) { fail("Error in $file: $@") }

  my $tname = "Resource from $file via generic hashref";
  eval {
    my $cfn = Cfn->new;
    $cfn->addResource('Resource', $struct->{Type}, %{ $struct->{Properties} });

    # since addResource cannot add things like Version, Depends, etc... (it can only
    # add Type and Properties, we construct a new hash to compare with
    my $compare_with = { Type => $struct->{Type}, Properties => $struct->{Properties } };
    is_deeply($cfn->as_hashref->{Resources}->{Resource}, $compare_with, $tname);
  };
  if ($@) {
    fail($tname);
    diag($@);
  }

  $tname = "Resource from $file via object";
  eval {
    my $cfn2 = Cfn->new;
    my $res = Moose::Util::TypeConstraints::find_type_constraint('Cfn::Resource')->coerce($struct);
    $cfn2->addResource('Resource', $res);
    is_deeply($cfn2->as_hashref->{Resources}->{Resource}, $struct, $tname);
  };
  if ($@) {
    fail($tname);
    diag($@);
  }


}

done_testing;

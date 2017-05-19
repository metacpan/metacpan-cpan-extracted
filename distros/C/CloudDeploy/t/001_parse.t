#!/usr/bin/env perl

use Test::More;

use JSON;
use File::Slurp;

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
    is_deeply($cfn->Resources->{Resource}->as_hashref, $struct, $tname);
  };
  if ($@) {
    fail($tname);
    diag($@);
  }

  my $tname = "Resource from $file via object";
  eval {
    my $cfn2 = Cfn->new;
    my $class = "Cfn::Resource::$struct->{Type}";
    my $res = $class->new( Properties => $struct->{Properties} );
    $cfn2->addResource('Resource', $res);
    is_deeply($cfn2->Resources->{Resource}->as_hashref, $struct, $tname);
  };
  if ($@) {
    fail($tname);
    diag($@);
  }


}

done_testing;

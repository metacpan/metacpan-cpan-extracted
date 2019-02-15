#!/usr/bin/env perl

use Cfn;
use Test::More;
use Data::Printer;

my $obj = Cfn->new;

$obj->addOutput('output1', { Ref => 'XXX' });
$obj->addOutput('output2', { 'Fn::GetAtt' => [ 'XXX', 'InstanceID' ] });

my $struct = $obj->as_hashref;

is_deeply($struct->{Outputs}->{output1}->{Value},
          { Ref => 'XXX' },
          'Got the correct structure for the output');

is_deeply($struct->{Outputs}->{output2}->{Value},
          { 'Fn::GetAtt' => [ 'XXX', 'InstanceID' ] },
          'Got the correct structure for the output');

done_testing;

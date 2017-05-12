#!/usr/bin/env perl
# Convert to xpdl2.1
use warnings;
use strict;

use lib 'lib';
use Test::More;
#use Log::Report mode => 3;   # enable debugging

use BPM::XPDL;
use BPM::XPDL::Util ':xpdl21';
use XML::Compile::Util   'pack_type';
use XML::Compile::Tester 'compare_xml';

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

my $example_dir = 'examples/xpdl-2.0-sample';
if(-d $example_dir) { ; }
elsif(-d "../$example_dir") { $example_dir = "../$example_dir" }
else { plan skip_all => 'Cannot find the examples to test' }

plan tests => 3;

my $xml = <<_MESSAGE;
<?xml version="1.0" encoding="UTF-8"?>
<Package
    xmlns="http://www.wfmc.org/2004/XPDL2.0alpha"
    xmlns:xpdl10="http://www.wfmc.org/2002/XPDL1.0"
    Id="1" Name="test conversion">
  <PackageHeader>
    <XPDLVersion>2.0</XPDLVersion>
    <Vendor>MARKOV Solutions</Vendor>
    <Created>27/04/2000 16:32:20 PM</Created>
  </PackageHeader>
  <WorkflowProcesses>
    <WorkflowProcess Id="wpid" Name="test process">
      <ProcessHeader/>
      <ActivitySets>
        <ActivitySet Id="set1">
          <Transitions>
            <Transition Id="t1" From="me1" To="you1">
              <Condition xmlns="http://www.wfmc.org/2002/XPDL1.0">
                <xpdl20:Expression xmlns:xpdl20="http://www.wfmc.org/2004/XPDL2.0alpha">expr 1</xpdl20:Expression>
              </Condition>
            </Transition>
          </Transitions>
        </ActivitySet>
      </ActivitySets>
      <Activities>
        <Activity Id="Act2" Name="Activity2">
          <Implementation>
            <xpdl10:Tool Id="tool1"/>
          </Implementation>
        </Activity>
      </Activities>
      <Transitions>
        <Transition Id="t2" From="me2" To="you2">
          <Condition xmlns="http://www.wfmc.org/2002/XPDL1.0">
             <xpdl20:Expression xmlns:xpdl20="http://www.wfmc.org/2004/XPDL2.0alpha">expr2</xpdl20:Expression>
           </Condition>
        </Transition>
      </Transitions>
    </WorkflowProcess>
  </WorkflowProcesses>
</Package>
_MESSAGE

my $xpdl = BPM::XPDL->new(version => '2.1');
my ($type, $data) = $xpdl->from($xml);
ok(defined $data, 'converted to 2.1');
is($type, pack_type(NS_XPDL_21, 'Package'));
#warn Dumper $data;

my $xml21 = $xpdl->create($data)->toString(1);
#warn $xml21;

#   xmlns:xpdl20="http://www.wfmc.org/2004/XPDL2.0alpha"
compare_xml($xml21, <<'_CONVERTED');
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://www.wfmc.org/2008/XPDL2.1"
   xmlns:xpdl10="http://www.wfmc.org/2002/XPDL1.0"
   Id="1" Name="test conversion">
  <PackageHeader>
    <XPDLVersion>2.1</XPDLVersion>
    <Vendor>MARKOV Solutions</Vendor>
    <Created>27/04/2000 16:32:20 PM</Created>
  </PackageHeader>
  <WorkflowProcesses>
    <WorkflowProcess Id="wpid" Name="test process" AccessLevel="PUBLIC" ProcessType="None" Status="None" SuppressJoinFailure="0" EnableInstanceCompensation="0" AdHoc="0" AdHocOrdering="Parallel">
      <ProcessHeader/>
      <ActivitySets>
        <ActivitySet Id="set1" AdHoc="0" AdHocOrdering="Parallel">
          <Transitions>
            <Transition Id="t1" From="me1" To="you1" Quantity="1">
              <Condition xmlns="http://www.wfmc.org/2002/XPDL1.0">
                <xpdl21:Expression xmlns:xpdl21="http://www.wfmc.org/2008/XPDL2.1" xmlns:xpdl20="http://www.wfmc.org/2004/XPDL2.0alpha">expr 1</xpdl21:Expression>
              </Condition>
            </Transition>
          </Transitions>
        </ActivitySet>
      </ActivitySets>
      <Activities>
        <Activity Id="Act2" Name="Activity2" Status="None" StartQuantity="1" IsATransaction="0">
          <Implementation>
            <Task>
              <TaskApplication Id="tool1"/>
            </Task>
          </Implementation>
        </Activity>
      </Activities>
      <Transitions>
        <Transition Id="t2" From="me2" To="you2" Quantity="1">
          <Condition xmlns="http://www.wfmc.org/2002/XPDL1.0">
             <xpdl21:Expression xmlns:xpdl21="http://www.wfmc.org/2008/XPDL2.1" xmlns:xpdl20="http://www.wfmc.org/2004/XPDL2.0alpha">expr2</xpdl21:Expression>
           </Condition>
        </Transition>
      </Transitions>
    </WorkflowProcess>
  </WorkflowProcesses>
</Package>
_CONVERTED

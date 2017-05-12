#!/usr/bin/env perl
# Convert to xpdl2.0
use warnings;
use strict;

use lib 'lib';
use Test::More;
#use Log::Report mode => 3;   # enable debugging

use BPM::XPDL;
use BPM::XPDL::Util ':xpdl20';
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
<Package Id="1" Name="test conversion"
   xmlns="http://www.wfmc.org/2002/XPDL1.0" >
  <PackageHeader>
    <XPDLVersion>1.0</XPDLVersion>
    <Vendor>MARKOV Solutions</Vendor>
    <Created>27/04/2000 16:32:20 PM</Created>
  </PackageHeader>

  <WorkflowProcesses>
    <WorkflowProcess Id="wpid" Name="test process">
      <ProcessHeader />
      <FormalParameters>
        <FormalParameter Id="p1" Index="42">
          <DataType><BasicType Type="INTEGER"/></DataType>
        </FormalParameter>
      </FormalParameters>
      <Applications>
        <Application Id="appl1">
           <FormalParameters>
             <FormalParameter Id="p2" Index="43">
               <DataType><BasicType Type="INTEGER"/></DataType>
             </FormalParameter>
           </FormalParameters>
        </Application>
      </Applications>
      <ActivitySets>
        <ActivitySet Id="set1">
          <Transitions>
            <Transition Id="t1" From="me1" To="you1">
              <Condition>
                <Xpression>expr 1</Xpression>
              </Condition>
            </Transition>
          </Transitions>
        </ActivitySet>
      </ActivitySets>
      <Activities>
        <Activity Id="Act1" Name="Activity1">
          <BlockActivity BlockId="bid1" />
          <StartMode>
            <Automatic />
          </StartMode>
          <Deadline>
            <DeadlineCondition>3 weeks</DeadlineCondition>
            <ExceptionName>Help</ExceptionName>
          </Deadline>
        </Activity>
        <Activity Id="Act2" Name="Activity2">
          <Implementation>
             <Tool Id="tool1" Type="PROCEDURE" />
          </Implementation>
        </Activity>
      </Activities>
      <Transitions>
         <Transition Id="t2" From="me2" To="you2">
           <Condition>
             <Xpression>expr2</Xpression>
           </Condition>
         </Transition>
      </Transitions>
    </WorkflowProcess>
  </WorkflowProcesses>
</Package>
_MESSAGE

my $xpdl = BPM::XPDL->new(version => '2.0');
my ($type, $data) = $xpdl->from($xml);
ok(defined $data, 'converted to 2.0');
is($type, pack_type(NS_XPDL_20, 'Package'));
#warn Dumper $data;

my $xml20 = $xpdl->create($data)->toString(1);
#warn $xml20;

compare_xml($xml20, <<'_CONVERTED');
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
      <FormalParameters>
        <FormalParameter Id="p1" Mode="IN">
          <DataType>
            <BasicType Type="INTEGER"/>
          </DataType>
        </FormalParameter>
      </FormalParameters>
      <Applications>
        <Application Id="appl1">
          <FormalParameters>
            <FormalParameter Id="p2" Mode="IN">
              <DataType>
                <BasicType Type="INTEGER"/>
              </DataType>
            </FormalParameter>
          </FormalParameters>
        </Application>
      </Applications>
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
        <Activity Id="Act1" Name="Activity1" StartMode="Automatic">
          <BlockActivity ActivitySetId="bid1"/>
          <Deadline>
            <DeadlineDuration>3 weeks</DeadlineDuration>
            <ExceptionName>Help</ExceptionName>
          </Deadline>
        </Activity>
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
_CONVERTED

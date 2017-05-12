#!/usr/bin/env perl
# First example XPDL script from Interapy, but now create it.
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 3;
# use Log::Report mode => 3;   # enable debugging

use BPM::XPDL;
use XML::Compile::Tester 'compare_xml';

my $data = {    # output from t/10minimal.t
  Id => 'newpkg1',
  WorkflowProcesses => {
    WorkflowProcess => [
      {
        Id => 'OrderPizza',
        Transitions => {
          Transition => [
            {
              Id => 'trans1.0',
              To => 'WaitForDelivery',
              From => 'PlaceOrder'
            },
            {
              Id => 'trans1.1',
              To => 'PayPizzaGuy',
              From => 'WaitForDelivery'
            }
          ]
        },
        ProcessHeader => {
          Created => '2009-02-14 21:06:08'
        },
        Name => 'Order Pizza',
        Activities => {
          Activity => [
            {
              Id => 'PlaceOrder',
              Implementation => {
                No => {}
              }
            },
            {
              Id => 'WaitForDelivery',
              Implementation => {
                No => {}
              }
            },
            {
              Id => 'PayPizzaGuy',
              Implementation => {
                No => {}
              }
            }
          ]
        }
      }
    ]
  },
  PackageHeader => {
    Created => '2009-02-14 21:06:01',
    Vendor => 'Together',
    XPDLVersion => '1.0'
  },
  Name => 'newpkg1'
};

my $xpdl = BPM::XPDL->new(version => '1.0');
isa_ok($xpdl, 'BPM::XPDL');

my $xml = $xpdl->create($data);
isa_ok($xml, 'XML::LibXML::Document');

compare_xml($xml->toString(1), <<'_DUMP');
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://www.wfmc.org/2002/XPDL1.0" Id="newpkg1" Name="newpkg1">
  <PackageHeader>
    <XPDLVersion>1.0</XPDLVersion>
    <Vendor>Together</Vendor>
    <Created>2009-02-14 21:06:01</Created>
  </PackageHeader>
  <WorkflowProcesses>
    <WorkflowProcess Id="OrderPizza" Name="Order Pizza">
      <ProcessHeader>
        <Created>2009-02-14 21:06:08</Created>
      </ProcessHeader>
      <Activities>
        <Activity Id="PlaceOrder">
          <Implementation>
            <No/>
          </Implementation>
        </Activity>
        <Activity Id="WaitForDelivery">
          <Implementation>
            <No/>
          </Implementation>
        </Activity>
        <Activity Id="PayPizzaGuy">
          <Implementation>
            <No/>
          </Implementation>
        </Activity>
      </Activities>
      <Transitions>
        <Transition Id="trans1.0" From="PlaceOrder" To="WaitForDelivery"/>
        <Transition Id="trans1.1" From="WaitForDelivery" To="PayPizzaGuy"/>
      </Transitions>
    </WorkflowProcess>
  </WorkflowProcesses>
</Package>
_DUMP

#!/usr/bin/env perl
# First example XPDL script from Interapy
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 8;
# use Log::Report mode => 3;   # enable debugging

use BPM::XPDL;
use BPM::XPDL::Util ':xpdl10';
use XML::Compile::Util   'pack_type';

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

my $example = <<_EXAMPLE;
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<Package xmlns="http://www.wfmc.org/2002/XPDL1.0" xmlns:xpdl="http://www.wfmc.org/2002/XPDL1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Id="newpkg1" Name="newpkg1" xsi:schemaLocation="http://www.wfmc.org/2002/XPDL1.0 http://wfmc.org/standards/docs/TC-1025_schema_10_xpdl.xsd">
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
_EXAMPLE

my ($type, $data) = BPM::XPDL->from($example);
#warn Dumper $data;

is($type, pack_type(NS_XPDL_10, 'Package'));

isa_ok($data, 'HASH');
is($data->{Id}, 'newpkg1');

is($data->{PackageHeader}{Vendor}, 'Together');

is($data->{WorkflowProcesses}{WorkflowProcess}[0]{Name}, 'Order Pizza');

my $act = $data->{WorkflowProcesses}{WorkflowProcess}[0]{Activities}{Activity};
isa_ok($act, 'ARRAY');
cmp_ok(scalar @$act, '==', 3);
is(join(' ', map { $_->{Id} } @$act), 'PlaceOrder WaitForDelivery PayPizzaGuy');

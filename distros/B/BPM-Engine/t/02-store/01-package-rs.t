use strict;
use warnings;
use IO::File;
use Test::More;
use t::TestUtils;

my $rs = schema->resultset('Package');
isa_ok($rs, 'BPM::Engine::Store::ResultSet::Package');

# standard DBIC interface

{
my $package = $rs->create({});
isa_ok($package, 'BPM::Engine::Store::Result::Package');
my $proc = schema->resultset('Process')->create({
    package_id => $package->id
    });
isa_ok($proc, 'BPM::Engine::Store::Result::Process');

$package->delete();
is($rs->count, 0);
is(schema->resultset('Process')->count, 0);
}

# create_from_xml

{
my $string = qq!
<Package>
    <WorkflowProcesses>
        <WorkflowProcess Id="OrderPizza" Name="Order Pizza">
            <Activities>
                <Activity Id="PlaceOrder" />
                <Activity Id="WaitForDelivery" />
                <Activity Id="PayPizzaGuy" />
            </Activities>
            <Transitions>
                <Transition Id="1" From="PlaceOrder" To="WaitForDelivery"/>
                <Transition Id="2" From="WaitForDelivery" To="PayPizzaGuy"/>
            </Transitions>
        </WorkflowProcess>
    </WorkflowProcesses>
</Package>
!;

my $fh = IO::File->new('./t/02-store/01-package-rs.xml');

foreach my $xmlin(\$string, $fh, './t/02-store/01-package-rs.xml') {
    my $package = $rs->create_from_xml($xmlin);
    isa_ok($package, 'BPM::Engine::Store::Result::Package');

    my $process = $package->processes->first;
    isa_ok($process, 'BPM::Engine::Store::Result::Process');
    is($process->process_uid, 'OrderPizza', 'Process id matches');

    is($rs->count, 1);
    is(schema->resultset('Process')->count, 1);

    $package->delete();
    is($rs->count, 0);
    is(schema->resultset('Process')->count, 0);
    }

}

# create_from_xpdl

# XML::LibXML::Document
#\$string
# $file
# $fh

{
my $xpdl = q|<?xml version="1.0" encoding="UTF-8"?>
        <Package xmlns="http://www.wfmc.org/2008/XPDL2.1" Id="TestPackage">
        <PackageHeader><XPDLVersion>2.1</XPDLVersion>
        <Vendor/><Created/></PackageHeader>
        <WorkflowProcesses><WorkflowProcess Id="TestProcess"><ProcessHeader/>
            <Activities><Activity Id="wcp37.B" Name="B">
            <Implementation><Task><TaskManual/></Task></Implementation></Activity></Activities>
        </WorkflowProcess></WorkflowProcesses></Package>|;

my $fh = IO::File->new('./t/var/01-basic.xpdl');

foreach my $xml(\$xpdl, $fh, './t/var/01-basic.xpdl') {
    my $package = $rs->create_from_xpdl($xml);
    isa_ok($package, 'BPM::Engine::Store::Result::Package');
    #is($package->discard_changes->package_uid, 'TestPackage');
    }

foreach(qw/
  01-basic.xpdl
  02-branching.xpdl
  06-iteration.xpdl
  07-termination.xpdl
  08-samples.xpdl
  09-data.xpdl
  10-tasks.xpdl
  /){
    #warn "Package $_";
    my $package = $rs->create_from_xpdl('./t/var/' . $_);
    isa_ok($package, 'BPM::Engine::Store::Result::Package');
    my $process = $package->processes->first;
    isa_ok($process, 'BPM::Engine::Store::Result::Process');

    my @res = $package->processes->all;
    isa_ok($res[0], 'BPM::Engine::Store::Result::Process');
    }
}

done_testing;

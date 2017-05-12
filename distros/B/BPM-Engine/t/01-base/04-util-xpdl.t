use strict;
use warnings;
use Test::More;
END { done_testing() }
use Test::NoWarnings;
use Test::Fatal;

use BPM::Engine::Util::XPDL qw/xml_doc xpdl_doc xpdl_hash xml_hash/;  # xml_doc xpdl_doc xpdl_hash

foreach my $version(qw/1_0 2_0 2_1 2_2/) {
    ok(-e BPM::Engine::Util::XPDL::_xpdl_spec($version));
    }

my $faulty_string = q|<?xml version="1.0" encoding="UTF-8"?><Package></Package>|;
my $string = q|<?xml version="1.0" encoding="UTF-8"?>
    <Package xmlns="http://www.wfmc.org/2008/XPDL2.1" Id="TestPackage">
    <PackageHeader><XPDLVersion>2.1</XPDLVersion><Vendor/><Created/></PackageHeader>
    <WorkflowProcesses>
    <WorkflowProcess Id="TestProcess"><ProcessHeader/></WorkflowProcess>
    </WorkflowProcesses></Package>|;

# xml_doc

isa_ok(exception { xml_doc() }, 'BPM::Engine::Exception::Parameter');
isa_ok(exception { xml_doc([]) }, 'BPM::Engine::Exception::Parameter');
isa_ok(exception { xml_doc('') }, 'BPM::Engine::Exception::Parameter');
isa_ok(exception { xml_doc('./nonexistant') }, 'BPM::Engine::Exception::Parameter');
isa_ok(xml_doc(\$string), 'XML::LibXML::Document');
isa_ok(xml_doc('./t/var/09-data.xpdl'), 'XML::LibXML::Document');

# xpdl_doc

isa_ok(exception { xpdl_doc(\$faulty_string) }, 'BPM::Engine::Exception::Model');
isa_ok(xpdl_doc(\$string), 'XML::LibXML::Document');

# xpdl_hash

isa_ok(xpdl_hash(\$string), 'HASH');
isa_ok(xpdl_hash('./t/var/09-data.xpdl'), 'HASH');

# xml_hash

isa_ok(xml_hash(\$string), 'HASH');
isa_ok(xml_hash('./t/var/09-data.xpdl'), 'HASH');


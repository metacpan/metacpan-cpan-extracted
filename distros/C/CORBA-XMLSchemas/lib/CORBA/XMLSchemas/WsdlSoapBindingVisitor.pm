
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           CORBA to WSDL/SOAP Interworking Specification, Version 1.1 February 2005
#

package CORBA::XMLSchemas::WsdlSoapBindingVisitor;

use strict;
use warnings;

our $VERSION = '2.62';

use CORBA::XMLSchemas::BaseVisitor;
use base qw(CORBA::XMLSchemas::BaseVisitor);

use File::Basename;
use POSIX qw(ctime);
use XML::DOM;

# needs $node->{xsd_name} $node->{xsd_qname} (XsdNameVisitor)

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{beautify} = $parser->YYData->{opt_t};
    $self->{_tns} = 'tns';
    $self->{tns} = 'tns:';
    $self->{_xsd} = 'xs';
    $self->{xsd} = 'xs:';
    $self->{_wsdl} = 'wsdl';
    $self->{wsdl} = $parser->YYData->{opt_q} ? 'wsdl:' : q{};
    $self->{_soap} = 'soap';
    $self->{soap} = 'soap:';
    $self->{_corba} = 'corba';
    $self->{corba} = 'corba:';
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{base} = $parser->YYData->{opt_b} || q{};
    my $filename = basename($self->{srcname}, '.idl') . 'binding.wsdl';
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_inc_soap';
    return $self;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};

    $self->{dom_doc} = new XML::DOM::Document();
    $self->{dom_parent} = $self->{dom_doc};

    my $definitions = $self->{dom_doc}->createElement($self->{wsdl} . 'definitions');
    $definitions->setAttribute('targetNamespace', 'http://www.omg.org/IDL-Mapped/');
    $definitions->setAttribute('xmlns:' . $self->{_tns}, 'http://www.omg.org/IDL-Mapped/');
    if ($self->{wsdl}) {
        $definitions->setAttribute('xmlns:' . $self->{_wsdl}, 'http://schemas.xmlsoap.org/wsdl/');
    }
    else {
        $definitions->setAttribute('xmlns', 'http://schemas.xmlsoap.org/wsdl/');
    }
    $definitions->setAttribute('xmlns:' . $self->{_soap}, 'http://schemas.xmlsoap.org/wsdl/soap/');
    $definitions->setAttribute('xmlns:' . $self->{_corba}, 'http://www.omg.org/IDL-WSDL/1.0/');
    $self->{dom_parent}->appendChild($definitions);

    my $import = $self->{dom_doc}->createElement($self->{wsdl} . 'import');
    $import->setAttribute('namespace', 'http://www.omg.org/IDL-Mapped/');
    my $filename = basename($self->{srcname}, '.idl') . '.wsdl';
    $import->setAttribute('location', $self->{base} . $filename);
    $definitions->appendChild($import);

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $definitions);
    }

    if ($self->{beautify}) {
        print $FH "<!-- This file was generated (by ",$0,"). DO NOT modify it -->\n";
        print $FH "<!-- From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
        print $FH "-->\n";
        print $FH "\n";
        print $FH $self->_beautify($self->{dom_doc}->toString());
        print $FH "\n\n";
        print $FH "<!-- end of file : ",$self->{filename}," -->\n";
    }
    else {
        print $FH $self->{dom_doc}->toString();
    }
    close $FH;
    $self->{dom_doc}->dispose();
}

#
#   3.8     Interface Declaration
#
#   See 1.2.8       Interfaces
#

sub visitBaseInterface {
    # empty
}

sub visitRegularInterface {
    my $self = shift;
    my ($node, $dom_parent) = @_;

#   my $str = ' binding for ' . $node->{xsd_name} . q{ };
#   my $comment = $self->{dom_doc}->createComment($str);
#   $dom_parent->appendChild($comment);

    my $binding = $self->{dom_doc}->createElement($self->{wsdl} . 'binding');
    $binding->setAttribute('name', $node->{xsd_name} .  'Binding');
    $binding->setAttribute('type', 'tns:' . $node->{xsd_name});
    $dom_parent->appendChild($binding);

    my $soap_binding = $self->{dom_doc}->createElement($self->{soap} . 'binding');
    $soap_binding->setAttribute('style', 'rpc');
    $soap_binding->setAttribute('transport', 'http://schemas.xmlsoap.org/soap/http');
    $binding->appendChild($soap_binding);

    $self->{itf} = $node->{xsd_name};
    foreach (values %{$node->{hash_attribute_operation}}) {
        $self->_get_defn($_)->visit($self, $binding);
    }
    delete $self->{itf};
}

#
#   3.9     Value Declaration
#

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    # empty
}

sub visitStructType {
    # empty
}

sub visitUnionType {
    # empty
}

sub visitEnumType {
    # empty
}

#
#   3.12    Exception Declaration
#

sub visitException {
    # empty
}

#
#   3.13    Operation Declaration
#
#   See 1.2.8.2     Interface as Binding Operations
#

sub visitOperation {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $operation = $self->{dom_doc}->createElement($self->{wsdl} . 'operation');
    $operation->setAttribute('name', $node->{idf});
    $dom_parent->appendChild($operation);

    my $soap_operation = $self->{dom_doc}->createElement($self->{soap} . 'operation');
    $soap_operation->setAttribute('soapAction', $self->{itf} . '#' . $node->{idf});
    $operation->appendChild($soap_operation);

    my $input = $self->{dom_doc}->createElement($self->{wsdl} . 'input');
    $operation->appendChild($input);

    my $soap_body = $self->{dom_doc}->createElement($self->{soap} . 'body');
    $soap_body->setAttribute('namespace', 'http://www.omg.org/IDL-WSDL/1.0/');
    $soap_body->setAttribute('use', 'literal');
    $input->appendChild($soap_body);

    my $output = $self->{dom_doc}->createElement($self->{wsdl} . 'output');
    $operation->appendChild($output);

    $soap_body = $self->{dom_doc}->createElement($self->{soap} . 'body');
    $soap_body->setAttribute('namespace', 'http://www.omg.org/IDL-WSDL/1.0/');
    $soap_body->setAttribute('use', 'literal');
    $output->appendChild($soap_body);

    foreach (@{$node->{list_raise}}) {
        my $defn = $self->_get_defn($_);

        my $fault = $self->{dom_doc}->createElement($self->{wsdl} . 'fault');
        $fault->setAttribute('name', $defn->{xsd_name});
        $operation->appendChild($fault);

        my $soap_fault = $self->{dom_doc}->createElement($self->{soap} . 'fault');
        $soap_fault->setAttribute('namespace', 'http://www.omg.org/IDL-WSDL/1.0/');
        $soap_fault->setAttribute('name', $defn->{xsd_name});
        $soap_fault->setAttribute('use', 'literal');
        $fault->appendChild($soap_fault);
    }

    unless (exists $node->{modifier}) {     # oneway
        my $fault = $self->{dom_doc}->createElement($self->{wsdl} . 'fault');
        $fault->setAttribute('name', 'CORBA.SystemException');
        $operation->appendChild($fault);

        my $soap_fault = $self->{dom_doc}->createElement($self->{soap} . 'fault');
        $soap_fault->setAttribute('namespace', 'http://www.omg.org/IDL-WSDL/1.0/');
        $soap_fault->setAttribute('name', 'CORBA.SystemException');
        $soap_fault->setAttribute('use', 'literal');
        $fault->appendChild($soap_fault);
    }
}

1;


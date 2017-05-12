#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           CORBA to WSDL/SOAP Interworking Specification, Version 1.1 February 2005
#

package CORBA::XMLSchemas::WsdlVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::XMLSchemas::BaseVisitor;
use base qw(CORBA::XMLSchemas::BaseVisitor);

use File::Basename;
use POSIX qw(ctime);
use XML::DOM;
use CORBA::XMLSchemas::XsdImportVisitor;
use CORBA::XMLSchemas::RelaxngImportVisitor;

# needs $node->{xsd_name} $node->{xsd_qname} (XsdNameVisitor)

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $ext_schema) = @_;
    $self->{beautify} = $parser->YYData->{opt_t};
    $self->{ext_schema} = 'xsd:';
    $self->{ext_schema} = $ext_schema . ':' if (defined $ext_schema);
    $self->{_tns} = 'tns';
    $self->{tns} = 'tns:';
    $self->{_xsd} = 'xs';
    $self->{xsd} = 'xs:';
    $self->{_wsdl} = 'wsdl';
    $self->{wsdl} = $parser->YYData->{opt_q} ? 'wsdl:' : q{};
    $self->{_corba} = 'corba';
    $self->{corba} = 'corba:';
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{base} = $parser->YYData->{opt_b} || q{};
    $self->{root} = $parser->YYData->{root};
    my $filename = basename($self->{srcname}, '.idl') . '.wsdl';
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_inc_wsdl';
    if ($self->{ext_schema} eq 'rng:') {
        $self->{schema_visitor} = new CORBA::XMLSchemas::RelaxngImportVisitor($parser);
    }
    else {
        $self->{schema_visitor} = new CORBA::XMLSchemas::XsdImportVisitor($parser);
    }
    $self->{ports} = [];
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
    $definitions->setAttribute('xmlns:' . $self->{_xsd}, 'http://www.w3.org/2001/XMLSchema');
    if ($self->{wsdl}) {
        $definitions->setAttribute('xmlns:' . $self->{_wsdl}, 'http://schemas.xmlsoap.org/wsdl/');
    }
    else {
        $definitions->setAttribute('xmlns', 'http://schemas.xmlsoap.org/wsdl/');
    }
    $definitions->setAttribute('xmlns:' . $self->{_corba}, 'http://www.omg.org/IDL-WSDL/1.0/');
    $self->{dom_parent}->appendChild($definitions);

    my $import = $self->{dom_doc}->createElement($self->{wsdl} . 'import');
    $import->setAttribute('namespace', 'http://www.omg.org/IDL-WSDL/1.0/');
    $import->setAttribute('location', $self->{base} . 'corba.wsdl');
    $definitions->appendChild($import);

    my $types = $self->{dom_doc}->createElement($self->{wsdl} . 'types');
    $definitions->appendChild($types);

    $node->visit($self->{schema_visitor}, $self->{dom_doc}, $types);

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $definitions);
    }
    foreach (@{$self->{ports}}) {
        $definitions->appendChild($_);
    }

    if ($self->{beautify}) {
        print $FH "<!-- This file was generated (by ", $0, "). DO NOT modify it -->\n";
        print $FH "<!-- From file : ", $self->{srcname}, ", ", $self->{srcname_size}, " octets, ", POSIX::ctime($self->{srcname_mtime});
        print $FH "-->\n";
        print $FH "\n";
        print $FH $self->_beautify($self->{dom_doc}->toString());
        print $FH "\n\n";
        print $FH "<!-- end of file : ", $self->{filename}, " -->\n";
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

sub visitRegularInterface {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $str = ' interface: ' . $node->{xsd_name} . q{ };
    my $comment = $self->{dom_doc}->createComment($str);
    $dom_parent->appendChild($comment);

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $dom_parent);
    }

    if (scalar keys %{$node->{hash_attribute_operation}}) {
        my $str = ' port for ' . $node->{xsd_name} . q{ };
        my $comment = $self->{dom_doc}->createComment($str);
        push @{$self->{ports}}, $comment;

        my $portType = $self->{dom_doc}->createElement($self->{wsdl} . 'portType');
        $portType->setAttribute('name', $node->{xsd_name});
        push @{$self->{ports}}, $portType;

        foreach (values %{$node->{hash_attribute_operation}}) {
            my $defn = $self->_get_defn($_);
            if ($defn->isa('Operation')) {
                $self->_operation($defn, $portType);
            }
            else {
                $self->_operation($defn->{_get}, $portType);
                $self->_operation($defn->{_set}, $portType)
                        if (exists $defn->{_set});
            }
        }
    }
}

sub _operation {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $operation = $self->{dom_doc}->createElement($self->{wsdl} . 'operation');
    $operation->setAttribute('name', $node->{idf});
    $dom_parent->appendChild($operation);

    my $input = $self->{dom_doc}->createElement($self->{wsdl} . 'input');
    $input->setAttribute('message', $self->{tns} . $node->{xsd_name});
    $operation->appendChild($input);

    my $output = $self->{dom_doc}->createElement($self->{wsdl} . 'output');
    $output->setAttribute('message', $self->{tns} . $node->{xsd_name} . 'Response');
    $operation->appendChild($output);

    foreach (@{$node->{list_raise}}) {
        my $defn = $self->_get_defn($_);

        my $fault = $self->{dom_doc}->createElement($self->{wsdl} . 'fault');
        $fault->setAttribute('name', $defn->{xsd_name});
        $fault->setAttribute('message', $self->{tns} . '_exception.' . $defn->{xsd_name});
        $operation->appendChild($fault);
    }

    unless (exists $node->{modifier}) {     # oneway
        my $fault = $self->{dom_doc}->createElement($self->{wsdl} . 'fault');
        $fault->setAttribute('name', 'CORBA.SystemException');
        $fault->setAttribute('message', $self->{corba} . 'CORBA.SystemExceptionMessage');
        $operation->appendChild($fault);
    }
}

sub visitAbstractInterface {
    my $self = shift;
    my ($node, $dom_parent) = @_;

    my $str = ' abstract interface: ' . $node->{xsd_name} . q{ };
    my $comment = $self->{dom_doc}->createComment($str);
    $dom_parent->appendChild($comment);

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $dom_parent);
    }
}

#
#   3.9     Value Declaration
#

sub visitValue {
    # empty
}

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

    my $message = $self->{dom_doc}->createElement($self->{wsdl} . 'message');
    $message->setAttribute('name', $node->{xsd_name});
    $dom_parent->appendChild($message);

    foreach (@{$node->{list_param}}) {  # parameter
        if (       $_->{attr} eq 'in'
                or $_->{attr} eq 'inout' ) {
            $_->visit($self, $message);     # parameter
        }
    }

    my $type = $self->_get_defn($node->{type});
    $message = $self->{dom_doc}->createElement($self->{wsdl} . 'message');
    $message->setAttribute('name', $node->{xsd_name} . 'Response');
    $dom_parent->appendChild($message);

    unless ($type->isa('VoidType')) {
        my $part = $self->{dom_doc}->createElement($self->{wsdl} . 'part');
        $part->setAttribute('name', '_return');
        $part->setAttribute('type', $type->{xsd_qname});
        $message->appendChild($part);
    }

    foreach (@{$node->{list_param}}) {  # parameter
        if (       $_->{attr} eq 'inout'
                or $_->{attr} eq 'out' ) {
            $_->visit($self, $message);     # parameter
        }
    }

    foreach (@{$node->{list_raise}}) {
        my $defn = $self->_get_defn($_);

        my $message = $self->{dom_doc}->createElement($self->{wsdl} . 'message');
        $message->setAttribute('name', '_exception.' . $defn->{xsd_name});
        $dom_parent->appendChild($message);

        my $part = $self->{dom_doc}->createElement($self->{wsdl} . 'part');
        $part->setAttribute('name', 'exception');
        $part->setAttribute('type', $defn->{xsd_qname});
        $message->appendChild($part);
    }
}

sub visitParameter {
    my $self = shift;
    my ($node, $dom_parent) = @_;
    my $type = $self->_get_defn($node->{type});

    my $part = $self->{dom_doc}->createElement($self->{wsdl} . 'part');
    $part->setAttribute('name', $node->{xsd_name});
    $part->setAttribute('type', $type->{xsd_qname});
    $dom_parent->appendChild($part);
}

1;


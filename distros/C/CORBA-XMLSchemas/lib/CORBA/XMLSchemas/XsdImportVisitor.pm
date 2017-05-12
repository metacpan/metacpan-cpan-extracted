
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           CORBA to WSDL/SOAP Interworking Specification, Version 1.1 February 2005
#

package CORBA::XMLSchemas::XsdImportVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::XMLSchemas::XsdVisitor;
use base qw(CORBA::XMLSchemas::XsdVisitor);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{standalone} = undef;
    $self->{_tns} = 'tns';
    $self->{tns} = 'tns:';
    $self->{_xsd} = 'xs';
    $self->{xsd} = 'xs:';
    $self->{_corba} = 'corba';
    $self->{corba} = 'corba:';
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{root} = $parser->YYData->{root};
    $self->{done_hash} = {};
    $self->{num_key} = 'num_inc_xsd';
    $self->{need_corba} = undef;
    return $self;
}

sub visitSpecification {
    my $self = shift;
    my ($node, $dom_doc, $dom_parent) = @_;

    $self->{dom_doc} = $dom_doc;

    my $schema = $self->{dom_doc}->createElement($self->{xsd} . 'schema');
    $schema->setAttribute('targetNamespace', 'http://www.omg.org/IDL-Mapped/');
    $schema->setAttribute('xmlns:' . $self->{_xsd}, 'http://www.w3.org/2001/XMLSchema');
    $schema->setAttribute('xmlns:' . $self->{_corba}, 'http://www.omg.org/IDL-WSDL/1.0/');
    $schema->setAttribute('xmlns:' . $self->{_tns}, 'http://www.omg.org/IDL-Mapped/');
    $schema->setAttribute('elementFormDefault', 'qualified');
    $schema->setAttribute('attributeFormDefault', 'unqualified');
    $dom_parent->appendChild($schema);

    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self, $schema);
        }
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $schema);
    }
}

1;


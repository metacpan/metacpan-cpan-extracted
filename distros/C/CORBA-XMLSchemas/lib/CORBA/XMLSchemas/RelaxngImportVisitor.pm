
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::XMLSchemas::RelaxngImportVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::XMLSchemas::RelaxngVisitor;
use base qw(CORBA::XMLSchemas::RelaxngVisitor);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{standalone} = undef;
    $self->{tag_root} = q{};
    $self->{_rng} = 'rng';
    $self->{rng} = 'rng:';
    $self->{_xsd} = 'xs';
    $self->{xsd} = 'xs:';
    $self->{_corba} = 'corba';
    $self->{corba} = 'corba:';
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{root} = $parser->YYData->{root};
    $self->{done_hash} = {};
    $self->{num_key} = 'num_inc_rng';
    $self->{need_corba} = undef;
    return $self;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node, $dom_doc, $dom_parent) = @_;

    $self->{dom_doc} = $dom_doc;

    my $grammar = $self->{dom_doc}->createElement($self->{rng} . 'grammar');
    $grammar->setAttribute('ns', 'http://www.omg.org/IDL-Mapped/');
    $grammar->setAttribute('datatypeLibrary', 'http://www.w3.org/2001/XMLSchema-datatypes');
    $grammar->setAttribute('xmlns:' . $self->{_xsd}, 'http://www.w3.org/2001/XMLSchema');
    $grammar->setAttribute('xmlns:' . $self->{_rng}, 'http://relaxng.org/ns/structure/1.0');
    $grammar->setAttribute('xmlns:' . $self->{_corba}, 'http://www.omg.org/IDL-WSDL/1.0/');
    $dom_parent->appendChild($grammar);

    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self, $grammar);
        }
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $grammar);
    }
}

1;


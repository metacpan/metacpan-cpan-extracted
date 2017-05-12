
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           CORBA to WSDL/SOAP Interworking Specification, Version 1.1 February 2005
#

package CORBA::XMLSchemas::NameVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

# builds $node->{xsd_name} and $node->{xsd_qname}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $ns) = @_;
    $self->{key} = 'xsd_name';
    $self->{tns} = 'tns:';
    $self->{xsd} = 'xs:';
    $self->{xsd} = $ns . ':' if (defined $ns);
    $self->{corba} = 'corba:';
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{root} = $parser->YYData->{root};
    return $self;
}

sub _get_defn {
    my $self = shift;
    my ($defn) = @_;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{symbtab}->Lookup($defn);
    }
}

#
#   See 1.2     Scoped Names
#
sub _get_name {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{full};
    $name =~ s/^:://;
    $name =~ s/::/\./g;
    return $name;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self);
        }
    }
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{xsd_name});
    $node->{xsd_name} = $self->_get_name($node);
    $node->{xsd_qname} = $self->{corba} . 'ObjectReference';
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.9     Value Declaration
#

sub visitRegularValue {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{xsd_name});
    $node->{xsd_name} = $self->_get_name($node);
    $node->{xsd_qname} = $self->{tns} . $node->{xsd_name};
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitStateMember {
    shift->visitMember(@_);
}

sub visitInitializer {
    # empty
}

sub visitBoxedValue {
    shift->visitTypeDeclarator(@_);
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{xsd_name});
    $node->{xsd_name} = $self->_get_name($node);
    $node->{xsd_qname} = $self->{tns} . $node->{xsd_name};
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    $self->{root}->{need_corba} = 1
            if ($type->isa('BaseInterface'));
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = $node->{idf};
}

#
#   3.11.1  Basic Types
#
#   See 1.2.6       Primitive Types
#

sub visitIntegerType {
    my $self = shift;
    my ($node) = @_;
    if    ($node->{value} eq 'short') {
        $node->{xsd_name} = 'short';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    elsif ($node->{value} eq 'unsigned short') {
        $node->{xsd_name} = 'unsignedShort';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    elsif ($node->{value} eq 'long') {
        $node->{xsd_name} = 'int';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    elsif ($node->{value} eq 'unsigned long') {
        $node->{xsd_name} = 'unsignedInt';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    elsif ($node->{value} eq 'long long') {
        $node->{xsd_name} = 'long';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    elsif ($node->{value} eq 'unsigned long long') {
        $node->{xsd_name} = 'unsignedLong';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    else {
        warn __PACKAGE__,"::visitIntegerType $node->{value}.\n";
    }
}

sub visitFloatingPtType {
    my $self = shift;
    my ($node) = @_;
    if    ($node->{value} eq 'float') {
        $node->{xsd_name} = 'float';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    elsif ($node->{value} eq 'double') {
        $node->{xsd_name} = 'double';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    elsif ($node->{value} eq 'long double') {
        $node->{xsd_name} = 'double';
        $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
    }
    else {
        warn __PACKAGE__,"::visitFloatingPtType $node->{value}.\n";
    }
}

sub visitCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'string';
    $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
}

sub visitWideCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'string';
    $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
}

sub visitBooleanType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'boolean';
    $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
}

sub visitOctetType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'unsignedByte';
    $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
}

sub visitAnyType {      # See 1.2.7.8   Any
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'CORBA.Any';
    $node->{xsd_qname} = $self->{corba} . $node->{xsd_name};
    $self->{root}->{need_any} = 1;
}

sub visitObjectType {   # See 1.2.5     Object References
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'ObjectReference';
    $node->{xsd_qname} = $self->{corba} . $node->{xsd_name};
    $self->{root}->{need_corba} = 1;
}

sub visitValueBaseType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'ObjectReference';
    $node->{xsd_qname} = $self->{corba} . $node->{xsd_name};
    $self->{root}->{need_corba} = 1;
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{xsd_name});
    $node->{xsd_name} = $self->_get_name($node);
    $node->{xsd_qname} = $self->{tns} . $node->{xsd_name};
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = $node->{idf};
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    $self->{root}->{need_corba} = 1
            if ($type->isa('BaseInterface'));
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{xsd_name});
    $node->{xsd_name} = $self->_get_name($node);
    $node->{xsd_qname} = $self->{tns} . $node->{xsd_name};
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_expr}}) {
        $_->{element}->visit($self);            # element
    }
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{value})->visit($self);     # single or array
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{xsd_name});
    $node->{xsd_name} = $self->_get_name($node);
    $node->{xsd_qname} = $self->{tns} . $node->{xsd_name};
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # enum
    }
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = $node->{idf};
}

#
#   3.11.3  Template Types
#
#   See 1.2.7.5     Sequences
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    $self->{root}->{need_corba} = 1
            if ($type->isa('BaseInterface'));
}

#
#   See 1.2.6       Primitive Types
#

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'string';
    $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
}

sub visitWideStringType {
    shift->visitStringType(@_);
}

#
#   See 1.2.7.9     Fixed
#

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    $node->{xsd_name} = 'decimal';
    $node->{xsd_qname} = $self->{xsd} . $node->{xsd_name};
}

#
#   3.12    Exception Declaration
#
#   See 1.2.8.5     Exceptions
#

sub visitException {
    shift->visitStructType(@_);
}

#
#   3.13    Operation Declaration
#
#   See 1.2.8.2     Interface as Binding Operation
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $self->{op} = $node->{idf};
    $node->{xsd_name} = $self->_get_name($node);
    $node->{xsd_qname} = $self->{tns} . $node->{xsd_name};
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    if ($self->{op} =~ /^_set_/) {
        $node->{xsd_name} = 'value';
    }
    else {
        $node->{xsd_name} = $node->{idf};
    }
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    $self->{root}->{need_corba} = 1
            if ($type->isa('BaseInterface'));
}

sub visitVoidType {
    # empty
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $node->{_get}->visit($self);
    $node->{_set}->visit($self)
            if (exists $node->{_set});
}

#
#   3.15    Repository Identity Related Declarations
#

sub visitTypeId {
    # empty
}

sub visitTypePrefix {
    # empty
}

#
#   3.16    Event Declaration
#

sub visitEvent {
    # no mapping
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    # no mapping
}

sub visitForwardComponent {
    # no mapping
}

sub visitProvides {
    # no mapping
}

sub visitUses {
    # no mapping
}

sub visitPublishes {
    # no mapping
}

sub visitEmits {
    # no mapping
}

sub visitConsumes {
    # no mapping
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    # no mapping
}

sub visitFinder {
    # no mapping
}

1;


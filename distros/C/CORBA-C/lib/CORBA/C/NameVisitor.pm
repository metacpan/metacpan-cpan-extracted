
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::NameVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

# builds $node->{c_name}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{key} = 'c_name';
    $self->{symbtab} = $parser->YYData->{symbtab};
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
    $name =~ s/::/_/g;
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
#   3.6     Import Declaration
#

sub visitImport {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $self->_get_name($node);
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
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitInitializer {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $self->_get_name($node);
}

sub visitExpression {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
}

#
#   3.11.1  Basic Types
#
#   See 1.7     Mapping for Basic Data Types
#

sub visitBasicType {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{value};
    $name =~ s/ /_/g;
    $node->{$self->{key}} = 'CORBA_' . $name;
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
    $self->_get_defn($node->{type})->visit($self);
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # case
    }
}

sub visitCase {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_label}}) {
        $_->visit($self);           # default or expression
    }
    $node->{element}->visit($self);
}

sub visitDefault {
    # empty
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{value})->visit($self);     # member
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $self->_get_name($node);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # enum
    }
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $self->_get_name($node);
}

#
#   3.11.3  Template Types
#
#   See 1.11    Mapping for Sequence Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    while (     $type->isa('TypeDeclarator')
            and ! exists $type->{array_size} ) {
        $type = $self->_get_defn($type->{type});
    }
    $type->visit($self);
    my $name = $type->{$self->{key}};
    $name =~ s/^CORBA_//;
    $node->{$self->{key}} = 'CORBA_sequence_' . $name;
}

#
#   See 1.12    Mapping for Strings
#

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'CORBA_string';
}

#
#   See 1.13    Mapping for Wide Strings
#

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'CORBA_wstring';
}

#
#   See 1.14    Mapping for Fixed
#

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    my $name = 'CORBA_fixed_' . $node->{d}->{value} . '_' . $node->{s}->{value};
    $node->{$self->{key}} = $name;
}

sub visitFixedPtConstType {
    my $self = shift;
    my ($node) = @_;
    my $name = 'CORBA_fixed';
    $node->{$self->{key}} = $name;
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $self->_get_name($node);
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
}

#
#   3.13    Operation Declaration
#
#   See 1.4     Inheritance and Operation Names
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
    $self->_get_defn($node->{type})->visit($self);
}

sub visitVoidType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'void';
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $node->{_get}->visit($self);
    $node->{_set}->visit($self) if (exists $node->{_set});
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
#   3.17    Component Declaration
#

sub visitProvides {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
}

sub visitUses {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
}

sub visitPublishes {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
}

sub visitEmits {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
}

sub visitConsumes {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = $self->_get_name($node);
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitFinder {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

1;



#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::LengthVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

# builds $node->{length}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{done_hash} = {};
    $self->{key} = 'c_name';
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

#   See 1.8     Mapping Considerations for Constructed Types
#

sub _get_length {
    my $self = shift;
    my ($type) = @_;
    if (       $type->isa('AnyType')
            or $type->isa('SequenceType')
            or $type->isa('StringType')
            or $type->isa('WideStringType')
            or $type->isa('ObjectType') ) {
        return 'variable';
    }
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('TypeDeclarator') ) {
        return $type->{length};
    }
    return undef;
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
    return if (exists $node->{length});
#   $node->{length} = 'variable';
    # TODO : $self->{done}->{} ???
    $node->{length} = q{};      # void* = CORBA_unsigned_long
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{length});
#   $node->{length} = 'variable';
    $node->{length} = q{};      # void* = CORBA_unsigned_long
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{type})->visit($self);
}

sub visitInitializer {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $self->_get_defn($_->{type})->visit($self);
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('TypeDeclarator')
            or $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType')
            or $type->isa('SequenceType')
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
    $node->{length} = $self->_get_length($type);
}

sub visitNativeType {
    # C mapping is aligned with CORBA 2.1
}

#
#   3.11.1  Basic Types
#

sub visitBasicType {
    # fixed length
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{$self->{key}}});
    $self->{done_hash}->{$node->{$self->{key}}} = 1;
    $node->{length} = undef;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('TypeDeclarator')
                or $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('SequenceType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
        $node->{length} ||= $self->_get_length($type);
    }
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{$self->{key}}});
    $self->{done_hash}->{$node->{$self->{key}}} = 1;
    $node->{length} = undef;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{element}->{type});
        if (       $type->isa('TypeDeclarator')
                or $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('SequenceType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
        $node->{length} ||= $self->_get_length($type);
    }
    my $type = $self->_get_defn($node->{type});
    if ($type->isa('EnumType')) {
        $type->visit($self);
    }
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    # fixed length
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    $node->{length} = 'variable';
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('TypeDeclarator')
            or $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('SequenceType')
            or $type->isa('StringType')
            or $type->isa('WideStringType')
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
}

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{length} = 'variable';
}

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{length} = 'variable';
}

sub visitFixedPtType {
    # fixed length
}

sub visitFixedPtConstType {
    # fixed length
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    $node->{length} = undef;
    if (exists $node->{list_expr}) {
        warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
                unless (@{$node->{list_expr}});
        foreach (@{$node->{list_expr}}) {
            my $type = $self->_get_defn($_->{type});
            if (       $type->isa('TypeDeclarator')
                    or $type->isa('StructType')
                    or $type->isa('UnionType')
                    or $type->isa('SequenceType')
                    or $type->isa('FixedPtType') ) {
                $type->visit($self);
            }
            $node->{length} ||= $self->_get_length($type);
        }
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    foreach (@{$node->{list_param}}) {
        $self->_get_defn($_->{type})->visit($self);
    }
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
#   3.16    Event Declaration
#

#
#   3.17    Component Declaration
#

sub visitProvides {
    # empty
}

sub visitUses {
    # empty
}

sub visitPublishes {
    # empty
}

sub visitEmits {
    # empty
}

sub visitConsumes {
    # empty
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $self->_get_defn($_->{type})->visit($self);
    }
}

sub visitFinder {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $self->_get_defn($_->{type})->visit($self);
    }
}

1;

